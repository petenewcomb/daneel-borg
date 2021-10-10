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

    /mnt/c/Windows/System32/wbem/wmic.exe product get name, version >/root/installed-programs.txt

) >/root/clone-etc-backup.log 2>&1

test -e /mnt/b || mkdir /mnt/b
mount -r -tdrvfs b: /mnt/b

borgmatic --list

echo; echo

borgmatic

echo; echo

borgmatic --list

umount /mnt/b

status=$?
echo "Backup ended: $(date)"
exit $status
