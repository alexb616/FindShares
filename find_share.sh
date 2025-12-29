#!/usr/bin/env bash

set -euo pipefail

SCRIPT_NAME="$(basename "$0")"

show_help() {
cat << EOF
Usage:
  $SCRIPT_NAME -e EXTENSION

Description:
  Search for files by extension inside SMB share JSON files
  and build valid UNC paths (\\HOST\\SHARE\\path\\file)

Options:
  -e EXTENSION   File extension to search for (without dot)
  -h             Show this help panel

Examples:
  $SCRIPT_NAME -e sql
  $SCRIPT_NAME -e kdbx
  $SCRIPT_NAME -e vhdx

Common high-value extensions:
  kdbx, sql, bak, bk, config, php, ps1, bat, key,
  docx, doc, xlsx, csv, py, vhdx, vhd, txt, pfx, reg
EOF
}

EXT=""

while getopts ":e:h" opt; do
  case "$opt" in
    e) EXT="$OPTARG" ;;
    h) show_help; exit 0 ;;
    *)
      echo "[!] Invalid option"
      show_help
      exit 1
      ;;
  esac
done

if [[ -z "$EXT" ]]; then
    echo "[!] You must specify a file extension using -e"
    show_help
    exit 1
fi

shopt -s nullglob

for file in *.json; do
    host="${file%.json}"
    echo -e "\n[+] Host: $host:\n"

    jq -r --arg host "$host" --arg ext "$EXT" '
        to_entries[] |
        .key as $share |
        .value |
        keys[] |
        select(ascii_downcase | endswith("." + $ext)) |
        "\\\\\($host)\\\($share)\\" + (gsub("/"; "\\"))
    ' "$file"
done
