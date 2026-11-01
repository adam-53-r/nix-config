#!/usr/bin/env bash
# fzf front end for rbw. Edits go through the official bw CLI because rbw's own
# edit drops the per-item encryption key.
#
# Secrets only ever travel through pipes or files under $XDG_RUNTIME_DIR, never
# argv or here-strings (bash spills large ones to /tmp).
set -uo pipefail
umask 077

self=@out@/bin/rbw-picker
lib=@out@/share/rbw-picker
runtime=${XDG_RUNTIME_DIR:?}
bw_session_file=$runtime/rbw-picker-bw-session
bw_session_ttl=900
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
    local v sum
    v=$(cat)
    [ -n "$v" ] || return 1
    printf '%s' "$v" | wl-copy --sensitive
    sum=$(printf '%s' "$v" | sha256sum | cut -d' ' -f1)
    systemctl --user stop rbw-picker-clip.timer 2>/dev/null
    systemd-run --user --quiet --collect --unit=rbw-picker-clip --on-active=$clip_ttl \
        --setenv=WAYLAND_DISPLAY="$WAYLAND_DISPLAY" "$self" clip-clear "$sum"
}

clip_clear() {
    [ "$(wl-paste -n 2>/dev/null | sha256sum | cut -d' ' -f1)" = "$1" ] && wl-copy --clear
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

bw_unlock() {
    local status
    if [ -s "$bw_session_file" ]; then
        BW_SESSION=$(cat "$bw_session_file")
        export BW_SESSION
    fi
    status=$(bw status | jq -r .status) || return 1
    case $status in
        unlocked) ;;
        unauthenticated)
            echo "bw is not logged in yet."
            BW_SESSION=$(bw login --raw) || return 1
            ;;
        *)
            echo "bw needs your master password to save this."
            BW_SESSION=$(bw unlock --raw) || return 1
            ;;
    esac
    export BW_SESSION
    printf '%s' "$BW_SESSION" > "$bw_session_file"
    systemctl --user stop rbw-picker-bw-lock.timer 2>/dev/null
    systemd-run --user --quiet --collect --unit=rbw-picker-bw-lock --on-active=$bw_session_ttl \
        "$self" bw-lock
}

# bw takes about a second to start, too slow to run on every screen lock.
bw_lock() {
    [ -e "$bw_session_file" ] || return 0
    rm -f "$bw_session_file"
    bw lock > /dev/null 2>&1
}

bw_fetch() {
    bw_unlock || return 1
    bw sync > /dev/null || return 1
    bw get item "$1" > "$work/item.json"
}

bw_save() {
    bw encode | bw edit item "$1" > /dev/null || return 1
    rbw sync
}

notes() {
    local id=$1 file=$work/notes.txt
    value "$id" notes > "$file"
    cp "$file" "$work/notes.orig"
    hx "$file"
    if [ "$(cat "$file")" = "$(cat "$work/notes.orig")" ]; then
        return 0
    fi
    bw_fetch "$id" || return 1
    if [ "$(jq -j '.notes // ""' "$work/item.json")" != "$(cat "$work/notes.orig")" ]; then
        echo "The notes changed on the server since rbw last synced; not saving."
        return 1
    fi
    jq --rawfile n "$file" '.notes = ($n | sub("\n+$"; "") | if . == "" then null else . end)' "$work/item.json" \
        | bw_save "$id"
}

edit() {
    local id=$1 file=$work/item.edit.json
    bw_fetch "$id" || return 1
    pjq editable "$work/item.json" > "$file"
    cp "$file" "$work/item.orig.json"
    while true; do
        hx "$file"
        if cmp -s "$file" "$work/item.orig.json"; then
            return 0
        fi
        jq empty "$file" && break
        read -r -n 1 -p "Not valid JSON: [e]dit again or [a]bort? " answer
        echo
        [ "$answer" = e ] || return 0
    done
    pjq 'merge($e[0])' --slurpfile e "$file" "$work/item.json" | bw_save "$id"
}

fields_screen() {
    local id=$1 name result status key line fkey
    name=$(raw "$id" | jq -r .name)
    while true; do
        status=0
        result=$(raw "$id" | pjq field_lines | fzf "${fzf_common[@]}" \
            --border-label=" $name " \
            --expect=ctrl-t,ctrl-e \
            --header="$fields_header") || status=$?
        [ $status -eq 130 ] && return 1
        [ $status -eq 2 ] && return 1
        { read -r key; read -r line; } < <(printf '%s\n' "$result")
        fkey=${line%%$'\t'*}
        [ -n "$fkey" ] || continue
        case $key in
            ctrl-e) edit "$id" || pause "Edit failed." ;;
            ctrl-t) printf '%s\t%s\n' "$id" "$fkey" > "$out"; return 0 ;;
            *)
                if [ "$fkey" = notes ]; then
                    notes "$id" || pause "Saving the notes failed."
                elif [ "$mode" = type ]; then
                    printf '%s\t%s\n' "$id" "$fkey" > "$out"
                    return 0
                else
                    value "$id" "$fkey" | copy && return 0
                fi
                ;;
        esac
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
    local entries_header="enter $enter · ^y password · ^o totp · ^t type login · ^n notes · ^e edit · ^r sync"
    fields_header="enter $([ "$mode" = type ] && echo type || echo copy) · ^t type · ^e edit · esc back"

    rbw unlock || exit 1

    local query="" result status key line id
    while true; do
        status=0
        result=$(rbw list --raw | pjq entry_lines | fzf "${fzf_common[@]}" \
            --border-label=" rbw " \
            --query="$query" --print-query \
            --expect=ctrl-y,ctrl-o,ctrl-t,ctrl-n,ctrl-e,ctrl-r \
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
            ctrl-n) notes "$id" || pause "Saving the notes failed." ;;
            ctrl-e) edit "$id" || pause "Edit failed." ;;
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
    clip-clear) clip_clear "$2" ;;
    bw-lock) bw_lock ;;
    lock)
        rbw lock 2> /dev/null
        bw_lock
        ;;
    *) launch "$@" ;;
esac
