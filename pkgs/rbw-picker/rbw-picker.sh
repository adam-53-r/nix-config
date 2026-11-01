#!/usr/bin/env bash
# Read-only fzf front end for rbw; adding and editing is left to the Bitwarden
# GUI because rbw's own edit drops the per-item encryption key.
#
# Secrets only ever travel through pipes or files under $XDG_RUNTIME_DIR, never
# argv or here-strings (bash spills large ones to /tmp).
set -uo pipefail
umask 077

self=@out@/bin/rbw-picker
lib=@out@/share/rbw-picker
runtime=${XDG_RUNTIME_DIR:?}
clip_sum_file=$runtime/rbw-picker-clip
clip_ttl=30

pjq() {
    jq -r -L "$lib" "include \"picker\"; $1" "${@:2}"
}

pause() {
    read -r -s -n 1 -p "$1 (press any key)" || true
    echo
}

raw() {
    rbw get --raw "$1"
}

value() {
    local id=$1 key=$2
    case $key in
        totp) rbw code "$id" | tr -d '\n' ;;
        notes) raw "$id" | jq -j '.notes // ""' ;;
        uri:*) raw "$id" | jq -j --argjson i "${key#uri:}" '.data.uris[$i].uri // ""' ;;
        field:*) raw "$id" | jq -j --argjson i "${key#field:}" '.fields[$i].value // ""' ;;
        data:*) raw "$id" | jq -j --arg k "${key#data:}" '.data[$k] // ""' ;;
    esac
}

# Copies stdin, keeping it out of cliphist, and clears it later unless
# something else has been copied since.
copy() {
    local v
    v=$(cat)
    [ -n "$v" ] || return 1
    printf '%s' "$v" | wl-copy --sensitive
    # The checksum stays in a 0600 file: argv is world-readable and systemd
    # keeps the unit's command line.
    printf '%s' "$v" | sha256sum | cut -d' ' -f1 > "$clip_sum_file"
    systemctl --user stop rbw-picker-clip.timer 2>/dev/null
    systemd-run --user --quiet --collect --unit=rbw-picker-clip --on-active=$clip_ttl \
        --setenv=WAYLAND_DISPLAY="$WAYLAND_DISPLAY" "$self" clip-clear
}

clip_clear() {
    local sum
    [ -s "$clip_sum_file" ] || return 0
    sum=$(cat "$clip_sum_file")
    rm -f "$clip_sum_file"
    [ "$(wl-paste -n 2>/dev/null | sha256sum | cut -d' ' -f1)" = "$sum" ] && wl-copy --clear
}

type_value() {
    local id=$1 key=$2
    if [ "$key" = login ]; then
        value "$id" data:username | wtype -
        wtype -k Tab
        value "$id" data:password | wtype -
        if [ -n "$(raw "$id" | jq -r '.data.totp // empty')" ]; then
            value "$id" totp | copy
        fi
    else
        value "$id" "$key" | wtype -
    fi
}

# Opened for reading and selecting; whatever is typed in helix is thrown away.
notes() {
    local file=$work/notes.txt
    value "$1" notes > "$file"
    hx "$file"
    rm -f "$file"
}

fields_screen() {
    local id=$1 name result status key line fkey
    name=$(raw "$id" | jq -r .name)
    while true; do
        status=0
        result=$(raw "$id" | pjq field_lines | fzf "${fzf_common[@]}" \
            --border-label=" $name " \
            --expect=ctrl-t \
            --header="$fields_header") || status=$?
        [ $status -eq 130 ] && return 1
        [ $status -eq 2 ] && return 1
        { read -r key; read -r line; } < <(printf '%s\n' "$result")
        fkey=${line%%$'\t'*}
        [ -n "$fkey" ] || continue
        if [ "$fkey" = notes ]; then
            notes "$id"
        elif [ "$key" = ctrl-t ] || [ "$mode" = type ]; then
            printf '%s\t%s\n' "$id" "$fkey" > "$out"
            return 0
        else
            value "$id" "$fkey" | copy && return 0
        fi
    done
}

ui() {
    mode=$1
    out=$2
    work=$(mktemp -d -p "$runtime" rbw-picker.XXXXXX)
    trap 'rm -rf "$work"' EXIT

    fzf_common=(
        --ansi --delimiter=$'\t' --with-nth=2..
        --layout=reverse --border=rounded --info=inline-right
        --pointer='▌' --prompt='  ' --color='header:dim,label:bold'
    )
    local enter="fields"
    [ "$mode" = type ] && enter="type login"
    local entries_header="enter $enter · ^y password · ^o totp · ^t type login · ^n notes · ^r sync"
    fields_header="enter $([ "$mode" = type ] && echo type || echo copy) · ^t type · esc back"

    rbw unlock || exit 1

    local query="" result status key line id
    while true; do
        status=0
        result=$(rbw list --raw | pjq entry_lines | fzf "${fzf_common[@]}" \
            --border-label=" rbw " \
            --query="$query" --print-query \
            --expect=ctrl-y,ctrl-o,ctrl-t,ctrl-n,ctrl-r \
            --preview="$self preview {1}" --preview-window=right,50%,border-left,wrap \
            --header="$entries_header") || status=$?
        [ $status -eq 130 ] && exit 0
        if [ $status -eq 2 ]; then
            pause "fzf failed."
            exit 1
        fi
        { read -r query; read -r key; read -r line; } < <(printf '%s\n' "$result")
        id=${line%%$'\t'*}
        if [ "$key" = ctrl-r ]; then
            rbw sync || pause "Sync failed."
            continue
        fi
        [ -n "$id" ] || continue
        case $key in
            ctrl-y) value "$id" data:password | copy && exit 0 ;;
            ctrl-o) value "$id" totp | copy && exit 0 ;;
            ctrl-t) printf '%s\tlogin\n' "$id" > "$out"; exit 0 ;;
            ctrl-n) notes "$id" ;;
            *)
                if [ "$mode" = type ]; then
                    printf '%s\tlogin\n' "$id" > "$out"
                    exit 0
                fi
                fields_screen "$id" && exit 0
                ;;
        esac
    done
}

launch() {
    local mode=copy out id key
    [ "${1:-}" = --type ] && mode="type"
    out=$(mktemp -p "$runtime" rbw-picker.XXXXXX)
    alacritty --class rbw-picker -e "$self" ui "$mode" "$out"
    IFS=$'\t' read -r id key < "$out"
    rm -f "$out"
    [ -n "${id:-}" ] || exit 0
    # Let focus go back to the previous window before typing into it.
    sleep 0.3
    type_value "$id" "$key"
}

case ${1:-} in
    ui) ui "$2" "$3" ;;
    preview) raw "$2" | pjq preview ;;
    clip-clear) clip_clear ;;
    lock) rbw lock 2> /dev/null ;;
    *) launch "$@" ;;
esac
