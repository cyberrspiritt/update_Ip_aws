#!/bin/bash
# script to pull my current public IP address
# and add a rule to my EC2 security group allowing me SSH access
curl https://checkip.amazonaws.com > ip.txt
awk '{ print $0 "/32" }' < ip.txt > ipnew.txt
export stuff=$(cat ipnew.txt)
aws ec2 revoke-security-group-ingress --group-id sg-xxxxxxxx --ip-permissions "`aws ec2 describe-security-groups --output json --group-id sg-xxxxxxxx --query "SecurityGroups[0].IpPermissions" --profile yyyyyy`" --profile yyyyyyy
aws ec2 authorize-security-group-ingress --group-id sg-xxxxxxxx --protocol tcp --port 22 --cidr $stuff --profile yyyyyyy
aws ec2 authorize-security-group-ingress --group-id sg-xxxxxxxx --protocol tcp --port 3306 --cidr $stuff --profile yyyyyyy
