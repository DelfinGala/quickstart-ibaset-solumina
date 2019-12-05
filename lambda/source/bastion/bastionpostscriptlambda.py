#!bin/bash/python


from __future__ import print_function
from botocore.vendored import requests

# import cfnresponse

import json
import requests

import boto3
import os
import time

from collections import defaultdict

#  Copyright 2016 Amazon Web Services, Inc. or its affiliates. All Rights Reserved.
#  This file is licensed to you under the AWS Customer Agreement (the "License").
#  You may not use this file except in compliance with the License.
#  A copy of the License is located at http://aws.amazon.com/agreement/ .
#  This file is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, express or implied.
#  See the License for the specific language governing permissions and limitations under the License.
 
 
SUCCESS = "SUCCESS"
FAILED = "FAILED"
outputData = {}
responseBody = {}
 
def send(event, context, responseStatus, responseData, physicalResourceId=None, noEcho=False):
    responseUrl = event['ResponseURL']
 
    print('Sending to the responseURL: '+ responseUrl)
 
    responseBody = {}
    responseBody['Status'] = responseStatus
    responseBody['Reason'] = 'See the details in CloudWatch Log Stream: ' + context.log_stream_name
    responseBody['PhysicalResourceId'] = physicalResourceId or context.log_stream_name
    responseBody['StackId'] = event['StackId']
    responseBody['RequestId'] = event['RequestId']
    responseBody['LogicalResourceId'] = event['LogicalResourceId']
    responseBody['NoEcho'] = noEcho
    responseBody['Data'] = responseData
 
    json_responseBody = json.dumps(responseBody)
   
    print("Response body:\n" + json_responseBody)
 
    headers = {
        'content-type' : '', 
        'content-length' : str(len(json_responseBody))
    }
    
    try:
        response = requests.put(responseUrl,
                                data=json_responseBody,
                                headers=headers)
        print("Status code: " + response.reason)
    except Exception as e:
        print("send(..) failed executing send(..): " + str(e))
        raise

print('Loading function')

