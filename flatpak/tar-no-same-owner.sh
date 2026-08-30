#!/bin/sh
# Flutter extracts some cached SDK artifacts with tar. Their archives retain
# numeric owner metadata that cannot be restored inside Flatpak's build
# sandbox, so preserve file contents but deliberately ignore ownership.
exec /usr/bin/tar --no-same-owner "$@"
