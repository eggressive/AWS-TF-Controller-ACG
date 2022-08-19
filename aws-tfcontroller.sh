#!/bin/bash
# Bootstrap terraform controller instance in ACG lab

# Environment
export AWS_DEFAULT_OUTPUT=text
export AWS_PROFILE=acglab

# Variables
keyfile=tfcontrol.pem
keyname=TFControl$1
sg_name=tfcontrol-sg$1
iamprofile=SSMProfile$1
ssmrole=SSMRole$1
av_zone=us-east-1a
amz_image="/aws/service/ami-amazon-linux-latest/amzn2-ami-hvm-x86_64-gp2"
inst_count=1
inst_type=t2.micro
osuser=ec2-user
ssmpolicy="arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"

# Determine vpc-id
echo Reaching into the Cloud...
vpcid=$(aws ec2 describe-vpcs --query 'Vpcs[*].[VpcId]')
echo -e Getting VPC ID... ' \t\t\t' $vpcid

# Create keypair
aws ec2 create-key-pair --key-name $keyname --query 'KeyMaterial' > $keyfile
chmod 400 tfcontrol.pem
keyout=($(aws ec2 describe-key-pairs --key-name $keyname --query 'KeyPairs[*].[KeyName,KeyFingerprint]'))
echo -e "Creating EC2 instance keypair...  \t ${keyout[1]} (${keyout[0]})"

# SSM Role, instance profile creation & assignment
aws iam create-role --role-name $ssmrole --assume-role-policy-document file://ec2.json --query 'Role.[RoleName]' 2>&1 > /dev/null
aws iam attach-role-policy --policy-arn $ssmpolicy --role-name $ssmrole
profilearn=$(aws iam create-instance-profile --instance-profile-name $iamprofile --query 'InstanceProfile.[Arn]')
aws iam add-role-to-instance-profile --role-name $ssmrole --instance-profile-name $iamprofile
echo -e Creating SSM instance profile...' \t' $iamprofile

# Security group
source_ip=$(curl -s https://checkip.amazonaws.com)
echo -e Getting source IP address... ' \t\t' $source_ip
sgroupid=$(aws ec2 create-security-group --group-name $sg_name --description "TFControl security group" --vpc-id $vpcid)
echo -e Creating security group... ' \t\t' $sgroupid

# Open ingress ssh from source
aws ec2 authorize-security-group-ingress --group-id $sgroupid --protocol tcp --port 22 --cidr $source_ip/32 2>&1 > /dev/null
echo SSH access open from $source_ip... 

## Get subnet in us-east-1q availability zone
subnetid=$(aws ec2 describe-subnets --filters "Name=availability-zone,Values=$av_zone" --query "Subnets[*].[SubnetId]")

# Spin instance(s) based on latest Amazon Linux 2 AMI image
echo -e Creating instance... 
inst_id=$(aws ec2 run-instances --image-id $(aws ssm get-parameters --names $amz_image --query 'Parameters[0].[Value]' --output text) --iam-instance-profile Arn=$profilearn --count $inst_count --instance-type $inst_type --subnet-id $subnetid --security-group-ids $sgroupid --key-name $keyname --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value="$keyname"}]" --query 'Instances[*].[InstanceId]')
set -x
instance=($(aws ec2 describe-instances --query 'Reservations[*].Instances[*].[PublicDnsName,PublicIpAddress]' --filters "Name=instance-id,Values=$inst_id"))
echo -e ' \t' ID: ' \t\t' $inst_id 
echo -e ' \t' DNS: ' \t\t' ${instance[0]}
echo -e ' \t' External IP: ' \t' ${instance[1]}

# Confirm SSM agent is running
#ssmstatus=$($awsssm get-connection-status --target $inst_id --query 'Status')
echo Confirming instance is up...
sleep 6
#isonline=$(aws ssm describe-instance-information --query 'InstanceInformationList[*].[PingStatus]' --filters "Key=InstanceIds,Values=$inst_id")
aws ssm describe-instance-information --filters Key=InstanceIds,Values=$inst_id #--query "InstanceInformationList[*].[PingStatus]"
set +x
#aws ssm describe-instance-information --query "InstanceInformationList[*].[PingStatus]" --filters Key=InstanceIds,Values=$inst_id
echo -e Instance state: ' \t' $isonline
#echo $isonline
