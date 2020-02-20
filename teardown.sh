#!/bin/sh
echo "deleting pre-existing instances"
aws ec2 terminate-instances --instance-ids $(aws ec2 describe-instances --filter "Name=tag:project,Values=csaa-demo" --region us-east-2 | jq -r ".Reservations[].Instances[].InstanceId") --region us-east-2