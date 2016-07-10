#!/bin/bash

git clone https://github.com/mozilla-services/syncserver /home/ubuntu/syncserver
cd /home/ubuntu/syncserver
make build
make test

SYNCPORT=5000
SYNCHOST="argus.williamslabs.com"
KEY=`head -c 20 /dev/urandom | sha1sum | awk '{print $1}'`
sed "s|public_url = http://localhost:5000/|public_url = http://$SYNCHOST:$SYNCPORT/|" <syncserver.ini >tmp.ini
sed 's|#sqluri = sqlite:////tmp/syncserver.db|sqluri = sqlite:////tmp/syncserver.db|' <tmp.ini >tmp2.ini
sed "s/#secret = INSERT_SECRET_KEY_HERE/secret = $KEY/" <tmp2.ini >syncserver.ini
rm tmp.ini tmp2.ini

cat > /etc/init/syncserver.conf <<'endmsg'
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

# Start service
start syncserver

