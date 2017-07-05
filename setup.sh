#!/bin/bash

# Set to make certbot not grab a permanent certificate (which has a quota)
# For development purposes hitting this certificate quota will cause problems.
# Note these certs won't be valid but they won't hit the quota
debug=1

# Install dependencies of the firefox sync server
apt-get install git-core python2.7 python2.7-dev python-virtualenv \
    make g++ nginx

DB_ID="utilitydb"
SYNCHOST="argus.williamslabs.com"


#RDS_QUERY="aws rds describe-db-instances --region=${EC2_REGION} --db-instance-identifier=${DB_ID}"
#DB_HOST=`$RDS_QUERY --query 'DBInstances[0].Endpoint.Address'`
#DB_PORT=`$RDS_QUERY --query 'DBInstances[0].Endpoint.Port'`

# Stop processes we are about to modify
systemctl stop nginx

cd /home/ubuntu
su ubuntu << 'EOF'
git clone https://github.com/mozilla-services/syncserver /home/ubuntu/syncserver
cd /home/ubuntu/syncserver
make build

KEY=`head -c 20 /dev/urandom | sha1sum | awk '{print $1}'`
sed "s|host = 0.0.0.0|host = 127.0.0.1|" <syncserver.ini >tmp.ini
sed "s|public_url = http://localhost:5000/|public_url = https://argus.williamslabs.com/|" <tmp.ini >tmp1.ini
sed 's|#sqluri = sqlite:////tmp/syncserver.db|sqluri = postgresql://dbuser:dbpass@utilitydb.ceddh3kqpgak.us-west-2.rds.amazonaws.com:5432/ffsync|' <tmp1.ini >tmp2.ini
sed "s/#secret = INSERT_SECRET_KEY_HERE/secret = $KEY/" <tmp2.ini >syncserver.ini
rm tmp.ini tmp1.ini tmp2.ini

/home/ubuntu/syncserver/local/bin/pip install psycopg2
EOF


cat > /lib/systemd/system/ffsync.service << 'EOF'
[Unit]
Description=gunicorn server running Mozilla's Firefox Sync Server
After=syslog.target network.target

[Service]
Type=simple
User=ubuntu
Group=ubuntu
UMask=007
Restart=on-abort
ExecStart=/home/ubuntu/syncserver/local/bin/gunicorn --paste /home/ubuntu/syncserver/syncserver.ini

[Install]
WantedBy=multi-user.target
EOF


cat > /etc/nginx/sites-available/syncserver << 'endmsg'
server {
    listen  443 ssl;
    server_name __SYNCHOST__;

    ssl_certificate /etc/letsencrypt/live/__SYNCHOST__/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/__SYNCHOST__/privkey.pem;

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
sed "s/__SYNCHOST__/${SYNCHOST}/" </etc/nginx/sites-available/syncserver >/etc/nginx/sites-available/syncserver


rm /etc/nginx/sites-enabled/default
ln -s /etc/nginx/sites-available/syncserver /etc/nginx/sites-enabled/default


cd /home/ubuntu
wget https://dl.eff.org/certbot-auto
chmod a+x certbot-auto
if [ $debug -eq 1 ]
then
    ./certbot-auto --staging --non-interactive --agree-tos --email root@williamslabs.com \
        certonly --standalone -d $SYNCHOST
else
    ./certbot-auto --non-interactive --agree-tos --email root@williamslabs.com \
        certonly --standalone -d $SYNCHOST
fi

# Add certbot cronjob to ubuntu crontab
crontab -l -u root > /tmp/crondump
echo "17 * * * * /home/ubuntu/certbot-auto renew --standalone --non-interactive --pre-hook 'service nginx stop' --post-hook 'service nginx start' --quiet" >> /tmp/crondump
crontab -u root /tmp/crondump
rm /tmp/crondump

# Start service
systemctl enable ffsync
systemctl start ffsync
systemctl start nginx

