def dim: "\u001b[2m" + . + "\u001b[0m";
def bold: "\u001b[1m" + . + "\u001b[0m";
def accent: "\u001b[36m" + . + "\u001b[0m";
def pad($n): . + (" " * ([$n - length, 1] | max));

def icon:
  {"Login": "", "Note": "", "Card": "", "Identity": "", "SSH Key": ""}[.] // " ";

def mask:
  if . == null or . == "" then "" else "•" * 8 end;

def secret_keys:
  ["password", "code", "number", "ssn", "passport_number", "license_number", "private_key"];

# rbw list --raw: one line per entry, the id first for fzf to hand back.
def entry_lines:
  sort_by([(.folder // "" | ascii_downcase), (.name // "" | ascii_downcase)])[]
  | (if .folder then .folder + "/" else "" end) as $dir
  | (.name // "") as $name
  | [
      .id,
      (.type // "" | icon | dim),
      ($dir | dim) + ($name | bold) + ("" | pad(44 - ($dir + $name | length))),
      (.user // "" | accent)
    ]
  | @tsv;

# rbw get --raw: every selectable value of one entry, secrets masked.
def rows:
  . as $e
  | [
      (($e.data // {}) | to_entries[]
        | select(.key != "uris" and .key != "totp" and .value != null and .value != "")
        | {
            key: "data:\(.key)",
            label: (.key | gsub("_"; " ")),
            shown: (if .key | IN(secret_keys[]) then .value | mask else .value end)
          }),
      (if ($e.data.totp // "") != "" then {key: "totp", label: "totp", shown: "✓"} else empty end),
      (($e.data.uris // []) | to_entries[] | {key: "uri:\(.key)", label: "uri", shown: .value.uri}),
      ($e.fields | to_entries[]
        | {
            key: "field:\(.key)",
            label: (.value.name // ""),
            shown: (
              if .value.type == "hidden" then .value.value | mask
              elif .value.type == "linked" then "(linked)"
              else .value.value // ""
              end
            )
          }),
      (if ($e.notes // "") != "" then
        {key: "notes", label: "notes", shown: ($e.notes | split("\n") | .[0] + (if length > 1 then " …" else "" end))}
      else empty end)
    ];

def field_lines:
  rows[] | [.key, (.label | pad(14) | accent), .shown] | @tsv;

def preview:
  (.name | bold) + (if .folder then "  " + (.folder | dim) else "" end),
  "",
  (rows[] | select(.key != "notes") | "  " + (.label | pad(14) | accent) + .shown),
  (if (.notes // "") != "" then "", ("notes" | dim), .notes else empty end);

# bw item <-> the trimmed JSON opened in the editor. Notes are edited on
# their own as plain text.
def field_types: {"text": 0, "hidden": 1, "boolean": 2, "linked": 3};

def editable:
  {name}
  + (if .type == 1 then
      {username: .login.username, password: .login.password, totp: .login.totp, uris: [.login.uris[]? | .uri]}
    elif .type == 3 then {card: .card}
    elif .type == 4 then {identity: .identity}
    else {}
    end)
  + {fields: [.fields[]? | {name, value, type: (["text", "hidden", "boolean", "linked"][.type])}]};

def merge($e):
  (.login.password // "") as $oldpw
  | (.fields // []) as $oldfields
  | .name = $e.name
  | if .type == 1 then
      (.login.uris // []) as $olduris
      | .login.username = $e.username
      | .login.password = $e.password
      | .login.totp = $e.totp
      | .login.uris = [$e.uris[]? as $u | ($olduris | map(select(.uri == $u)) | first) // {match: null, uri: $u}]
      # Same as the official clients: keep the old password, newest first, at most 5.
      | if $oldpw != "" and $e.password != $oldpw then
          .passwordHistory = ([{lastUsedDate: (now | todate), password: $oldpw}] + (.passwordHistory // []))[:5]
        else . end
    elif .type == 3 then .card = $e.card
    elif .type == 4 then .identity = $e.identity
    else . end
  | .fields = [
      $e.fields[]? as $f
      | {
          name: $f.name,
          value: $f.value,
          type: (field_types[$f.type] // 0),
          linkedId: (if $f.type == "linked" then $oldfields | map(select(.name == $f.name)) | first | .linkedId else null end)
        }
    ];
