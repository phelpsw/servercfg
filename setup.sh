#!/bin/bash

# Set to make certbot not grab a permanent certificate (which has a quota)
debug=0

# Stop processes we are about to modify
service nginx stop

git clone https://github.com/mozilla-services/syncserver /home/ubuntu/syncserver
cd /home/ubuntu/syncserver
make build
make test

SYNCHOST="argus.williamslabs.com"
KEY=`head -c 20 /dev/urandom | sha1sum | awk '{print $1}'`
sed "s|host = 0.0.0.0|host = 127.0.0.1|" <syncserver.ini >tmp.ini
sed "s|public_url = http://localhost:5000/|public_url = https://$SYNCHOST/|" <tmp.ini >tmp1.ini
sed 's|#sqluri = sqlite:////tmp/syncserver.db|sqluri = sqlite:////tmp/syncserver.db|' <tmp1.ini >tmp2.ini
sed "s/#secret = INSERT_SECRET_KEY_HERE/secret = $KEY/" <tmp2.ini >syncserver.ini
rm tmp.ini tmp1.ini tmp2.ini

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

cat > /etc/nginx/sites-available/syncserver << 'endmsg'
server {
    listen  443 ssl;
    server_name argus.williamslabs.com;

    ssl_certificate /etc/letsencrypt/live/argus.williamslabs.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/argus.williamslabs.com/privkey.pem;

    location / {
        proxy_set_header Host $http_host;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_redirect off;
        proxy_read_timeout 120;
        proxy_connect_timeout 10;
        proxy_pass http://127.0.0.1:5000/;
    }
}
endmsg

rm /etc/nginx/sites-enabled/default
ln -s /etc/nginx/sites-available/syncserver /etc/nginx/sites-enabled/default


cd /home/ubuntu
wget https://dl.eff.org/certbot-auto
chmod a+x certbot-auto
if [ $debug -eq 1 ]
then
    ./certbot-auto --staging --non-interactive --agree-tos --email admin@williamslabs.com \
        certonly --standalone -d argus.williamslabs.com
else
    ./certbot-auto --non-interactive --agree-tos --email admin@williamslabs.com \
        certonly --standalone -d argus.williamslabs.com
fi
# Add certbot cronjob to ubuntu crontab
crontab -l -u root > /tmp/crondump
echo "17 * * * * /home/ubuntu/certbot-auto renew --standalone --non-interactive --pre-hook 'service nginx stop' --post-hook 'service nginx start' --quiet" >> /tmp/crondump
crontab -u root /tmp/crondump
rm /tmp/crondump

# Start service
start syncserver
service nginx start

