#!/bin/bash

# Setup SSH Keys
wget https://github.com/phelpsw.keys -O /tmp/pubkeys
cat /tmp/pubkeys >> /home/ubuntu/.ssh/authorized_keys

# Setup secrets
aws s3 cp s3://phelps-swim-data/ipsec.secrets /etc/
aws s3 cp s3://phelps-swim-data/ipsec.conf /etc/
chmod 600 /etc/ipsec.secrets
chmod 600 /etc/ipsec.conf

systemctl restart strongswan


cat >> /etc/sysctl.conf << 'EOF'
# Uncomment the next two lines to enable Spoof protection (reverse-path filter)
# Turn on Source Address Verification in all interfaces to
# prevent some spoofing attacks
net.ipv4.conf.default.rp_filter=0
net.ipv4.conf.all.rp_filter=0


# Uncomment the next line to enable packet forwarding for IPv4
net.ipv4.ip_forward=1

# Accept IP source route packets (we are a router)
net.ipv4.conf.all.accept_source_route = 1
EOF

sysctl -p /etc/sysctl.conf
systemctl restart systemd-sysctl

