#!/bin/sh
echo -ne '\033c\033]0;Operation- Havok\a'
base_path="$(dirname "$(realpath "$0")")"
"$base_path/Operation Havok.x86_64" "$@"
