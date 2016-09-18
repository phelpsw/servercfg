#!/bin/bash

instance_id=$(aws ec2 run-instances --image-id ami-d732f0b7 --count 1 --instance-type t2.micro --key-name bravo --network-interfaces '[ { "NetworkInterfaceId": "eni-ce006cb3", "DeviceIndex": 0 } ]' --user-data=file://cloud-config --query 'Instances[0].InstanceId')

if [ $? -ne 0 ]
then
    echo "aws ec2 run-instances failed"
    exit 1
fi

echo "Created instance id"
echo $instance_id

# Wait until instance is running to attach volume
state=""
while [[ $state != "running" ]]
do
    sleep 1
    state=$(aws ec2 describe-instances --filter "Name=instance-id,Values=$instance_id" --query 'Reservations[0].Instances[0].State.Name' --output text)
    echo $state
done

# TODO: lookup volume id based on tag

aws ec2 attach-volume --volume-id vol-0783528f --instance-id $instance_id --device xvdb


