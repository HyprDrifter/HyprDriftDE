#!/bin/bash

output="/tmp/hyprdrift/apps.json"
mkdir -p "$(dirname "$output")"

# Create a temp file
temp_file="$(mktemp "${output}.tmp.XXXXXX")"

# Write the JSON structure to the temp file
{
  echo "{"
  echo "  \"apps\": ["

  first=1

  while IFS= read -r file; do
    [[ -f "$file" ]] || continue

    name=$(awk -F= '/^Name=/{print $2; exit}' "$file")
    exec=$(awk -F= '/^Exec=/{print $2; exit}' "$file" | sed 's/ *%[a-zA-Z]//g' | tr -cd '\11\12\15\40-\176')

    [[ -z "$name" || -z "$exec" ]] && continue

    [[ $first -eq 0 ]] && echo "," || first=0

    name="${name//\"/\\\"}"
    exec="${exec//\"/\\\"}"

    echo "    { \"name\": \"${name}\", \"exec\": \"${exec}\" }"
  done < <(find /usr/share/applications ~/.local/share/applications -name '*.desktop' 2>/dev/null)

  echo "  ]"
  echo "}"
} > "$temp_file"

# Atomically move the complete file into place
mv -f "$temp_file" "$output"