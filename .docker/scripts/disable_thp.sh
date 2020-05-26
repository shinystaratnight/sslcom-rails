#!/bin/bash
set -ex

docker run -it --privileged --pid=host alpine:3.11 nsenter -t 1 -m -u -n -i -- sh -c 'echo never > /sys/kernel/mm/transparent_hugepage/enabled'
docker run -it --privileged --pid=host alpine:3.11 nsenter -t 1 -m -u -n -i -- sh -c 'echo never > /sys/kernel/mm/transparent_hugepage/defrag'
