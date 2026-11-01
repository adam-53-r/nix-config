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
