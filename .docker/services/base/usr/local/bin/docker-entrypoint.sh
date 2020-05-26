#!/bin/zsh
set -e

# Display MotD
if [[ -e /etc/motd ]]; then cat /etc/motd; fi

exec "$@"
