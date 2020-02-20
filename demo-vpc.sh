#!/bin/sh
echo "setting up vpc"
vpcCount=$(aws ec2 describe-vpcs --filters "Name=tag:Name,Values=csaa-demo" | jq -r ".Vpcs | length")
if [ $vpcCount -eq 0 ]; then
    echo "vpc doesn't exist... creating"
    export VPC_ID=$(aws ec2 create-vpc --cli-input-json file://demo-vpc-def.json | jq -r ".Vpc.VpcId")
    aws ec2 create-tags --resources $VPC_ID --tags Key=Name,Value=csaa-demo Key=owner,Value=etienne_brouillard
    echo $VPC_ID
    echo "creating IGW"
    export IGW_ID=$(aws ec2 create-internet-gateway | jq -r ".InternetGateway.InternetGatewayId")
    aws ec2 create-tags --resources $IGW_ID --tags Key=Name,Value=csaa-demo-vpc-igw Key=owner,Value=etienne_brouillard
    echo "attaching IGW to VPC"
    aws ec2 attach-internet-gateway --vpc-id $VPC_ID --internet-gateway-id $IGW_ID
else
    echo "vpc exists, picking id"
    export VPC_ID=$(aws ec2 describe-vpcs --filters "Name=tag:Name,Values=csaa-demo" | jq -r ".Vpcs[-1].VpcId")
    echo $VPC_ID
fi
echo "setting up subnets"
subnetCount=$(aws ec2 describe-subnets --filter "Name=vpc-id,Values=$VPC_ID" | jq -e ".Subnets | length")
if [ $subnetCount -ne 4 ]; then
    echo "subnets don't exist... creating"
    zoneA=$(aws ec2 describe-availability-zones | jq -r ".AvailabilityZones[0].ZoneId")
    zoneB=$(aws ec2 describe-availability-zones | jq -r ".AvailabilityZones[1].ZoneId")
    echo "using Zones $zoneA and $zoneB"
    echo "public subnet a"
    if [ $(aws ec2 describe-subnets --filter "Name=vpc-id,Values=$VPC_ID" "Name=tag:Name,Values=public-subnet-a" | jq -e ".Subnets | length") -eq 0 ]; then
        export PUBLIC_SUBNET_A_ID=$(aws ec2 create-subnet --cidr-block 10.0.0.0/28 --availability-zone-id $zoneA --vpc-id $VPC_ID | jq -r ".Subnet.SubnetId")
        aws ec2 create-tags --resources $PUBLIC_SUBNET_A_ID --tags Key=Name,Value=public-subnet-a Key=owner,Value=etienne_brouillard
    fi
    echo "public subnet b"
    if [ $(aws ec2 describe-subnets --filter "Name=vpc-id,Values=$VPC_ID" "Name=tag:Name,Values=public-subnet-b" | jq -e ".Subnets | length") -eq 0 ]; then
        export PUBLIC_SUBNET_B_ID=$(aws ec2 create-subnet --cidr-block 10.0.0.16/28 --availability-zone-id $zoneB --vpc-id $VPC_ID | jq -r ".Subnet.SubnetId")
        aws ec2 create-tags --resources $PUBLIC_SUBNET_B_ID --tags Key=Name,Value=public-subnet-b Key=owner,Value=etienne_brouillard
    fi
    echo "private subnet a"
    if [ $(aws ec2 describe-subnets --filter "Name=vpc-id,Values=$VPC_ID" "Name=tag:Name,Values=private-subnet-a" | jq -e ".Subnets | length") -eq 0 ]; then
        export PRIVATE_SUBNET_A_ID=$(aws ec2 create-subnet --cidr-block 10.0.0.32/27 --availability-zone-id $zoneA --vpc-id $VPC_ID | jq -r ".Subnet.SubnetId")
        aws ec2 create-tags --resources $PRIVATE_SUBNET_A_ID --tags Key=Name,Value=private-subnet-a Key=owner,Value=etienne_brouillard
    fi
    echo "private subnet b"
    if [ $(aws ec2 describe-subnets --filter "Name=vpc-id,Values=$VPC_ID" "Name=tag:Name,Values=private-subnet-b" | jq -e ".Subnets | length") -eq 0 ]; then
        export PRIVATE_SUBNET_B_ID=$(aws ec2 create-subnet --cidr-block 10.0.0.64/27 --availability-zone-id $zoneB --vpc-id $VPC_ID | jq -r ".Subnet.SubnetId")
        aws ec2 create-tags --resources $PRIVATE_SUBNET_B_ID --tags Key=Name,Value=private-subnet-b Key=owner,Value=etienne_brouillard
    fi
    echo "creating subnet route tables"
    cp ./demo-vpc-routetable.json route-table-input.json
    sed -i 's/VPC_ID/'$VPC_ID'/' route-table-input.json
    sed -i 's/IGW_ID/'$IGW_ID'/' route-table-input.json
    export PUBLIC_ROUTE_TABLE_ID=$(aws ec2 create-route-table --cli-input-json file://route-table-input.json | jq -r ".RouteTable.RouteTableId")
    aws ec2 create-tags --resources $PUBLIC_ROUTE_TABLE_ID --tags Key=Name,Value=csaa-demo-vpc-publicrtb Key=owner,Value=etienne_brouillard
    export PRIVATE_ROUTE_TABLE_ID=$(aws ec2 create-route-table --cli-input-json file://route-table-input.json | jq -r ".RouteTable.RouteTableId")
    aws ec2 create-tags --resources $PRIVATE_ROUTE_TABLE_ID --tags Key=Name,Value=csaa-demo-vpc-privatertb Key=owner,Value=etienne_brouillard
    rm -f ./route-table-input.json
    
    echo "subnets: $PUBLIC_SUBNET_A_ID $PUBLIC_SUBNET_B_ID $PRIVATE_SUBNET_A_ID $PRIVATE_SUBNET_B_ID"
    echo "route tables: $PUBLIC_ROUTE_TABLE_ID $PRIVATE_ROUTE_TABLE_ID"
else
    echo "subnets exist... picking ids"
    export PUBLIC_SUBNET_A_ID=$(aws ec2 describe-subnets --filter "Name=vpc-id,Values=$VPC_ID" "Name=tag:Name,Values=public-subnet-a" | jq -r ".Subnets[-1].SubnetId")
    export PUBLIC_SUBNET_B_ID=$(aws ec2 describe-subnets --filter "Name=vpc-id,Values=$VPC_ID" "Name=tag:Name,Values=public-subnet-b" | jq -r ".Subnets[-1].SubnetId")
    export PRIVATE_SUBNET_A_ID=$(aws ec2 describe-subnets --filter "Name=vpc-id,Values=$VPC_ID" "Name=tag:Name,Values=private-subnet-a" | jq -r ".Subnets[-1].SubnetId")
    export PRIVATE_SUBNET_B_ID=$(aws ec2 describe-subnets --filter "Name=vpc-id,Values=$VPC_ID" "Name=tag:Name,Values=private-subnet-b" | jq -r ".Subnets[-1].SubnetId")

    export PUBLIC_ROUTE_TABLE_ID=$(aws ec2 describe-route-tables --filter "Name=tag:Name,Values=csaa-demo-vpc-publicrtb" | jq -r ".RouteTables[0].RouteTableId")
    export PRIVATE_ROUTE_TABLE_ID=$(aws ec2 describe-route-tables --filter "Name=tag:Name,Values=csaa-demo-vpc-privatertb" | jq -r ".RouteTables[0].RouteTableId")

    echo "subnets: $PUBLIC_SUBNET_A_ID $PUBLIC_SUBNET_B_ID $PRIVATE_SUBNET_A_ID $PRIVATE_SUBNET_B_ID"
    echo "route tables: $PUBLIC_ROUTE_TABLE_ID $PRIVATE_ROUTE_TABLE_ID"
fi