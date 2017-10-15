#!/bin/bash

wget https://phelps-swim-data.s3.amazonaws.com/ipsec.secrets -O /home/ubuntu/ipsec.secrets


# Setup SSH Keys
wget https://github.com/phelpsw.keys -O /tmp/pubkeys
cat /tmp/pubkeys >> /home/ubuntu/.ssh/authorized_keys

