import json
from typing import Any
import requests

def lambda_handler(event: dict[str, Any], content: Any) -> dict[str, Any]:

    return {
            "statusCode": 200,
            "body": json.dumps({
                "message": "Hello World!"
            })
        }
