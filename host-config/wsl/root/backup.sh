#!/bin/bash

set -e

/usr/sbin/logrotate -s /var/lib/logrotate/backup-status /root/backup-logrotate.conf

exec &> >(tee -a /var/log/backup.log)

node="$(uname -n)"

echo "Backup started for $node: $(date)"

function dsums() {(
set +e
echo "dsums: starting"
    debsums "$@"
    status=$?
echo "dsums: got status $status"
    if [ $status -eq 2 ]; then
        status=0
    fi
echo "dsums: returning $status"
    return $status
)}

set +e
(
    set -e

    echo "Running apt-clone..."
    apt-clone clone /root/apt-clone-state-$node.tar.gz

    echo "Logging nonstandard /etc files..."
    sums="$(dsums -e)"
    find /etc -type f | grep -vFf <(echo "$sums" | sed 's/[[:space:]]*OK$//') >/root/nonstandard-etc-files.txt

    echo "Logging changed conf files..."
    dsums -ec >/root/changed-conf-files.txt

) >/root/clone-etc-backup.log 2>&1

status=$?
cat /root/clone-etc-backup.log >&2
if [ $status -ne 0 ]; then
    exit $status
fi

set -e

borgmatic --info
borgmatic --list

echo; echo

borgmatic

echo; echo

borgmatic --info
borgmatic --list

umount /mnt/b

status=$?
echo "Backup ended: $(date)"
exit $status
