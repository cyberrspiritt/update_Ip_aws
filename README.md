## How to setup the script

You’ll need an IAM user which has the permission to edit security groups attached to the ec2 instance. We need the IAM Access key and Secret key to run this script. 

### Pre-requisites
AWS-cli installed. If not, get it from here [AWS CLI](https://aws.amazon.com/cli/)

### Setting up
After installing AWS CLI, it is required to create multiple profiles {in case multiple accounts of AWS are needed}. Refer [this link](https://stackoverflow.com/questions/593334/how-to-use-multiple-aws-accounts-from-the-command-line) to setup multiple accounts/profiles in AWS CLI.

### Editing the script for your own use case

1. The script performs the following actions
	1. Pulls out your public IP from the web
	2. Adds "/32" after it and saves it to a file
	3. Reads the file and copies it to a variable
	4. Revokes the existing permissions of the specified security group
	5. Adds the new IP to the specified security group
2. You can specify the security group id by replacing sg-xxxxxxxx with your security group id
3. You can add multiple port access to your ip by copying the last line and replacing the port number
4. Don't forget to modify the profile name yyyyyyy with your aws profile before using it

Happy Hacking..!! You just saved 3 minutes of your time by avoiding the whole UI related operations
