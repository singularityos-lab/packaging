#!/bin/bash
set -euo pipefail
CHECK_DIR=$(mktemp -d "${TMPDIR:?}/service.XXXXXX")
export GTK_A11Y=none GTK_USE_PORTAL=0
export XDG_RUNTIME_DIR="$CHECK_DIR/run" XDG_DATA_HOME="$CHECK_DIR/data"
export XDG_CACHE_HOME="$CHECK_DIR/cache" XDG_CONFIG_HOME="$CHECK_DIR/config"
mkdir -p "$XDG_RUNTIME_DIR" "$XDG_DATA_HOME" "$XDG_CACHE_HOME" "$XDG_CONFIG_HOME"
chmod 700 "$XDG_RUNTIME_DIR"
SOURCES=()
for source in subprojects/singularity-keyring/src/*.vala; do
    [ "$(basename "$source")" = main.vala ] || SOURCES+=("$source")
done
valac --pkg gtk4 --pkg json-glib-1.0 -X '-DGETTEXT_PACKAGE="singularity-keyring"' \
    -X "-I$PWD/subprojects/singularity-keyring/src" -X -lgcrypt -X -lsodium \
    -o "$CHECK_DIR/service-check" "$1" "${SOURCES[@]}" \
    subprojects/singularity-keyring/src/crypto.vapi subprojects/singularity-keyring/src/crypto.c
xvfb-run -a dbus-run-session -- "$CHECK_DIR/service-check"
