resource "aws_sqs_queue" "send_message_to_lambda" { 
  name = "${var.prefix}-send-message-to-lambda.fifo"
  fifo_queue = true
  content_based_deduplication = true
}

resource "aws_lambda_event_source_mapping" "sqs_to_lambda" { 
  event_source_arn = aws_sqs_queue.send_message_to_lambda.arn
  function_name = aws_lambda_function.lambda_function_read_message_from_sqs.arn
}
