#!/bin/bash
IMAGE_ID=ami-02fc24d56bc5f3d67
#ami-09693313102a30b2c
INSTANCE_TYPE=t2.micro
VPC_ID=vpc-04540e242cdfb35de
KEY_NAME=user4
USER_NAME=user4
SUBNET_ID=subnet-0d00d8b5d01e66e35
SHUTDOWN_TYPE=stop
TAGS="ResourceType=instance,Tags=[{Key=installation_id,Value=${USER_NAME}-vm1},{Key=Name,Value=NAME}]"

start_vm()
{
  local private_ip_address="$1"
  local public_ip="$2"
  local name="$3"

  local tags=$(echo $TAGS | sed s/NAME/$name/)

  aws ec2 run-instances \
    --image-id "$IMAGE_ID" \
    --instance-type "$INSTANCE_TYPE" \
    --key-name "$KEY_NAME" \
    --subnet-id "$SUBNET_ID" \
    --instance-initiated-shutdown-behavior "$SHUTDOWN_TYPE" \
    --private-ip-address "$private_ip_address" \
    --tag-specifications "$tags" \
    --${public_ip} \
   | jq -r .Instances[0].InstanceId
}

get_dns_name()
{
  local instance="$1"

  aws ec2 describe-instances --instance-ids ${instance} \
  | jq -r '.Reservations[0].Instances[0].NetworkInterfaces[0].Association.PublicDnsName'
}

start()
{
  start_log=$(
    start_vm 10.2.1.40 associate-public-ip-address ${USER_NAME}-vm1
  )

  instance_id=$(echo "${start_log}" | jq -r .Instances[0].InstanceId)

 # for i in {2..3}; do
 #   start_vm 10.2.1.$((40+i)) no-associate-public-ip-address ${USER_NAME}-vm$i > /dev/null
 # done

  sleep 2
  dns_name=$(get_dns_name "$instance_id")
}

stop()
{
  ids=($(
    aws ec2 describe-instances \
    --query 'Reservations[*].Instances[?KeyName==`'$KEY_NAME'`].InstanceId' \
    --output text
  ))
  aws ec2 terminate-instances --instance-ids "${ids[@]}"
}

if [ "$1" = start ]; then
  start
elif [ "$1" = stop ]; then
  stop
else
  cat <<EOF
Usage:

  $0 start|stop
EOF
fi