def setup_bastion(event, context, stack_name):

    try:
        print("Fethcing instance_id by searching for tag Name:LinuxBastion")

        BastionInstanceID = ''
        ec2 = boto3.resource('ec2')
        
        # Get information for all running instances
        running_instances = ec2.instances.filter(Filters=[{
            'Name': 'instance-state-name',
            'Values': ['running']}])
        
        ec2info = defaultdict()
        for instance in running_instances:
            for tag in instance.tags:
                if 'Name' in tag['Key']:
                    name = tag['Value']
                if 'LinuxBastion' in tag['Value']:    
                    BastionInstanceID = instance.instance_id
        
        print("BastionInstanceID :" + BastionInstanceID)
        
        print("Creating ssm parameter bastionID")
        ssm_client = boto3.client('ssm')
        # create a ssm parameter
        response = ssm_client.put_parameter(
            Name='bastionID',
            Description='InstanceID of the bastion host to manage EKS',
            Value=BastionInstanceID,
            Type='String',
            Overwrite=True,
            Tier='Standard'
        )

        ec2 = boto3.resource('ec2')
        instance = ec2.Instance(BastionInstanceID)
        iam_instance_profile = instance.iam_instance_profile
        
        print ('iam_instance_profile: ' + iam_instance_profile['Arn'])
        
        iam_instance_profile_arn = iam_instance_profile['Arn']
        # rolename = iam_instance_profile_arn.split('/')[len(iam_instance_profile_arn.split('/'))-1]

        rolename = ''
        kms_policy_arns = []
        client_iam = boto3.client('iam')
        response_list_roles = client_iam.list_roles()
        Role_list = response_list_roles['Roles']
        for key in Role_list:
            if 'BastionRole' in key['RoleName']:
                rolename = key['RoleName']
                print('RoleName: ' + key['RoleName']) 
                print('ARN: ' + key['Arn'])
                kms_policy_arns.append(key['Arn']) 
        
                print('rolename: ' + rolename)
                
                iam = boto3.resource('iam')
                role = iam.Role(rolename)
                
                iam = boto3.resource('iam')
                role = iam.Role(rolename)
        
                # policy_arn = 'arn:aws:iam::977306392285:policy/random'
                policy_arn = os.environ['CustomBastionPolicyARN']
        
                print('-----------------------------------------------------------')
                print(rolename)
                print('-----------------------------------------------------------')
                
                print('-----------------------------------------------------------')
                print(role)
                print('-----------------------------------------------------------')
                
                response = role.attach_policy(
                    PolicyArn=policy_arn
                )
                print('-----------------------------------------------------------')
                print(response)
                print('-----------------------------------------------------------')
                print('policy_arn: ' + os.environ['CustomBastionPolicyARN'])

        responseBody['Status']=SUCCESS
        json_responseBody = json.dumps(responseBody)
        print("Completed assigning Role stack response success:\n" + json_responseBody)
        #send(event, context, SUCCESS, outputData)
        
        ## Added for Mongo ##
        print("Creating a ingres Rule for MongoDB security group to allow traffic from EKS \n")

        ec2_client = boto3.client('ec2')
        describe_security_groups_response = ec2_client.describe_security_groups(
            Filters=[
                {
                    'Name': 'tag-key',
                    'Values': [
                        'aws:cloudformation:logical-id',
                    ]
                },
            ],
            MaxResults=123
        )


        # Create KMS Keys and attach the IAM policy with required ARNs
        sts = boto3.client('sts')
        identity = sts.get_caller_identity()
        
        # Inputs
        rds_role_name = event['ResourceProperties']['InstanceProfileRoleName']
        
        # role arns that need kms access
        rds_role_arn = 'arn:aws:iam::' + identity['Account'] + ':role/' + rds_role_name
        cfn_user_arn = identity['Arn']
        root_arn = 'arn:aws:iam::' + identity['Account'] + ':root'

        kms_policy_arns.append(rds_role_arn)
        kms_policy_arns.append(cfn_user_arn)
        kms_policy_arns.append(root_arn)
        
        print('user identity: ' + json.dumps(identity))
        
        kms_policy =  {
                        "Version": "2012-10-17",
                        "Statement": [
                            {
                                "Sid": "Enable IAM User Permissions for KMS Key",
                                "Effect": "Allow",
                                "Principal": {
                                    "AWS": kms_policy_arns
                                },
                                "Action": "kms:*",
                                "Resource": "*"
                            }
                        ]
                      }
        
        client_kms = boto3.client('kms')
        response = client_kms.create_key(
            Description='KMS key to decyrpt the QuickStart credentials',
            KeyUsage='ENCRYPT_DECRYPT',
            Origin='AWS_KMS',
            Policy=json.dumps(kms_policy)
        )
        
        print ('Created KMS Key with ARN: ' + response['KeyMetadata']['Arn']);
        print ('Created KMS Key with KeyID : ' + response['KeyMetadata']['KeyId']);

        kmskeyid = response['KeyMetadata']['KeyId']
        # You need to have user type on the password as the parameter in CFN and then pass the password to Lambda using ResourceProperties
        # More help @ https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/template-custom-resources.html
        # You can pass value as event data from cfn and then get it from event object e.g. event['ResourceProperties']['Password']
        rds_password = event['ResourceProperties']['RDSPassword']
        
        print("Creating ssm parameter RDS Password")
        ssm_client = boto3.client('ssm')
        # create a ssm parameter
        response = ssm_client.put_parameter(
            Name='SSDBAdminPassword',
            Description='Password of the RDS DB Server Admin',
            Value=rds_password,
            KeyId=kmskeyid,
            Type='SecureString',
            Overwrite=True,
            Tier='Standard'
        )

        # You need to have user type on the password as the parameter in CFN and then pass the password to Lambda using ResourceProperties
        # More help @ https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/template-custom-resources.html
        # You can pass value as event data from cfn and then get it from event object e.g. event['ResourceProperties']['Password']
        mongo_password = event['ResourceProperties']['MongoDBPassword']        
        print("Creating ssm parameter Mongo Password")
        ssm_client = boto3.client('ssm')
        # create a ssm parameter
        response = ssm_client.put_parameter(
            Name='MongoDBAdminPassword',
            Description='Password of the Mongo DB Server Admin',
            Value=mongo_password,
            KeyId=kmskeyid,
            Type='SecureString',
            Overwrite=True,
            Tier='Standard'
        )
        
        print("Finished creating ssm parameters for Mongo and RDS Password")

        
        security_group_id = ''
        for security_group in describe_security_groups_response['SecurityGroups']:
            if security_group['Tags']:
                for tag_pair in security_group['Tags']:
                    print('tag_pair[Value]: ' + tag_pair['Value'])
                    if 'MongoDBServerSecurityGroup' in tag_pair['Value']:
                        security_group_id = security_group['GroupId']
        

        source_security_group_id =  os.environ['EKSSourceSecGroupId']
        print("\n Source Security Group from enviroment variable: " +  source_security_group_id)
        print("\n MongoDB Security Group that contains the ingress rule: " + security_group_id)

        response = ec2_client.authorize_security_group_ingress(
            GroupId=security_group_id,
            IpPermissions=[
                {
                    'FromPort': 27017,
                    'IpProtocol': 'TCP',
                    'UserIdGroupPairs': [
                        {
                            'GroupId': source_security_group_id,
                        },
                    ],
                    'ToPort': 27030,
                },
            ],
        )

        print("Completed setting up the bastion.")

        ###
        
        return json_responseBody
    except Exception as e:
        print("Failed to set up the resources required by bastion instance to run scripts. Error: " + str(e))


def delete_cfn(event, context, stack_name):
    try:
        print("Delete stack start:\n" + stack_name)
        cfn = boto3.resource('cloudformation')
        stack = cfn.Stack(stack_name)
        stack.delete()
        responseBody['Status']=SUCCESS
        json_responseBody = json.dumps(responseBody)
        print("Delete stack response success:\n" + json_responseBody)
        #send(event, context, SUCCESS, outputData)
        return json_responseBody
    except Exception as e:
        print("send(..) failed executing deleting stack(..): " + str(e))

def lambda_handler(event, context):

    print("Received event:")
    print(json.dumps(event))


    try:
        responseStatus = 'SUCCESS'
        print('OS environment -- ' + os.environ['stackName'])
        # If the Cloudformation Stack is being created, call the desired Elastic APIs for configuration
        if event['RequestType'] == 'Create':
    

            stack_name = os.environ['stackName']
            # Sleep for 10 second, delete this code for production.
            send(event, context, SUCCESS, outputData)
            # time.sleep(120)
            print('About to set up the resources required by bastion instance to run scripts')

            setup_bastion(event, context, stack_name)
            time.sleep(60)

            print('About to delete lambda stack # ' + stack_name)
            ## Uncomment this for stack deletion ##
            return delete_cfn(event, context, stack_name)
        else:
            send(event, context, SUCCESS, outputData)
    except Exception as e:
        print("send(..) failed executing handler (..): " + str(e))
        #send(event, context, FAILED, str(e), 'error')
      #raise Exception(FAILED)

    

if __name__ == '__main__':
    lambda_handler('event', 'handler')