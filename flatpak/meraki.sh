#!/bin/sh
# The Flutter bundle is intentionally kept self-contained below /app/meraki.
# libmpv is installed in /app/lib by the Flatpak manifest. Keep both locations
# on the loader path: flutter_rust_bridge needs the first and media_kit needs
# the latter.
export LD_LIBRARY_PATH="/app/meraki/lib:/app/lib${LD_LIBRARY_PATH:+:${LD_LIBRARY_PATH}}"
exec /app/meraki/meraki "$@"
