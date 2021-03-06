#!/bin/bash

# Parameters
AMI="ami-835b4efa"
KEY="supernova_5_12_2017"
ENI="eni-ce006cb3"

# TODO: Delete old ebs volume

#
# Terminate previous instance if ENI is still attached
#
old_instance=$(aws ec2 describe-network-interface-attribute \
    --network-interface-id ${ENI} \
    --attribute attachment \
    --query Attachment.InstanceId)
if [ $old_instance != "null" ]; then
    echo "Found existing instance $old_instance with ENI attached, terminating"
    # Strip quotes from around the instance id
    old_instance=$(sed -e 's/^"//' -e 's/"$//' <<<"$old_instance")

    # Terminate the instance
    aws ec2 terminate-instances --instance-ids $old_instance

    term_state=""
    while [[ $term_state != "null" ]]
    do
        sleep 10
        term_state=$(aws ec2 describe-network-interface-attribute \
            --network-interface-id ${ENI} \
            --attribute attachment \
            --query Attachment.InstanceId)
        echo "Waiting for instance shutdown"
    done
fi

#
# ENI Should now be available
#
instance_id=$(aws ec2 run-instances --image-id ${AMI} \
    --count 1 --instance-type t2.micro \
    --key-name ${KEY} --user-data=file://cloud-config \
    --network-interfaces "[ { \"NetworkInterfaceId\": \"${ENI}\", \"DeviceIndex\": 0 } ]" \
    --query 'Instances[0].InstanceId')

if [ $? -ne 0 ]
then
    echo "aws ec2 run-instances failed"
    exit 1
fi

echo "Created instance id $instance_id"

# Wait until instance is running
state=""
while [[ $state != "running" ]]
do
    sleep 5
    state=$(aws ec2 describe-instances --filter "Name=instance-id,Values=$instance_id" \
        --query 'Reservations[0].Instances[0].State.Name' --output text)
    echo $state
done

#
# Print helpful login details
#
dnsname=$(aws ec2 describe-instances \
    --filter "Name=instance-id,Values=$instance_id" \
    --query 'Reservations[0].Instances[0].PublicDnsName')
dnsname=$(sed -e 's/^"//' -e 's/"$//' <<<"$dnsname")
echo "ssh -i ~/.ssh/${KEY}.pem ubuntu@${dnsname}"

