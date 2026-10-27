#!/bin/sh
set -eu

repo_root=$(git -C "$(dirname "$0")/.." rev-parse --show-toplevel)
plugin_version=$(awk '
  /^  protoc_plugin:$/ { in_package = 1; next }
  in_package && /^  [^ ]/ { exit }
  in_package && /^    version: / { gsub(/"/, "", $2); print $2; exit }
' "$repo_root/pubspec.lock")
plugin_script="$HOME/.pub-cache/hosted/pub.dev/protoc_plugin-$plugin_version/bin/protoc_plugin.dart"

exec dart --packages="$repo_root/.dart_tool/package_config.json" "$plugin_script" -c "$@"