#!/bin/bash

# Get the latest AMI given the specified criteria
# https://askubuntu.com/questions/53582/how-do-i-know-what-ubuntu-ami-to-launch-on-ec2
# needed as json list returned by ubuntu site is mal-formed
remove_last_comma() { sed '
$x;$G;/\(.*\),/!H;//!{$!d
    };  $!x;$s//\1/;s/^\n//'
}
AMI=`curl -s "https://cloud-images.ubuntu.com/locator/ec2/releasesTable" \
    | remove_last_comma \
    | jq -c '.aaData[] | select(contains(["16.04", "us-west-2", "hvm:ebs"]))' \
    | grep -o 'ami-[a-z0-9]\+' | head -1`

# Parameters
KEY="supernova_5_12_2017"
ENI="eni-8a358788"
NAME="SWIM-CLIENT"
INSTANCE_PROFILE_NAME="swim-vpn-instance-profile"

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
        sleep 30
        term_state=$(aws ec2 describe-network-interface-attribute \
            --network-interface-id ${ENI} \
            --attribute attachment \
            --query Attachment.InstanceId)
        echo "Waiting for instance shutdown"
    done
fi

#
# ENI Should now be available, create the instance
#
instance_id=$(aws ec2 run-instances --image-id ${AMI} \
    --count 1 --instance-type t2.micro \
    --key-name ${KEY} --user-data=file://cloud-config \
    --iam-instance-profile "{ \"Name\": \"${INSTANCE_PROFILE_NAME}\" }" \
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
    sleep 20
    state=$(aws ec2 describe-instances --filter "Name=instance-id,Values=$instance_id" \
        --query 'Reservations[0].Instances[0].State.Name' --output text)
    echo $state
done

# Tag the instance with a helpful name
aws ec2 create-tags --resources $instance_id --tags "Key=Name,Value=${NAME}"

#
# Print helpful login details
#
dnsname=$(aws ec2 describe-instances \
    --filter "Name=instance-id,Values=$instance_id" \
    --query 'Reservations[0].Instances[0].PublicDnsName')
dnsname=$(sed -e 's/^"//' -e 's/"$//' <<<"$dnsname")
echo "ssh -i ~/.ssh/${KEY}.pem ubuntu@${dnsname}"

