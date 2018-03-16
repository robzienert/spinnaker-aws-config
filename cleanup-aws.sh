#!/bin/bash
# set -x 

ARN_FILENAME=aws_arns.json

validate(){
	print_function_details
	if [ ! -e $ARN_FILENAME ] 
	then
		print_error_and_exit "File aws_arns.json does not exist. No resources to clean up."
	fi 
}

delete_vpc_and_subnet(){
	print_function_details
	# Clean up VPC and Subnet
	aws ec2 disassociate-route-table --association-id $(jq -r '.AWS_RT_ASSOCIATION_ID' $ARN_FILENAME)
	aws ec2 delete-route-table --route-table-id $(jq -r '.AWS_ROUTE_TABLE_ID' $ARN_FILENAME)

	aws ec2 detach-internet-gateway --internet-gateway-id $(jq -r '.AWS_INTERNET_GATEWAY_ID' aws_arns.json) --vpc-id $(jq -r '.AWS_VPC_ID' $ARN_FILENAME)
	aws ec2 delete-internet-gateway --internet-gateway-id $(jq -r '.AWS_INTERNET_GATEWAY_ID' $ARN_FILENAME)

	sleep 5

	aws ec2 delete-subnet --subnet-id $(jq -r '.AWS_SUBNET_ID' $ARN_FILENAME)
	aws ec2 delete-vpc --vpc-id $(jq -r '.AWS_VPC_ID' $ARN_FILENAME)

	# Clean up Keypair
	aws ec2 delete-key-pair --key-name $(jq -r '.AWS_KEYPAIR_NAME' $ARN_FILENAME)
}

delete_policies_and_roles(){
	print_function_details
	# Clean up Policies
	aws iam delete-policy --policy-arn $(jq -r '.AWS_ASSUME_ROLE_POLICY_ARN' $ARN_FILENAME)	
	aws iam delete-policy --policy-arn $(jq -r '.AWS_PASS_ROLE_POLICY_ARN' $ARN_FILENAME)

	# Clean up Roles 
	aws iam delete-role --role-name BaseIAMRole
	aws iam delete-role --role-name SpinnakerAuthRole
	aws iam delete-role --role-name spinnakerManaged
}

print_function_details(){
		echo "Script step: " ${FUNCNAME[1]}	
}

print_error_and_exit(){
	ERROR_MSG=$1
	echo "Error: " $ERROR_MSG
	exit 1
}

validate
delete_vpc_and_subnet
delete_policies_and_roles