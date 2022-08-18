# AWS-TF-Controller-ACG
## Bootstrap terraform controller in ACG lab
# TODO:
## 1. Manage instance via SSM
## 2. Work on SSM agent status check

aws configure --profile acglab
export AWS_PROFILE=acglab
# profile checks
aws configure list
aws ec2 describe-instances --profile acglab
aws iam get-account-summary --profile acglab
aws iam get-login-profile --user-name cloud_user --profile acglab
#Create EC2
## keypair
aws ec2 create-key-pair --key-name TFControl --query 'KeyMaterial' --output text > tfcontrol.pem
chmod 400 tfcontrol.pem
aws ec2 describe-key-pairs --key-name TFControl1
## Security group
### Determine vpc-id
aws ec2 describe-vpcs --query 'Vpcs[*].VpcId' --output text
aws ec2 create-security-group --group-name tfcontrol-sg --description "TFControl security group" --vpc-id vpc-05b16755dbb9d03f3
aws ec2 describe-security-groups --group-ids sg-0c94c94b747919ed0
aws ec2 authorize-security-group-ingress --group-id sg-0c94c94b747919ed0 --protocol tcp --port 22 --cidr 0.0.0.0/0 
### or --cidr 147.161.173.113/32 for own IP address

## AMI image
aws ec2 describe-images --region us-east-1 
aws ec2 describe-images --region us-east-1 --filters Name=architecture,Values=x86_64
aws ec2 describe-images --owners amazon --filters "Name=name,Values=amzn*" --query 'sort_by(Images, &CreationDate)[].Name'
## Subnets
aws ec2 describe-subnets --query "Subnets[*].SubnetId"
aws ec2 describe-subnets --query "Subnets[*].[SubnetId,AvailabilityZone]"

### Always run latest Amz image
aws ec2 run-instances --image-id $(aws ssm get-parameters --names /aws/service/ami-amazon-linux-latest/amzn2-ami-hvm-x86_64-gp2 --query 'Parameters[0].[Value]' --output text) --count 1 --instance-type t2.medium --subnet-id subnet-0ac0f7f495eb1c852 --security-group-ids sg-0c94c94b747919ed0 --key-name TFControl1 --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=TFControl2}]'
aws ec2 describe-instances --query 'Reservations[*].Instances[*].[PublicDnsName,PublicIpAddress]' --filters "Name=instance-id,Values=$inst_id"

# Tags
aws ec2 create-tags --resources i-05b38f011da036e91 --tags Key=Name,Value=TFControl1

Query examples
 --query 'Users[*].[UserName,Arn,CreateDate,PasswordLastUsed,UserId]'
 --query 'Role[*].[RoleName]' --output=text

ssh -q -o "StrictHostKeyChecking no"

# SSM
aws ssm get-connection-status --target i-0b63c6045b0f4bef0 --query 'Status'

policies for SSM IAM
AmazonSSMManagedInstanceCore, arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore
Role name: SSMInstanceProfile

1. Create role: aws iam create-role --role-name Test-Role1 --assume-role-policy-document file://ec2.json
2. Attach policy AmazonSSMManagedInstanceCore to role: aws iam attach-role-policy --policy-arn arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore --role-name Test-Role7
3. Create instance profile: aws iam create-instance-profile --instance-profile-name SSMInstanceProfile
4. Attach role to instance: aws iam add-role-to-instance-profile --role-name Test-Role7 --instance-profile-name SSMInstanceProfile1
