import json
from typing import Any
import requests

def lambda_handler(event: dict[str, Any], content: Any) -> dict[str, Any]:

    for record in event["Records"]:
        body = json.loads(record["body"])
        callback_url = body.get("callback_url")
        message = body.get("message", "") + "!"

        try:
            print("Post response to callback URL")
            post_response = requests.post(
                callback_url,
                json=json.dumps({
                    "message": message,
                }),
            )
        except Exception as e:
            print(f"Failed to post result.: {e}")
            raise Exception("PostResultError")

    return {
            "statusCode": 200,
            "body": json.dumps({
                "message": "Finished callback"
            })
        }
