#!/bin/bash

USER_NAME=user4
IMAGE_ID=ami-02fc24d56bc5f3d67 # ami-09693313102a30b2c
INSTANCE_TYPE=t2.micro
VPC_ID=vpc-04540e242cdfb35de
KEY_NAME=user4
SUBNET_ID=subnet-0d00d8b5d01e66e35
SHUTDOWN_TYPE=stop
TAGS="ResourceType=instance,Tags=[{Key=installation_id,Value=${USER_NAME}-1},{Key=Name,Value=NAME}]"

initial_command()
{
  cat <<EOF
#!/bin/sh

curl https://raw.githubusercontent.com/VladislavSemko/AWS/master/scripts/install-qrencode.sh | bash -s
EOF

}

start_vm()
{
  local private_ip_address="$1"
  local public_ip="$2"
  local name="$3"
  local user_data="$4"

  local tags=$(echo $TAGS | sed s/NAME/$name/)
  # local tags=${TAGS/NAME/$name}

  aws ec2 run-instances \
    --image-id "$IMAGE_ID" \
    --instance-type "$INSTANCE_TYPE" \
    --key-name "$KEY_NAME" \
    --subnet-id "$SUBNET_ID" \
    --instance-initiated-shutdown-behavior "$SHUTDOWN_TYPE" \
    --private-ip-address "$private_ip_address" \
    --tag-specifications "$tags" \
    --user-data "$user_data" \
    --${public_ip}

  # --security-groups "$security_group" \

  #  [--block-device-mappings <value>]
  #  [--placement <value>]
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
    start_vm 10.2.1.40 associate-public-ip-address ${USER_NAME}-vm1 file://<( initial_command )
  )

  instance_id=$(echo "${start_log}" | jq -r .Instances[0].InstanceId)

  # for i in {2..3}; do
  #   start_vm 10.2.1.$((100+i)) no-associate-public-ip-address ${USER_NAME}-vm$i > /dev/null
  # done

  sleep 2
  dns_name=$(get_dns_name "$instance_id")
  echo $dns_name
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
  exit 1
fi
