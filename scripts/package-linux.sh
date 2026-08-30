#!/usr/bin/env bash
# Build the Flutter/Rust Linux bundle and package it for Debian or Fedora.
# No root access is needed to create packages.
set -euo pipefail

readonly APP_NAME="meraki"
readonly APP_ID="com.meraki.player"
readonly INSTALL_DIR="/opt/${APP_NAME}"

format="all"
skip_build=false

usage() {
  cat <<'EOF'
Usage: scripts/package-linux.sh [--format bundle|deb|rpm|all] [--skip-build]

  --format      Artifact to create (default: all).
  --skip-build  Reuse build/linux/x64/release/bundle. Useful in CI packaging jobs.

Outputs are placed in dist/linux/.
EOF
}

while (($#)); do
  case "$1" in
    --format)
      format="${2:-}"
      shift 2
      ;;
    --skip-build)
      skip_build=true
      shift
      ;;
    --help|-h)
      usage
      exit 0
      ;;
    *)
      echo "Unknown option: $1" >&2
      usage >&2
      exit 2
      ;;
  esac
done

case "$format" in
  bundle|deb|rpm|all) ;;
  *)
    echo "Invalid --format value: $format" >&2
    exit 2
    ;;
esac

root_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$root_dir"

readonly bundle_dir="$root_dir/build/linux/x64/release/bundle"
# Cargo writes workspace members to the workspace-level target directory.
readonly rust_library="$root_dir/target/release/librust_lib_meraki.so"
readonly desktop_file="$root_dir/packaging/linux/${APP_ID}.desktop"
readonly icon_directory="$root_dir/packaging/linux/icons"
readonly dist_dir="$root_dir/dist/linux"

version_line="$(awk '/^version:/ { print $2; exit }' pubspec.yaml)"
if [[ -z "$version_line" ]]; then
  echo "Could not read the application version from pubspec.yaml." >&2
  exit 1
fi
readonly deb_version="$version_line"
readonly rpm_version="${version_line%%+*}"
rpm_release="${version_line#*+}"
if [[ "$rpm_release" == "$version_line" || -z "$rpm_release" ]]; then
  rpm_release="1"
fi
readonly rpm_release

flutter_bin="${FLUTTER_BIN:-flutter}"

require_command() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "Required command not found: $1" >&2
    exit 1
  fi
}

build_bundle() {
  require_command "$flutter_bin"
  require_command cargo

  echo "==> Building Rust release library"
  cargo build --manifest-path rust_core/Cargo.toml --release

  echo "==> Building Flutter Linux release bundle"
  "$flutter_bin" build linux --release

  if [[ ! -f "$rust_library" ]]; then
    echo "Rust release library was not created: $rust_library" >&2
    exit 1
  fi

  install -d "$bundle_dir/lib"
  install -m 0755 "$rust_library" "$bundle_dir/lib/librust_lib_meraki.so"
  cmp -s "$rust_library" "$bundle_dir/lib/librust_lib_meraki.so" || {
    echo "Rust FFI library copy verification failed." >&2
    exit 1
  }
}

verify_bundle() {
  [[ -x "$bundle_dir/$APP_NAME" ]] || {
    echo "Flutter bundle executable not found: $bundle_dir/$APP_NAME" >&2
    exit 1
  }
  [[ -f "$bundle_dir/lib/librust_lib_meraki.so" ]] || {
    echo "Rust FFI library missing from bundle: $bundle_dir/lib/librust_lib_meraki.so" >&2
    exit 1
  }
  [[ -f "$desktop_file" && \
    -f "$icon_directory/hicolor/512x512/apps/${APP_ID}.png" ]] || {
    echo "Desktop integration templates are missing under packaging/linux/." >&2
    exit 1
  }
}

if [[ "$skip_build" == false ]]; then
  build_bundle
fi
verify_bundle

if [[ "$format" == "bundle" ]]; then
  echo "Release bundle ready: $bundle_dir"
  exit 0
fi

mkdir -p "$dist_dir"
work_dir="$(mktemp -d)"
trap 'rm -rf "$work_dir"' EXIT
stage_dir="$work_dir/root"

