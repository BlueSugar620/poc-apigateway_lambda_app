data "aws_iam_policy_document" "lambda_assume_policy" { 
  version = "2012-10-17"
  statement {
    effect = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "lambda_assume_role" { 
  name = "${var.prefix}-lambda-role"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_policy.json
}

resource "aws_iam_role_policy_attachment" "lambda_exec_policy" { 
  role = aws_iam_role.lambda_assume_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

data "archive_file" "lambda_zip" {
  type = "zip"
  source_dir = "${path.module}/../app/lambda"
  output_path = "${path.module}/lambda/lambda.zip"
}

data "archive_file" "lambda_layer_zip" { 
  type = "zip"
  source_dir = "${path.module}/../app/lambda/outputs/layer"
  output_path = "${path.module}/lambda/lambda_layer.zip"
}

resource "aws_lambda_layer_version" "lambda_layer" { 
  layer_name = "${var.prefix}-lambda-layer"
  filename = data.archive_file.lambda_layer_zip.output_path
  source_code_hash = data.archive_file.lambda_layer_zip.output_base64sha256
  compatible_runtimes = ["python3.12"]
}


resource "aws_lambda_function" "lambda_function_push_message_to_sqs" { 
  filename = data.archive_file.lambda_zip.output_path
  function_name = "${var.prefix}-push-message-to-sqs"
  role = aws_iam_role.lambda_assume_role.arn
  handler = "lambda_function.lambda_handler"
  runtime = "python3.12"
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256
}

resource "aws_lambda_permission" "from_apigateway" { 
  statement_id = "AllowExecutionFromAPIGateway"
  action = "lambda:InvokeFunction"
  function_name = aws_lambda_function.lambda_function_push_message_to_sqs.function_name
  principal = "apigateway.amazonaws.com"
  source_arn = "arn:aws:execute-api:ap-northeast-1:${data.aws_caller_identity.self.account_id}:${aws_api_gateway_rest_api.api.id}/*/${aws_api_gateway_method.hello_world.http_method}${aws_api_gateway_resource.hello_world.path}"
}

