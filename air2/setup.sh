#!/bin/bash

# Setup SSH Keys
wget https://github.com/phelpsw.keys -O /tmp/pubkeys
cat /tmp/pubkeys >> /home/ubuntu/.ssh/authorized_keys

