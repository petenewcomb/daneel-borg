#!/bin/bash

set -e

cd "${BASH_SOURCE[0]%/*}"

cp -vr etc/. /etc/.
chmod 0700 /etc/borgmatic
chmod 0700 /etc/borgmatic/config.yaml

cp -vr root/. /root/.
chmod 0700 /root/.ssh
