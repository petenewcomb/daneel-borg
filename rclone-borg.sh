#!/bin/bash

set -e

repo="${1%/}"
cool_down_period="${COOL_DOWN_PERIOD:-0}"
if ! [ "$cool_down_period" -ge 0 ]; then
    echo "$(date) Invalid COOL_DOWN_PERIOD \`$cool_down_period'" >&2
    exit 1
fi

if ls "$repo/lock.exclusive" 2>/dev/null | egrep -qx "$(hostname)"'@[0-9]+\.'"$PPID"'-0'; then
    echo "$(date) Borg repo $repo locked." >&2
else
    if [ "$cool_down_period" -gt 0 ]; then
	echo "$(date) Waiting for cool down period" >&2
	sleep "$cool_down_period"
    fi
    echo "$(date) Locking borg repo $repo" >&2
    exec borg with-lock --lock-wait 1 "$repo" "$0" "$@"
fi

# Official timestamp for this run, now that we're locked.
ts="$(date +%s)"

# Time to wait until to ensure that competitors have already given up
finish_after=$(($ts+(2*$cool_down_period)))

function wait_out_competitors() {
    finish_time="$(date +%s)"
    if [ $finish_time -lt $finish_after ]; then
	echo "$(date) Waiting for others to cool down..." >&2
	sleep $(($finish_after-$finish_time))
    fi
    echo "$(date) Exiting." >&2
}
trap wait_out_competitors EXIT

src="$repo"; shift
dst="${1%/}"; shift

echo "$(date) Checking config file" >&2
configsum="$(sha256sum <"$src/config" | cut -d' ' -f1)"
cp -vup "$src/config" "$src/config.$configsum"

filterargs=(
    --filter '+ log/**'
    --filter '+ data/**'
    --filter '+ config.*'
    --filter '- **'
)

function rxesc() {
    echo "$1" | sed -e 's/[^^]/[&]/g' -e 's/\^/\\^/g'
}
srcrx="$(rxesc "$src")"

checkpatterns=(
    -e ': File not in (GCS bucket|Local file system at) '
    -e ' Failed to check with ([0-9]+) errors: last error was: \1 differences found$'
    -e ' NOTICE: GCS bucket [-_.a-z0-9]+: [0-9]+ (matching files|files missing|differences found|errors while checking)$'
    -e ' NOTICE: Local file system at '"$srcrx"': [0-9]+ files missing$'
)

month="$(TZ=UTC date -d"@$ts" +%Y-%m)"
mkdir -p "$src/log/$month"
echo "$(date) Generating $src/log/$month/$ts.check" >&2
rclone check --combined "$src/log/$month/$ts.check" --fast-list --filter "- log/$month/$ts.check" "${filterargs[@]}" "$src" "$dst/" 2>&1 | (! egrep -v "${checkpatterns[@]}" >&2)
egrep -v '^[-=] ' "$src/log/$month/$ts.check" | sort
gzip -9 "$src/log/$month/$ts.check"

echo "$(date) Starting upload..." >&2
rclone copy -v --immutable --transfers 1 --fast-list "${filterargs[@]}" "$src" "$dst/"
echo "$(date) Upload finished!" >&2
