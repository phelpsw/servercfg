#!/bin/bash

aws s3 cp s3://phelps-swim-data/id_rsa.pub /tmp/
cat /tmp/id_rsa.pub >> /home/ubuntu/.ssh/authorized_keys
rm /tmp/id_rsa.pub

