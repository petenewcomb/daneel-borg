#!/bin/bash

set -e

cd "${BASH_SOURCE[0]%/*}"

for d in etc root; do
    diff -ru "/$d" "$d" | fgrep -v "Only in /$d" || true
done
