#!/bin/bash
# Creates terraform controller in ACG lab

# Environment
export AWS_DEFAULT_OUTPUT="text"
export AWS_PROFILE=acglab

# Variables
awscmd="aws ec2"
keyname="TFControl2"
keyfile="tfcontrol.pem"
sg_name="tfcontrol-sg2"
av_zone="us-east-1a"
amz_image="/aws/service/ami-amazon-linux-latest/amzn2-ami-hvm-x86_64-gp2"
inst_count="1"
inst_type="t2.medium"
osuser="ec2-user"

# Determine vpc-id
echo Connection established...
vpcid=$($awscmd describe-vpcs --query 'Vpcs[*].[VpcId]')
echo -e Getting VPC ID... ' \t\t\t' $vpcid

# Create keypair
$awscmd create-key-pair --key-name $keyname --query 'KeyMaterial' > $keyfile
chmod 400 tfcontrol.pem
keyout=($($awscmd describe-key-pairs --key-name $keyname --query 'KeyPairs[*].[KeyName,KeyFingerprint]'))
echo -e "Creating EC2 instance keypair...  \t ${keyout[1]} (${keyout[0]})"

# Security group
source_ip=$(curl -s https://checkip.amazonaws.com)
echo -e Getting source IP address... ' \t\t' $source_ip
sgroupid=$($awscmd create-security-group --group-name $sg_name --description "TFControl security group" --vpc-id $vpcid)
echo -e Creating security group... ' \t\t' $sgroupid

# Open ingress ssh from source
$awscmd authorize-security-group-ingress --group-id $sgroupid --protocol tcp --port 22 --cidr $source_ip/32 2>&1 > /dev/null
echo -e SSH ingress open from $source_ip... 

## Get subnet in us-east-1q availability zone
subnetid=$($awscmd describe-subnets --filters "Name=availability-zone,Values=$av_zone" --query "Subnets[*].[SubnetId]")

# Spin instance(s) based on latest Amazon Linux 2 AMI image
inst_id=$($awscmd run-instances --image-id $(aws ssm get-parameters --names $amz_image --query 'Parameters[0].[Value]' --output text) --count $inst_count --instance-type $inst_type --subnet-id $subnetid --security-group-ids $sgroupid --key-name $keyname --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=TF Controller}]' --query 'Instances[*].[InstanceId]')
instance=($(aws ec2 describe-instances --query 'Reservations[*].Instances[*].[PublicDnsName,PublicIpAddress]' --filters "Name=instance-id,Values=$inst_id" --output=text))
echo -e Creating instance... 
echo -e ' \t' ID: ' \t\t' $inst_id 
echo -e ' \t' DNS: ' \t\t' ${instance[0]}
echo -e ' \t' External IP: ' \t' ${instance[1]}
