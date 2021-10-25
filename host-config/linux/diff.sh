#!/bin/bash

diff -ru /etc etc | fgrep -v 'Only in /etc'
diff -ru /root etc | fgrep -v 'Only in /root'
