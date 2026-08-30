#!/bin/sh
# cargokit (used by flutter_rust_bridge) invokes rustup even for the native
# Linux target. The Rust toolchain in the Flatpak manifest is installed from
# the official standalone archive, which includes cargo/rustc but not rustup.
#
# The target is already present in that archive, so this small build-only shim
# implements the read-only commands cargokit needs and forwards `rustup run`
# directly to cargo. It never downloads a toolchain during the sandbox build.
set -eu

readonly toolchain='stable-x86_64-unknown-linux-gnu'
readonly target='x86_64-unknown-linux-gnu'

case "${1:-}" in
  toolchain)
    if [ "${2:-}" = 'list' ]; then
      printf '%s (default)\n' "$toolchain"
      exit 0
    fi
    ;;
  target)
    if [ "${2:-}" = 'list' ] && [ "${5:-}" = '--installed' ]; then
      printf '%s\n' "$target"
      exit 0
    fi
    ;;
  run)
    # Discard `run` and the resolved toolchain name, then execute cargo.
    shift 2
    exec "$@"
    ;;
esac

printf 'Unsupported rustup command in Flatpak build: %s\n' "$*" >&2
exit 2
