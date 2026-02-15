#!/bin/bash
set -e

sudo service dbus start
exec /usr/sbin/sshd -D
