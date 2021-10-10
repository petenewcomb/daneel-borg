#!/bin/sh

ip="$1"; shift
mac="$1"; shift

ping -n -q -c1 -w1 "$ip" >/dev/null

/usr/sbin/arp -n "$ip" | fgrep "$ip" | fgrep -q "$mac"
