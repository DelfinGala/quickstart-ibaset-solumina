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
        client_iam = boto3.client('iam')
        response_list_roles = client_iam.list_roles()
        Role_list = response_list_roles['Roles']
        for key in Role_list:
            if 'BastionRole' in key['RoleName']:
                rolename = key['RoleName']
                print('RoleName: ' + key['RoleName']) 
                print('ARN: ' + key['Arn'])
        
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