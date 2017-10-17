#!/bin/bash

# Setup SSH Keys
#wget https://github.com/phelpsw.keys -O /tmp/pubkeys
#cat /tmp/pubkeys >> /home/ubuntu/.ssh/authorized_keys

aws s3 cp s3://phelps-swim-data/id_rsa.pub /tmp/
cat /tmp/id_rsa.pub >> /home/ubuntu/.ssh/authorized_keys
rm /tmp/id_rsa.pub
#chmod 600 /home/ubuntu/.ssh/authorized_keys
#chown ubuntu:ubuntu /home/ubuntu/.ssh/authorized_keys

