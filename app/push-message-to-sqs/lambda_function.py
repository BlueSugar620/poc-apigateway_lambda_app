import os
import json
import boto3

SQS_URL = os.environ.get("SQS_URL")


sqs_client = boto3.client("sqs")

def lambda_handler(event, content):

    body = event["queryStringParameters"]
    callback_url = body.get("callback_url")
    message = body.get("message", "") + "!"
    
    try:
        response = sqs_client.send_message(
            QueueUrl=SQS_URL,
            MessageBody=json.dumps({
                "callback_url": callback_url,
                "message": message,
            }),
            MessageGroupId="1",
        )
    except Exception as e:
        print(f"Cannot send message to sqs: {e}")
        raise Exception("SendMessageToSQSError")

    return {
            "statusCode": 200,
            "body": json.dumps({
                "message": "Pushed message to SQS",
                "requestId": response.get("MessageId", "Error")
                })
        }

