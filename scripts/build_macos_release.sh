#!/bin/sh
set -eu

repo_root=$(git rev-parse --show-toplevel)
cd "$repo_root"

release_tag=$(git tag --list 'v[0-9]*' --sort=-version:refname | awk '/^v[0-9]+\.[0-9]+\.[0-9]+$/ { print; exit }')
if [ -z "$release_tag" ]; then
  printf '%s\n' 'No semantic version tag found (expected vMAJOR.MINOR.PATCH).' >&2
  exit 1
fi

release_version=${release_tag#v}
flutter build macos --release --build-name "$release_version" "$@"

release_dir=build/macos/Build/Products/Release
app_path=$release_dir/beatwork.app
if [ ! -d "$app_path" ]; then
  printf 'Built app not found: %s\n' "$app_path" >&2
  exit 1
fi

touch "$app_path"
archive_name=beatwork_$(printf '%s' "$release_version" | tr '.' '_')
archive_dir=$release_dir/$archive_name
mkdir -p "$archive_dir"
ditto -c -k --sequesterRsrc --keepParent "$app_path" "$archive_dir/$archive_name.zip"
printf 'Release archive: %s\n' "$archive_dir/$archive_name.zip"
