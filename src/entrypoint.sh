#!/bin/sh
# ===========================================================================
# SABnzbd entrypoint wrapper for the TerraMaster TOS 7 package.
#
# The upstream image boots with the s6-overlay v3 init, whose service manager
# runs as root and drops to the "abc" user; with user "1000:1000" it cannot
# start anything and the container stays up with nothing listening on 8080.
# TOS forbids root containers, so this wrapper runs exactly the command the s6
# service runs, directly as the unprivileged container user:
#
#   python3 /app/sabnzbd/SABnzbd.py --config-file /config --server 0.0.0.0
# ===========================================================================
set -u

CONFIG_DIR=/config
DOWNLOAD_DIR=/downloads

mkdir -p "$CONFIG_DIR" "$DOWNLOAD_DIR"

# SABnzbd keeps its cache and logs below the config directory.
export HOME=$CONFIG_DIR
export TZ="${TZ:-Asia/Shanghai}"
export PYTHONIOENCODING=UTF-8

exec python3 -u /app/sabnzbd/SABnzbd.py --config-file "$CONFIG_DIR" --server 0.0.0.0
