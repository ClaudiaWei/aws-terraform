resource "aws_lambda_function" "update_mappingtable" {
  filename                       = "lambda/update_mappingtable.zip"
  function_name                  = "update_mappingtable" 
  handler                        = "update-mappingtable.handler"
  package_type                   = "Zip"
  source_code_hash               = filebase64sha256("lambda/update_mappingtable.zip")
  runtime                        = "nodejs14.x"
  memory_size                    = "128"
  role                           = aws_iam_role.lambda_role.arn
  reserved_concurrent_executions = "-1"
  timeout                        = "10"
  architectures                  = ["x86_64"]
  tracing_config {
    mode = "PassThrough"
  }
}

resource "aws_lambda_function" "delete_mappingtable" {
  filename                       = "lambda/delete_mappingtable.zip"
  function_name                  = "delete_mappingtable" 
  handler                        = "delete-mappingtable.handler"
  package_type                   = "Zip"
  source_code_hash               = filebase64sha256("lambda/delete_mappingtable.zip")
  runtime                        = "nodejs14.x"
  memory_size                    = "128"
  role                           = aws_iam_role.lambda_role.arn
  reserved_concurrent_executions = "-1"
  timeout                        = "10"

  architectures                  = ["x86_64"]

  tracing_config {
    mode = "PassThrough"
  }
}

resource "aws_lambda_function" "CommercialVariable" {
  filename                       = "lambda/CommercialVariable.zip"
  function_name                  = "CommercialVariable" 
  handler                        = "projectCommercialVariableScheduledMapping::projectCommercialVariableScheduledMapping.Function::FunctionHandler"
  package_type                   = "Zip"
  source_code_hash               = filebase64sha256("lambda/CommercialVariable.zip")
  runtime                        = "dotnetcore3.1"
  memory_size                    = "128"
  role                           = aws_iam_role.lambda_role.arn
  reserved_concurrent_executions = "-1"
  timeout                        = "10"
  architectures                  = ["x86_64"]

  environment {
    variables = {
      AWS__S3Bucket = "project-mod-web-prod-bucket"
      S3ObjectKey__CommercialVariableMappingTable = "config/MappingTable.csv"
    }
  }
  tracing_config {
    mode = "PassThrough"
  }
}

resource "aws_lambda_function" "RawDataCompression" {
  filename                       = "lambda/RawDataCompression.zip"
  function_name                  = "RawDataCompression" 
  handler                        = "projectRawDataSheetScheduledCompression::projectRawDataSheetScheduledCompression.Function::FunctionHandler"
  package_type                   = "Zip"
  source_code_hash               = filebase64sha256("lambda/RawDataCompression.zip")
  runtime                        = "dotnetcore3.1"
  memory_size                    = "512"
  role                           = aws_iam_role.lambda_role.arn
  reserved_concurrent_executions = "-1"
  timeout                        = "10"
  architectures                  = ["x86_64"]

  environment {
    variables = {
      AWS__S3Bucket = "project-mod-prod-bucket"
    }
  }
  tracing_config {
    mode = "PassThrough"
  }
}

resource "aws_lambda_function" "RawDataMapping" {
  filename                       = "lambda/RawDataMapping.zip"
  function_name                  = "RawDataMapping" 
  handler                        = "projectRawDataSheetScheduledMapping::projectRawDataSheetScheduledMapping.Function::FunctionHandler"
  package_type                   = "Zip"
  source_code_hash               = filebase64sha256("lambda/RawDataMapping.zip")
  runtime                        = "dotnetcore3.1"
  memory_size                    = "128"
  role                           = aws_iam_role.lambda_role.arn
  reserved_concurrent_executions = "-1"
  timeout                        = "10"
  architectures                  = ["x86_64"]

  environment {
    variables = {
      AWS__S3Bucket = "project-mod-prod-bucket",
      S3ObjectKey__RawDataSheetMappingTable = "config/MappingTable.csv"
    }
  }
  tracing_config {
    mode = "PassThrough"
  }
}

resource "aws_lambda_permission" "allow_bucke_update" {
  statement_id  = "AllowExecutionFromS3Bucket"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.update_mappingtable.arn
  principal     = "s3.amazonaws.com"
  source_arn    = aws_s3_bucket.bucket.arn
}

resource "aws_lambda_permission" "allow_bucket_delete" {
  statement_id  = "AllowExecutionFromS3Bucket"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.delete_mappingtable.arn
  principal     = "s3.amazonaws.com"
  source_arn    = aws_s3_bucket.bucket.arn
}

resource "aws_lambda_permission" "CommercialVariable" {
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.CommercialVariable.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.CommercialVariable.arn
}
resource "aws_lambda_permission" "RawDataCompression" {
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.RawDataCompression.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.RawDataCompression.arn
}
resource "aws_lambda_permission" "RawDataMapping" {
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.RawDataMapping.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.RawDataMapping.arn
}

resource "aws_s3_bucket" "bucket" {
  bucket = var.project_bucket
}

resource "aws_s3_bucket_acl" "bucket" {
  bucket = aws_s3_bucket.bucket.id
  acl    = "private" 
}

resource "aws_s3_bucket_cors_configuration" "bucket" {
  bucket = aws_s3_bucket.bucket.bucket

  cors_rule {
    allowed_headers = ["*"]
    allowed_methods = ["GET","PUT","POST","DELETE"]
    allowed_origins = ["*"]
    expose_headers  = []
    max_age_seconds = 3000
  }
}

resource "aws_s3_bucket_notification" "bucket_notification" {
  bucket = aws_s3_bucket.bucket.id

  lambda_function {
    lambda_function_arn = aws_lambda_function.update_mappingtable.arn
    events              = ["s3:ObjectCreated:*"]
  }

  lambda_function {
    lambda_function_arn = aws_lambda_function.delete_mappingtable.arn
    events              = ["s3:ObjectRemoved:*"]
  }
}

resource "aws_cloudwatch_event_rule" "CommercialVariable" {
  name                = "CommercialVariable"
  schedule_expression = "rate(1 hour)"
}

resource "aws_cloudwatch_event_rule" "RawDataCompression" {
  name                = "RawDataCompression"
  schedule_expression = "rate(1 hour)"
}

resource "aws_cloudwatch_event_rule" "RawDataMapping" {
  name                = "RawDataMapping"
  schedule_expression = "rate(1 hour)"
}

resource "aws_cloudwatch_event_target" "CommercialVariable" {
  target_id = "CommercialVariable"
  arn  = aws_lambda_function.CommercialVariable.arn
  rule = aws_cloudwatch_event_rule.CommercialVariable.id
}

resource "aws_cloudwatch_event_target" "RawDataCompression" {
  target_id = "RawDataCompression"
  arn  = aws_lambda_function.RawDataCompression.arn
  rule = aws_cloudwatch_event_rule.RawDataCompression.id
}

resource "aws_cloudwatch_event_target" "RawDataMapping" {
  target_id = "RawDataMapping"
  arn  = aws_lambda_function.RawDataMapping.arn
  rule = aws_cloudwatch_event_rule.RawDataMapping.id
}