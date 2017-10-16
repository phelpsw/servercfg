#!/bin/bash

# Setup SSH Keys
wget https://github.com/phelpsw.keys -O /tmp/pubkeys
cat /tmp/pubkeys >> /home/ubuntu/.ssh/authorized_keys

aws s3 cp s3://phelps-swim-data/id_rsa /tmp/id_rsa.pub
cat /tmp/id_rsa.pub >> /home/ubuntu/.ssh/authorized_keys
chmod 644 /home/ubuntu/.ssh/id_rsa.pub
chown ubuntu:ubuntu /home/ubuntu/.ssh/id_rsa.pub

