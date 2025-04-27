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

data "aws_iam_policy_document" "lambda_do_sqs" { 
  version = "2012-10-17"
  statement {
    effect = "Allow"
    actions = ["sqs:*"]

    resources = [
      "${aws_sqs_queue.send_message_to_lambda.arn}",
      "${aws_sqs_queue.send_message_to_lambda.arn}/*"
    ]
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

resource "aws_iam_policy" "lambda_do_sqs" { 
  name = "${var.prefix}-lambda-do-sqs-policy"
  policy = data.aws_iam_policy_document.lambda_do_sqs.json
}

resource "aws_iam_role_policy_attachment" "lambda_do_sqs" { 
  role = aws_iam_role.lambda_assume_role.name
  policy_arn = aws_iam_policy.lambda_do_sqs.arn
}

// Lambda for pushing message to SQS
data "archive_file" "lambda_function_push_message_to_sqs_zip" {
  type = "zip"
  source_dir = "${path.module}/../app/push-message-to-sqs"
  output_path = "${path.module}/lambda/lambda_function_push_message_to_sqs.zip"
}

resource "aws_lambda_function" "lambda_function_push_message_to_sqs" { 
  filename = data.archive_file.lambda_function_push_message_to_sqs_zip.output_path
  function_name = "${var.prefix}-push-message-to-sqs"
  role = aws_iam_role.lambda_assume_role.arn
  handler = "lambda_function.lambda_handler"
  runtime = "python3.12"
  source_code_hash = data.archive_file.lambda_function_push_message_to_sqs_zip.output_base64sha256

  environment {
    variables = {
      SQS_URL = aws_sqs_queue.send_message_to_lambda.url
    }
  }
}

resource "aws_lambda_permission" "from_apigateway" { 
  statement_id = "AllowExecutionFromAPIGateway"
  action = "lambda:InvokeFunction"
  function_name = aws_lambda_function.lambda_function_push_message_to_sqs.function_name
  principal = "apigateway.amazonaws.com"
  source_arn = "arn:aws:execute-api:ap-northeast-1:${data.aws_caller_identity.self.account_id}:${aws_api_gateway_rest_api.api.id}/*/${aws_api_gateway_method.hello_world.http_method}${aws_api_gateway_resource.hello_world.path}"
}

// Lambda for reading message from SQS
data "archive_file" "lambda_function_read_message_from_sqs_zip" { 
  type = "zip"
  source_dir = "${path.module}/../app/read-message-from-sqs"
  output_path = "${path.module}/lambda/lambda_function_read_message_from_sqs.zip"
}

data "archive_file" "lambda_layer_read_message_from_sqs_zip" { 
  type = "zip"
  source_dir = "${path.module}/../app/read-message-from-sqs/outputs/layer"
  output_path = "${path.module}/lambda/lambda_layer_function_read_message_from_sqs.zip"
}

resource "aws_lambda_layer_version" "lambda_layer_read_message_from_sqs" { 
  layer_name = "${var.prefix}-read-message-from-sqs"
  filename = data.archive_file.lambda_layer_read_message_from_sqs_zip.output_path
  source_code_hash = data.archive_file.lambda_layer_read_message_from_sqs_zip.output_base64sha256
  compatible_runtimes = ["python3.12"]
}

resource "aws_lambda_function" "lambda_function_read_message_from_sqs" { 
  filename = data.archive_file.lambda_function_read_message_from_sqs_zip.output_path
  function_name = "${var.prefix}-read-message-from-sqs"
  role = aws_iam_role.lambda_assume_role.arn
  handler = "lambda_function.lambda_handler"
  runtime = "python3.12"
  source_code_hash = data.archive_file.lambda_function_read_message_from_sqs_zip.output_base64sha256

  layers = [aws_lambda_layer_version.lambda_layer_read_message_from_sqs.arn]
}

resource "aws_lambda_permission" "from_sqs" { 
  statement_id = "AllowExecutionFromSQS"
  action = "lambda:InvokeFunction"
  function_name = aws_lambda_function.lambda_function_read_message_from_sqs.function_name
  principal = "sqs.amazonaws.com"
  source_arn = aws_sqs_queue.send_message_to_lambda.arn
}
