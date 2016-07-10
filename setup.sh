#!/bin/bash

git clone https://github.com/mozilla-services/syncserver
cd syncserver
make build
make test

# TODO: fix public url to match reality
# TODO: Generate key
sed 's|public_url = http://localhost:5000/|public_url = http://localhost:5000/|' <syncserver.ini >syncserver.ini
sed 's|#sqluri = sqlite:////tmp/syncserver.db|sqluri = sqlite:////tmp/syncserver.db|' <syncserver.ini >syncserver.ini

cat > /etc/init/syncserver <<'endmsg'
description "Mozilla Firefox sync server"

start on (local-filesystems and net-device-up IFACE!=lo)
stop on runlevel [!2345]

env STNORESTART=yes
env HOME=/home/ubuntu
setuid "ubuntu"
setgid "ubuntu"

chdir /home/ubuntu/syncserver
exec make serve

respawn
endmsg

# TODO: Reboot or start service
