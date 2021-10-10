#!/bin/bash

set -e

host="$1"; shift
repo="/backups/$host"
rclone_cmd="$HOME/rclone-borg.sh"
backupsDst="gcs-backups"

pid="$(ps awwx | fgrep "rclone " | fgrep " $repo" | awk '{print $1}')"
if [ -n "$pid" ]; then
   kill "$pid"
fi

cd "$repo"
set +e
borg serve --lock-wait 60 --restrict-to-path "$repo"

setsid "$rclone_cmd" "$repo/repo" "gcs-backups:${host}-borg-repo" </dev/null >>"$HOME/rclone-$host-borg-repo.log" 2>&1 &
