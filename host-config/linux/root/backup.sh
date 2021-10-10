#!/bin/bash

/usr/sbin/logrotate -s /var/lib/logrotate/backup-status /root/backup-logrotate.conf

exec &> >(tee -a /var/log/backup.log)

node="$(uname -n)"

echo "Backup started for $node: $(date)"

(
    set -x

    apt-clone clone /root/apt-clone-state-$node.tar.gz

    find /etc -type f | grep -vFf <(debsums -e | sed 's/[[:space:]]*OK$//') >/root/nonstandard-etc-files.txt

    debsums -ec >/root/changed-conf-files.txt

) >/root/clone-etc-backup.log 2>&1

borgmatic --list

echo; echo

borgmatic

echo; echo

borgmatic --list

status=$?
echo "Backup ended: $(date)"
exit $status
