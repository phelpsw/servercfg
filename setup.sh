#!/bin/bash

git clone https://github.com/mozilla-services/syncserver /home/ubuntu/syncserver
cd /home/ubuntu/syncserver
make build
make test

echo "working directory"
pwd

# TODO: fix public url to match reality
# TODO: Generate key
sed 's|public_url = http://localhost:5000/|public_url = http://localhost:5000/|' <syncserver.ini >tmp.ini
sed 's|#sqluri = sqlite:////tmp/syncserver.db|sqluri = sqlite:////tmp/syncserver.db|' <tmp.ini >syncserver.ini

# Ideally would create upstart file here but to avoid 
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
