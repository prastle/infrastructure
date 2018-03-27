#!/bin/bash

set -eux

. /root/infrastructure/common.sh

echo "Check hostname is not 'localhost'. It is currently: $(hostname)"

if [ "$(hostname)" == "localhost" ]; then
  reportError "Hostname is set to localhost; run ./set_host_name.sh and restart the server"
  exit 0
fi
