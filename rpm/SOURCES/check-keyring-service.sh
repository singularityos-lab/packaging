#!/bin/bash
set -euo pipefail
CHECK_DIR=$(mktemp -d "${TMPDIR:?}/keyring.XXXXXX")
export GTK_A11Y=none
export XDG_RUNTIME_DIR="$CHECK_DIR/run" XDG_DATA_HOME="$CHECK_DIR/data"
export XDG_CACHE_HOME="$CHECK_DIR/cache" XDG_CONFIG_HOME="$CHECK_DIR/config"
unset XDG_DATA_DIRS
mkdir -p "$XDG_RUNTIME_DIR" "$XDG_DATA_HOME" "$XDG_CACHE_HOME" "$XDG_CONFIG_HOME"
chmod 700 "$XDG_RUNTIME_DIR"
xvfb-run -a dbus-run-session -- bash -c '
    set -euo pipefail
    "$1" & daemon=$!
    trap "kill $daemon 2>/dev/null || true" EXIT
    sleep 12
    kill -0 "$daemon"
    owner=$(gdbus call --session --dest org.freedesktop.DBus --object-path /org/freedesktop/DBus --method org.freedesktop.DBus.GetConnectionUnixProcessID org.freedesktop.secrets)
    test "$owner" = "(uint32 $daemon,)"
    gdbus call --session --dest org.freedesktop.secrets --object-path /org/freedesktop/secrets --method org.freedesktop.Secret.Service.ReadAlias default
    echo "Secret Service remained alive and owned its bus name after 12 seconds"
' keyring-check "$1"
