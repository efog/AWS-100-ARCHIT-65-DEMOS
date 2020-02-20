#!/bin/sh

echo "deleting previous key pair"
aws ec2 delete-key-pair --key-name eb-csaa-demo-use2 --region us-east-2
echo "creating new key pair"
aws ec2 create-key-pair --key-name eb-csaa-demo-use2 --region us-east-2 | jq -r ".KeyMaterial" > ~/.ssh/ec2_csaa_demo_key
echo "getting AMI id for instance"
export AMI_ID=$(aws ec2 describe-images --filters "Name=name,Values=ubuntu/images/hvm-ssd/ubuntu-bionic-18.04-amd64*" "Name=owner-id,Values=099720109477" --region us-east-2 --query "sort_by(Images, &CreationDate)[]" | jq -r ".[-1].ImageId")
echo "deleting pre-existing instances"
aws ec2 terminate-instances --instance-ids $(aws ec2 describe-instances --filter "Name=tag:project,Values=csaa-demo" --region us-east-2 | jq -r ".Reservations[].Instances[].InstanceId") --region us-east-2
echo "getting subnet"
export VPC_ID=$(aws ec2 describe-vpcs --filters "Name=tag:Name,Values=csaa-demo-vpc" --region us-east-2 | jq -r ".Vpcs[-1].VpcId")
export PUBLIC_SUBNET_A_ID=$(aws ec2 describe-subnets --region us-east-2 --filter "Name=vpc-id,Values=$VPC_ID" "Name=tag:Name,Values=public-subnet-a" | jq -r ".Subnets[-1].SubnetId")
export PUBLIC_SUBNET_B_ID=$(aws ec2 describe-subnets --region us-east-2 --filter "Name=vpc-id,Values=$VPC_ID" "Name=tag:Name,Values=public-subnet-b" | jq -r ".Subnets[-1].SubnetId")
export PRIVATE_SUBNET_A_ID=$(aws ec2 describe-subnets --region us-east-2 --filter "Name=vpc-id,Values=$VPC_ID" "Name=tag:Name,Values=private-subnet-a" | jq -r ".Subnets[-1].SubnetId")
export PRIVATE_SUBNET_B_ID=$(aws ec2 describe-subnets --region us-east-2 --filter "Name=vpc-id,Values=$VPC_ID" "Name=tag:Name,Values=private-subnet-b" | jq -r ".Subnets[-1].SubnetId")
echo "getting security group"
export BASTION_SECURITY_GROUP_ID=$(aws ec2 describe-security-groups --region us-east-2 --filter "Name=group-name,Values=csaa-demo-bastion-sg" | jq -r ".SecurityGroups[-1].GroupId")
export PRIVATE_SECURITY_GROUP_ID=$(aws ec2 describe-security-groups --region us-east-2 --filter "Name=group-name,Values=csaa-demo-bastiontoprivate-sg" | jq -r ".SecurityGroups[-1].GroupId")
echo "creating instance"
export INSTANCE_TAGS="ResourceType=instance,Tags=[{Key=project,Value=csaa-demo},{Key=owner,Value=etienne_brouillard}]"
aws ec2 run-instances --region us-east-2 --image-id $AMI_ID --tag-specifications $INSTANCE_TAGS --associate-public-ip-address --instance-type t3.micro --key-name eb-csaa-demo-use2 --subnet-id $PUBLIC_SUBNET_A_ID --security-group-ids $BASTION_SECURITY_GROUP_ID
aws ec2 run-instances --region us-east-2 --image-id $AMI_ID --tag-specifications $INSTANCE_TAGS --instance-type t3.micro --key-name eb-csaa-demo-use2 --subnet-id $PRIVATE_SUBNET_A_ID --security-group-ids $PRIVATE_SECURITY_GROUP_ID
aws ec2 run-instances --region us-east-2 --image-id $AMI_ID --tag-specifications $INSTANCE_TAGS --instance-typaws s3