#!/bin/bash
# Creates terraform controller in ACG lab

# Environment
export AWS_DEFAULT_OUTPUT="text"
export AWS_PROFILE=acglab

# Variables
awscmd="aws ec2"
keyname="TFControl"
keyfile="tfcontrol.pem"
sg_name="tfcontrol-sg"

# Determine vpc-id
echo Connection established...
vpcid=$($awscmd describe-vpcs --query 'Vpcs[*].[VpcId]')
echo -e Getting VPC ID... ' \t\t\t' $vpcid

# Create keypair
#$awscmd create-key-pair --key-name $keyname --query 'KeyMaterial' > $keyfile
#chmod 400 tfcontrol.pem
#keyout=($($awscmd describe-key-pairs --key-name $keyname --query 'KeyPairs[*].[KeyName,KeyFingerprint]'))
echo -e Creating EC2 instance keypair... ' \t' ${keyout[1]} ${keyout[0]}

# Security group
source_ip=$(curl -s https://checkip.amazonaws.com)
echo -e Getting source IP address... ' \t\t' $source_ip
sgroupid=$($awscmd create-security-group --group-name $sg_name --description "TFControl security group" --vpc-id $vpcid)
echo -e Creating security group... ' \t\t' $sgroupid

# Open ingress ssh from source
$awscmd authorize-security-group-ingress --group-id $sgroupid --protocol tcp --port 22 --cidr $source_ip/32 2>&1 > /dev/null
echo -e SSH ingress open from $source_ip... 
##aws ec2 describe-security-groups --query 'SecurityGroups[*].[GroupName,Description,GroupId]'
## --query 'Users[*].[UserName,Arn,CreateDate,PasswordLastUsed,UserId]'

## AMI image
#aws ec2 describe-images --region us-east-1 
#aws ec2 describe-images --region us-east-1 --filters Name=architecture,Values=x86_64
#aws ec2 describe-images --owners amazon --filters "Name=name,Values=amzn*" --query 'sort_by(Images, &CreationDate)[].Name'
## Subnets
#aws ec2 describe-subnets --query "Subnets[*].SubnetId"

### Always run latest Amz image
#aws ec2 run-instances --image-id $(aws ssm get-parameters --names /aws/service/ami-amazon-linux-latest/amzn2-ami-hvm-x86_64-gp2 --query 'Parameters[0].[Value]' --output text) --count 1 --instance-type t2.medium --subnet-id subnet-0ac0f7f495eb1c852 --security-group-ids sg-0c94c94b747919ed0 --key-name TFControl1 --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=TFControl2}]'