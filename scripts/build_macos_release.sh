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
exec flutter build macos --release --build-name "$release_version" "$@"