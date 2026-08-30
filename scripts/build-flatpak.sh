#!/usr/bin/env bash
# Build an installable Flatpak bundle locally. No root access is required.
set -euo pipefail

readonly app_id='com.github.lindnergui.meraki'
readonly manifest='flatpak/com.github.lindnergui.meraki.yml'
readonly build_dir='flatpak/build'
readonly repository='flatpak/repo'
readonly bundle='dist/meraki.flatpak'
readonly flathub_repo='https://dl.flathub.org/repo/flathub.flatpakrepo'

for command in flatpak flatpak-builder; do
  command -v "$command" >/dev/null 2>&1 || {
    echo "Required command not found: $command" >&2
    exit 1
  }
done

mkdir -p dist
flatpak remote-add --if-not-exists --user flathub "$flathub_repo"
flatpak-builder --force-clean --user --install-deps-from=flathub \
  --repo="$repository" "$build_dir" "$manifest"
flatpak build-bundle "$repository" "$bundle" "$app_id" \
  --runtime-repo="$flathub_repo"

echo "Created Flatpak bundle: $bundle"

