#!/bin/bash
# Creates terraform controller in ACG lab

# Environment
export AWS_DEFAULT_OUTPUT="text"
export AWS_PROFILE=acglab

# Variables
awsec="aws ec2"
awsiam="aws iam"
keyname="TFControl"
keyfile="tfcontrol.pem"
sg_name="tfcontrol-sg"
av_zone="us-east-1a"
amz_image="/aws/service/ami-amazon-linux-latest/amzn2-ami-hvm-x86_64-gp2"
inst_count="1"
inst_type="t2.medium"
osuser="ec2-user"
iamprofile="SSMInstanceProfile"
ssmrole="SSMProfileRole"
ssmpolicy="arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"

# SSM Role, instance profile creation & assignment
$awsiam create-role --role-name $ssmrole --assume-role-policy-document file://ec2.json --query 'Role.[RoleName]' 2>&1 > /dev/null
$awsiam attach-role-policy --policy-arn $ssmpolicy --role-name $ssmrole
$awsiam create-instance-profile --instance-profile-name $iamprofile 2>&1 > /dev/null
$awsiam add-role-to-instance-profile --role-name $ssmrole --instance-profile-name $iamprofile

echo -e Creating SSM instance profile... ' \t' $iamprofile

