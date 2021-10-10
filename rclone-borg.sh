#!/bin/bash

set -e

repo="${1%/}"

if ls "$repo/lock.exclusive" 2>/dev/null | egrep -qx "$(hostname)"'@[0-9]+\.'"$PPID"'-0'; then
   echo "$(date) Borg repo $repo locked." >&2
else
   echo "$(date) Waiting for cool down period" >&2
   sleep 1800
   echo "$(date) Locking borg repo $repo..." >&2
   exec borg with-lock --lock-wait 1 "$repo" "$0" "$@"
fi

src="$repo"; shift
dst="${1%/}"; shift

rclone copy -v --transfers 1 --fast-list --gcs-storage-class ARCHIVE "$@" "$src/data" "$dst/data"
rclone copy -v --transfers 1 --fast-list --gcs-storage-class STANDARD --header-upload "x-goog-storage-class: STANDARD" --exclude '{data,lock.**}' "$@" "$src" "$dst"
rclone sync -v --transfers 1 --fast-list --gcs-storage-class STANDARD --header-upload "x-goog-storage-class: STANDARD" --exclude 'lock.**' "$@" "$src" "$dst"