prepare_stage() {
  install -d \
    "$stage_dir$INSTALL_DIR" \
    "$stage_dir/usr/bin" \
    "$stage_dir/usr/share/applications" \
    "$stage_dir/usr/share/icons"

  cp -a "$bundle_dir/." "$stage_dir$INSTALL_DIR/"
  install -m 0644 "$desktop_file" \
    "$stage_dir/usr/share/applications/${APP_ID}.desktop"
  # Ship standard hicolor PNG sizes so desktop environments can select the
  # best resolution for the application menu, dock, and task switcher.
  cp -a "$icon_directory/." "$stage_dir/usr/share/icons/"

  cat > "$stage_dir/usr/bin/$APP_NAME" <<EOF
#!/usr/bin/env sh
exec "$INSTALL_DIR/$APP_NAME" "\$@"
EOF
  chmod 0755 "$stage_dir/usr/bin/$APP_NAME"
}

package_deb() {
  require_command dpkg-deb
  prepare_stage
  install -d "$stage_dir/DEBIAN"
  cat > "$stage_dir/DEBIAN/control" <<EOF
Package: $APP_NAME
Version: $deb_version
Section: sound
Priority: optional
Architecture: amd64
Maintainer: Meraki Contributors <maintainers@example.invalid>
Depends: libgtk-3-0, libglib2.0-0, libstdc++6, libgcc-s1, libasound2, libpulse0
Description: Meraki music player
 Meraki reproduz músicas locais e bibliotecas Subsonic em uma interface dark.
EOF

  local target="$dist_dir/${APP_NAME}_${deb_version}_amd64.deb"
  if ! dpkg-deb --build --root-owner-group "$stage_dir" "$target"; then
    dpkg-deb --build "$stage_dir" "$target"
  fi
  echo "Created Debian package: $target"
}

package_rpm() {
  require_command rpmbuild
  prepare_stage

  local rpm_top="$work_dir/rpmbuild"
  local source_name="${APP_NAME}-${rpm_version}"
  install -d "$rpm_top/BUILD" "$rpm_top/BUILDROOT" "$rpm_top/RPMS" \
    "$rpm_top/SOURCES" "$rpm_top/SPECS" "$rpm_top/SRPMS"
  cp -a "$stage_dir" "$rpm_top/SOURCES/$source_name"
  tar -C "$rpm_top/SOURCES" -czf "$rpm_top/SOURCES/$source_name.tar.gz" \
    "$source_name"

  cat > "$rpm_top/SPECS/${APP_NAME}.spec" <<EOF
Name:           $APP_NAME
Version:        $rpm_version
Release:        $rpm_release%{?dist}
Summary:        Meraki music player
License:        Proprietary
URL:            https://github.com/SEU-USUARIO/meraki
Source0:        $source_name.tar.gz
BuildArch:      x86_64
# The Flutter and Rust binaries are stripped release artifacts.  Fedora's
# automatic debuginfo/debugsource subpackages would be empty here and make
# rpmbuild fail its manifest validation.
%global debug_package %{nil}
Requires:       gtk3
Requires:       mesa-libGL
Requires:       libstdc++
Requires:       alsa-lib
Requires:       pulseaudio-libs

%description
Meraki reproduz músicas locais e bibliotecas Subsonic em uma interface dark.

%prep
%setup -q

%build

%install
rm -rf %{buildroot}
mkdir -p %{buildroot}
cp -a . %{buildroot}/

%files
/opt/meraki
/usr/bin/meraki
/usr/share/applications/com.meraki.player.desktop
/usr/share/icons/hicolor

%changelog
* $(LC_ALL=C date '+%a %b %d %Y') Meraki Contributors <maintainers@example.invalid> - $rpm_version-$rpm_release
- Automated package build.
EOF

  rpmbuild --define "_topdir $rpm_top" --define "_build_id_links none" \
    -bb "$rpm_top/SPECS/${APP_NAME}.spec"

  local rpm_file="$rpm_top/RPMS/x86_64/${APP_NAME}-${rpm_version}-${rpm_release}.x86_64.rpm"
  if [[ ! -f "$rpm_file" ]]; then
    rpm_file="$(find "$rpm_top/RPMS" -type f -name '*.rpm' -print -quit)"
  fi
  cp "$rpm_file" "$dist_dir/"
  echo "Created RPM package: $dist_dir/$(basename "$rpm_file")"
}

case "$format" in
  deb)
    package_deb
    ;;
  rpm)
    package_rpm
    ;;
  all)
    package_deb
    rm -rf "$stage_dir"
    package_rpm
    ;;
esac
