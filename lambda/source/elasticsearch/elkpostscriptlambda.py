#!bin/bash/python


from __future__ import print_function
from botocore.vendored import requests

# import cfnresponse

import json
import requests

import boto3
import os
import time

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
        #send(event, context, FAILED, str(e), 'error')
        #raise Exception(FAILED)

def lambda_handler(event, context):

    print("Received event:")
    print(json.dumps(event))


    try:
        responseStatus = 'SUCCESS'
        print('OS environment -- ' + os.environ['DomainEndpoint'])
        # If the Cloudformation Stack is being created, call the desired Elastic APIs for configuration
        if event['RequestType'] == 'Create':
    
            uri = os.environ['DomainEndpoint']
    
            putRequest = json.dumps({
    
                  "index_patterns": [
                    "solumina*"
                  ],
                  "settings": {
                    "index.max_ngram_diff": "8",
                    "analysis": {
                      "analyzer": {
                        "ibaset_analyzer": {
                          "tokenizer": "ibaset_ngram_tokenizer",
                          "filter": [
                            "lowercase"
                          ]
                        }
                      },
                      "tokenizer": {
                        "ibaset_ngram_tokenizer": {
                          "type": "nGram",
                          "min_gram": "3",
                          "max_gram": "11",
                          "token_chars": []
                        },
                        "white_tokenizer": {
                          "type": "whitespace"
                        }
                      }
                    },
                    "number_of_shards": 2,
                    "number_of_replicas" : "2"
                  },
                  "mappings": {
                    "doc": {
                      "properties": {
                        "oper_no": {
                          "type": "text",
                          "analyzer": "ibaset_analyzer",
                          "fields": {
                            "keyword": {
                              "type": "keyword",
                              "ignore_above": 256
                            }
                          }
                        },
                        "order_id": {
                          "type": "text"
                        },
                        "order_no": {
                          "type": "text",
                          "analyzer": "ibaset_analyzer",
                          "fields": {
                            "keyword": {
                              "type": "keyword",
                              "ignore_above": 256
                            }
                          }
                        },
                        "oper_key": {
                          "type": "text"
                        },
                        "part_no": {
                          "type": "text",
                          "analyzer": "ibaset_analyzer",
                          "fields": {
                            "keyword": {
                              "type": "keyword",
                              "ignore_above": 256
                            }
                          }
                        },
                        "serial_no": {
                          "type": "text",
                          "analyzer": "ibaset_analyzer",
                          "fields": {
                            "keyword": {
                              "type": "keyword",
                              "ignore_above": 256
                            }
                          }
                        },
                        "lot_no": {
                          "type": "text",
                          "analyzer": "ibaset_analyzer",
                          "fields": {
                            "keyword": {
                              "type": "keyword",
                              "ignore_above": 256
                            }
                          }
                        },
                        "asgnd_work_center": {
                          "type": "text",
                          "analyzer": "ibaset_analyzer",
                          "fields": {
                            "keyword": {
                              "type": "keyword",
                              "ignore_above": 256
                            }
                          }
                        },
                        "updt_userid": {
                          "type": "text",
                          "analyzer": "ibaset_analyzer",
                          "fields": {
                            "keyword": {
                              "type": "keyword",
                              "ignore_above": 256
                            }
                          }
                        }
                      }
                    }
                  }
    
            })
            print('PUT Request: \n' + putRequest)
            response = requests.put(uri, data=putRequest, headers={"Content-Type": "application/json"}, timeout= 30)
            results = json.loads(response.text)
            print('Results: \n' + response.text)
            stack_name = os.environ['stackName']
            # Sleep for 10 second, delete this code for production.
            send(event, context, SUCCESS, outputData)
            time.sleep(120)
            print('About to delelete stack # ' + stack_name)

            return delete_cfn(event, context, stack_name)
        else:
            send(event, context, SUCCESS, outputData)
    except Exception as e:
        print("send(..) failed executing handler (..): " + str(e))
        #send(event, context, FAILED, str(e), 'error')
      #raise Exception(FAILED)

    

if __name__ == '__main__':
    lambda_handler('event', 'handler')