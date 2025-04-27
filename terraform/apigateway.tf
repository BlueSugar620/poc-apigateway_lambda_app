data "aws_iam_policy_document" "apigateway_assume_policy" { 
  version = "2012-10-17"
  statement {
    effect = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type = "Service"
      identifiers = ["apigateway.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "apigateway_assume_role" { 
  name = "${var.prefix}-apigateway-role"
  assume_role_policy = data.aws_iam_policy_document.apigateway_assume_policy.json
}

resource "aws_iam_role_policy_attachment" "apigateway_logs_policy" { 
  role = aws_iam_role.apigateway_assume_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonAPIGatewayPushToCloudWatchLogs"
}

resource "aws_iam_role_policy_attachment" "apigateway_lambda_policy" { 
  role = aws_iam_role.apigateway_assume_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaRole"
}

resource "aws_api_gateway_rest_api" "api" {
  name = "${var.prefix}-api"
}

resource "aws_api_gateway_resource" "hello_world" { 
  parent_id = aws_api_gateway_rest_api.api.root_resource_id
  path_part = "hello-world"
  rest_api_id = aws_api_gateway_rest_api.api.id
}

resource "aws_api_gateway_method" "hello_world" { 
  authorization = "NONE"
  http_method = "GET"
  resource_id = aws_api_gateway_resource.hello_world.id
  rest_api_id = aws_api_gateway_rest_api.api.id
}

resource "aws_api_gateway_integration" "hello_world" { 
  http_method = aws_api_gateway_method.hello_world.http_method
  resource_id = aws_api_gateway_resource.hello_world.id
  rest_api_id = aws_api_gateway_rest_api.api.id
  type = "AWS_PROXY"
  integration_http_method = "POST"
  content_handling = "CONVERT_TO_TEXT"
  uri = aws_lambda_function.lambda_function_push_message_to_sqs.invoke_arn
}

resource "aws_api_gateway_method_response" "hello_world_200" { 
  rest_api_id = aws_api_gateway_rest_api.api.id
  resource_id = aws_api_gateway_resource.hello_world.id
  http_method = aws_api_gateway_method.hello_world.http_method
  status_code = 200
  response_parameters = {
    "method.response.header.Access-Control-Allow-Origin" = true
  }
}

resource "aws_api_gateway_integration_response" "hello_world_200" { 
  rest_api_id = aws_api_gateway_rest_api.api.id
  resource_id = aws_api_gateway_resource.hello_world.id
  http_method = aws_api_gateway_method.hello_world.http_method
  status_code = aws_api_gateway_method_response.hello_world_200.status_code
  response_parameters = {
    "method.response.header.Access-Control-Allow-Origin" = "'*'"
  }
  depends_on = [aws_api_gateway_integration.hello_world]
}

resource "aws_api_gateway_deployment" "trial_deploy" { 
  rest_api_id = aws_api_gateway_rest_api.api.id
  triggers = {
    redeployment = sha1(jsonencode([
      aws_api_gateway_resource.hello_world.id,
      aws_api_gateway_method.hello_world.id,
      aws_api_gateway_integration.hello_world.id,
    ]))
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_api_gateway_account" "api_account" { 
  cloudwatch_role_arn = aws_iam_role.apigateway_assume_role.arn
  reset_on_delete = true
}

resource "aws_cloudwatch_log_group" "apigateway_logs" { 
  name = "/aws/${var.prefix}-api"
}

resource "aws_api_gateway_stage" "trial" { 
  deployment_id = aws_api_gateway_deployment.trial_deploy.id
  rest_api_id = aws_api_gateway_rest_api.api.id
  stage_name = "trial"

  access_log_settings {
    destination_arn = aws_cloudwatch_log_group.apigateway_logs.arn
    format = jsonencode({
      "requestId": "$context.requestId",
      "ip": "$context.identity.sourceIp",
      "requestTime": "$context.requestTime",
      "httpMethod": "$context.httpMethod",
      "routeKey": "$context.routeKey",
      "status": "$context.status",
      "protocol": "$context.protocol",
      "responseLength": "$context.responseLength",
      "integrationError": "$context.integrationErrorMessage"
    })
  }

  depends_on = [
    aws_api_gateway_account.api_account
  ]
}


