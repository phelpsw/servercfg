#!/bin/bash

aws s3 cp s3://phelps-swim-data/id_rsa.pub /tmp/
cat /tmp/id_rsa.pub >> /home/ubuntu/.ssh/authorized_keys
rm /tmp/id_rsa.pub

cat >> /etc/network/if-up.d/static-route << 'EOF'
#!/bin/bash

/sbin/ip route add 155.178.68.32/27 via 172.16.1.10 dev eth0
EOF
chmod 755 /etc/network/if-up.d/static-route
