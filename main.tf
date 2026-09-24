data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

data "archive_file" "api" {
  type        = "zip"
  source_dir  = "${path.module}/lambda/api"
  output_path = "${path.module}/build/api.zip"
}
data "archive_file" "s3" {
  type        = "zip"
  source_dir  = "${path.module}/lambda/s3"
  output_path = "${path.module}/build/s3.zip"
}
data "archive_file" "sqs" {
  type        = "zip"
  source_dir  = "${path.module}/lambda/sqs"
  output_path = "${path.module}/build/sqs.zip"
}
data "archive_file" "layer" {
  type        = "zip"
  source_dir  = "${path.module}/layer"
  output_path = "${path.module}/build/layer.zip"
}
data "archive_file" "custom_runtime" {
  type        = "zip"
  source_dir  = "${path.module}/custom_runtime"
  output_path = "${path.module}/build/custom_runtime.zip"
}

locals {
  project = "serverless-demo"
  name    = "${local.project}-${var.environment}"

  api_root_methods = {
    users_get = {
      resource_id = aws_api_gateway_resource.users.id
      http_method = "GET"
    }
    users_post = {
      resource_id = aws_api_gateway_resource.users.id
      http_method = "POST"
    }
    products_get = {
      resource_id = aws_api_gateway_resource.products.id
      http_method = "GET"
    }
    products_post = {
      resource_id = aws_api_gateway_resource.products.id
      http_method = "POST"
    }
  }

  api_id_methods = {
    users_id_get = {
      resource_id = aws_api_gateway_resource.users_id.id
      http_method = "GET"
    }
    users_id_put = {
      resource_id = aws_api_gateway_resource.users_id.id
      http_method = "PUT"
    }
    users_id_delete = {
      resource_id = aws_api_gateway_resource.users_id.id
      http_method = "DELETE"
    }
    products_id_get = {
      resource_id = aws_api_gateway_resource.products_id.id
      http_method = "GET"
    }
    products_id_put = {
      resource_id = aws_api_gateway_resource.products_id.id
      http_method = "PUT"
    }
    products_id_delete = {
      resource_id = aws_api_gateway_resource.products_id.id
      http_method = "DELETE"
    }
  }
}

# -----------------------------
# CloudWatch / Lambda IAM
# -----------------------------

resource "aws_iam_role" "lambda_role" {
  name = "${local.name}-lambda-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "lambda.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_basic" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy_attachment" "lambda_insights" {
  count      = var.enable_lambda_insights ? 1 : 0
  role       = aws_iam_role.lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchLambdaInsightsExecutionRolePolicy"
}

resource "aws_iam_role_policy" "lambda_app" {
  name = "${local.name}-lambda-app-policy"
  role = aws_iam_role.lambda_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "dynamodb:GetItem",
          "dynamodb:PutItem",
          "dynamodb:UpdateItem",
          "dynamodb:DeleteItem",
          "dynamodb:Query",
          "dynamodb:Scan"
        ]
        Resource = aws_dynamodb_table.users.arn
      },
      {
        Effect = "Allow"
        Action = [
          "sqs:ReceiveMessage",
          "sqs:DeleteMessage",
          "sqs:GetQueueAttributes",
          "sqs:ChangeMessageVisibility"
        ]
        Resource = aws_sqs_queue.main.arn
      }
    ]
  })
}

# -----------------------------
# Lambda Layer
# -----------------------------

resource "aws_lambda_layer_version" "common" {
  layer_name          = "${local.name}-common"
  filename            = data.archive_file.layer.output_path
  source_code_hash    = data.archive_file.layer.output_base64sha256
  compatible_runtimes = ["python3.12"]
}

# -----------------------------
# DynamoDB
# -----------------------------

resource "aws_dynamodb_table" "users" {
  name         = "${local.name}-users"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "id"

  attribute {
    name = "id"
    type = "S"
  }
}

# -----------------------------
# API Lambda
# -----------------------------

resource "aws_lambda_function" "api" {
  function_name    = "${local.name}-api"
  filename         = data.archive_file.api.output_path
  source_code_hash = data.archive_file.api.output_base64sha256
  role             = aws_iam_role.lambda_role.arn
  handler          = "lambda_function.lambda_handler"
  runtime          = "python3.12"

  memory_size = 512
  timeout     = 30
  publish     = true

  reserved_concurrent_executions = var.api_reserved_concurrency

  layers = compact([
    aws_lambda_layer_version.common.arn,
    var.enable_lambda_insights ? var.lambda_insights_layer_arn : null
  ])

  environment {
    variables = {
      ENVIRONMENT = var.environment
      TABLE_NAME  = aws_dynamodb_table.users.name
      LOG_LEVEL   = "INFO"
    }
  }

  depends_on = [aws_iam_role_policy_attachment.lambda_basic]
}

resource "aws_lambda_alias" "api_live" {
  name             = "live"
  function_name    = aws_lambda_function.api.function_name
  function_version = aws_lambda_function.api.version
}

resource "aws_lambda_provisioned_concurrency_config" "api" {
  count = var.enable_provisioned_concurrency ? 1 : 0

  function_name                     = aws_lambda_function.api.function_name
  qualifier                         = aws_lambda_alias.api_live.name
  provisioned_concurrent_executions = var.api_provisioned_concurrency
}

# -----------------------------
# S3 + S3 Lambda
# -----------------------------

resource "random_id" "bucket" {
  byte_length = 4
}

resource "aws_s3_bucket" "uploads" {
  bucket = "${local.name}-uploads-${random_id.bucket.hex}"
}

resource "aws_s3_bucket_public_access_block" "uploads" {
  bucket                  = aws_s3_bucket.uploads.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_lambda_function" "s3" {
  function_name    = "${local.name}-s3"
  filename         = data.archive_file.s3.output_path
  source_code_hash = data.archive_file.s3.output_base64sha256
  role             = aws_iam_role.lambda_role.arn
  handler          = "lambda_function.lambda_handler"
  runtime          = "python3.12"

  memory_size = 256
  timeout     = 30
  layers      = [aws_lambda_layer_version.common.arn]

  environment {
    variables = {
      ENVIRONMENT = var.environment
      LOG_LEVEL   = "INFO"
    }
  }

  depends_on = [aws_iam_role_policy_attachment.lambda_basic]
}

resource "aws_lambda_permission" "s3" {
  statement_id  = "AllowS3Invoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.s3.function_name
  principal     = "s3.amazonaws.com"
  source_arn    = aws_s3_bucket.uploads.arn
}

resource "aws_s3_bucket_notification" "uploads" {
  bucket = aws_s3_bucket.uploads.id

  lambda_function {
    lambda_function_arn = aws_lambda_function.s3.arn
    events              = ["s3:ObjectCreated:*"]
  }

  depends_on = [aws_lambda_permission.s3]
}

# -----------------------------
# SQS + SQS Lambda
# -----------------------------

resource "aws_sqs_queue" "main" {
  name                       = "${local.name}-queue"
  visibility_timeout_seconds = 60
  message_retention_seconds  = 86400
}

resource "aws_lambda_function" "sqs" {
  function_name    = "${local.name}-sqs"
  filename         = data.archive_file.sqs.output_path
  source_code_hash = data.archive_file.sqs.output_base64sha256
  role             = aws_iam_role.lambda_role.arn
  handler          = "lambda_function.lambda_handler"
  runtime          = "python3.12"

  memory_size = 256
  timeout     = 30
  layers      = [aws_lambda_layer_version.common.arn]

  environment {
    variables = {
      ENVIRONMENT = var.environment
      LOG_LEVEL   = "INFO"
    }
  }

  depends_on = [aws_iam_role_policy_attachment.lambda_basic]
}

resource "aws_lambda_event_source_mapping" "sqs" {
  event_source_arn = aws_sqs_queue.main.arn
  function_name    = aws_lambda_function.sqs.arn
  batch_size       = 10
  enabled          = true
}

# -----------------------------
# EventBridge + Scheduled Lambda
# -----------------------------

resource "aws_cloudwatch_event_rule" "schedule" {
  name                = "${local.name}-schedule"
  description         = "Run scheduled Lambda task every 5 minutes"
  schedule_expression = "rate(5 minutes)"
}

resource "aws_lambda_function" "scheduled" {
  function_name    = "${local.name}-scheduled"
  filename         = data.archive_file.custom_runtime.output_path
  source_code_hash = data.archive_file.custom_runtime.output_base64sha256
  role             = aws_iam_role.lambda_role.arn
  handler          = "bootstrap"
  runtime          = "provided.al2023"
  architectures    = ["x86_64"]

  memory_size = 256
  timeout     = 30

  environment {
    variables = {
      ENVIRONMENT = var.environment
      LOG_LEVEL   = "INFO"
    }
  }

  depends_on = [aws_iam_role_policy_attachment.lambda_basic]
}

resource "aws_cloudwatch_event_target" "scheduled" {
  rule      = aws_cloudwatch_event_rule.schedule.name
  target_id = "scheduled-lambda"
  arn       = aws_lambda_function.scheduled.arn
}

resource "aws_lambda_permission" "eventbridge" {
  statement_id  = "AllowEventBridgeInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.scheduled.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.schedule.arn
}

# -----------------------------
# API Gateway REST API
# -----------------------------

resource "aws_api_gateway_rest_api" "api" {
  name = "${local.name}-rest-api"

  endpoint_configuration {
    types = ["REGIONAL"]
  }

  binary_media_types = []
}

resource "aws_api_gateway_resource" "users" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  parent_id   = aws_api_gateway_rest_api.api.root_resource_id
  path_part   = "users"
}

resource "aws_api_gateway_resource" "users_id" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  parent_id   = aws_api_gateway_resource.users.id
  path_part   = "{id}"
}

resource "aws_api_gateway_resource" "products" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  parent_id   = aws_api_gateway_rest_api.api.root_resource_id
  path_part   = "products"
}

resource "aws_api_gateway_resource" "products_id" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  parent_id   = aws_api_gateway_resource.products.id
  path_part   = "{id}"
}

# Request validator and models
resource "aws_api_gateway_request_validator" "body_and_params" {
  name                        = "${local.name}-validator"
  rest_api_id                 = aws_api_gateway_rest_api.api.id
  validate_request_body       = true
  validate_request_parameters = true
}

resource "aws_api_gateway_model" "create_user" {
  rest_api_id  = aws_api_gateway_rest_api.api.id
  name         = "CreateUserRequest"
  description  = "Request body for creating a user"
  content_type = "application/json"

  schema = jsonencode({
    "$schema" = "http://json-schema.org/draft-04/schema#"
    title     = "CreateUserRequest"
    type      = "object"
    required  = ["name", "email"]

    properties = {
      name = {
        type      = "string"
        minLength = 2
      }
      email = {
        type   = "string"
        format = "email"
      }
    }

    additionalProperties = false
  })
}

resource "aws_api_gateway_model" "create_product" {
  rest_api_id  = aws_api_gateway_rest_api.api.id
  name         = "CreateProductRequest"
  description  = "Request body for creating a product"
  content_type = "application/json"

  schema = jsonencode({
    "$schema" = "http://json-schema.org/draft-04/schema#"
    title     = "CreateProductRequest"
    type      = "object"
    required  = ["name", "price"]

    properties = {
      name = {
        type      = "string"
        minLength = 2
      }
      price = {
        type    = "number"
        minimum = 0
      }
    }

    additionalProperties = false
  })
}

# Methods - collection resources
resource "aws_api_gateway_method" "root_methods" {
  for_each = local.api_root_methods

  rest_api_id = aws_api_gateway_rest_api.api.id
  resource_id = each.value.resource_id
  http_method = each.value.http_method

  authorization    = "NONE"
  api_key_required = true

  request_validator_id = (
    each.value.http_method == "POST"
    ? aws_api_gateway_request_validator.body_and_params.id
    : each.value.resource_id == aws_api_gateway_resource.users.id
    ? aws_api_gateway_request_validator.body_and_params.id
    : null
  )

  request_models = (
    each.value.http_method == "POST"
    ? { "application/json" = each.value.resource_id == aws_api_gateway_resource.users.id ? aws_api_gateway_model.create_user.name : aws_api_gateway_model.create_product.name }
    : {}
  )

  request_parameters = (
    each.value.resource_id == aws_api_gateway_resource.users.id && each.value.http_method == "GET"
    ? { "method.request.querystring.limit" = true }
    : {}
  )
}

# Methods - ID resources
resource "aws_api_gateway_method" "id_methods" {
  for_each = local.api_id_methods

  rest_api_id = aws_api_gateway_rest_api.api.id
  resource_id = each.value.resource_id
  http_method = each.value.http_method

  authorization    = "NONE"
  api_key_required = true

  request_parameters = {
    "method.request.path.id" = true
  }
}

# Integrations
resource "aws_api_gateway_integration" "root_methods" {
  for_each = local.api_root_methods

  rest_api_id = aws_api_gateway_rest_api.api.id
  resource_id = each.value.resource_id
  http_method = each.value.http_method

  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_alias.api_live.invoke_arn
}

resource "aws_api_gateway_integration" "id_methods" {
  for_each = local.api_id_methods

  rest_api_id = aws_api_gateway_rest_api.api.id
  resource_id = each.value.resource_id
  http_method = each.value.http_method

  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_alias.api_live.invoke_arn
}

# CORS - OPTIONS for both collections and ID resources
locals {
  cors_resources = {
    users       = aws_api_gateway_resource.users.id
    users_id    = aws_api_gateway_resource.users_id.id
    products    = aws_api_gateway_resource.products.id
    products_id = aws_api_gateway_resource.products_id.id
  }
}

resource "aws_api_gateway_method" "cors_options" {
  for_each = local.cors_resources

  rest_api_id   = aws_api_gateway_rest_api.api.id
  resource_id   = each.value
  http_method   = "OPTIONS"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "cors_options" {
  for_each = local.cors_resources

  rest_api_id = aws_api_gateway_rest_api.api.id
  resource_id = each.value
  http_method = "OPTIONS"

  type = "MOCK"

  request_templates = {
    "application/json" = "{\"statusCode\": 200}"
  }
}

resource "aws_api_gateway_method_response" "cors_options" {
  for_each = local.cors_resources

  rest_api_id = aws_api_gateway_rest_api.api.id
  resource_id = each.value
  http_method = "OPTIONS"
  status_code = "200"

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = true
    "method.response.header.Access-Control-Allow-Methods" = true
    "method.response.header.Access-Control-Allow-Origin"  = true
  }
}

resource "aws_api_gateway_integration_response" "cors_options" {
  for_each = local.cors_resources

  rest_api_id = aws_api_gateway_rest_api.api.id
  resource_id = each.value
  http_method = "OPTIONS"
  status_code = "200"

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = "'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Correlation-ID'"
    "method.response.header.Access-Control-Allow-Methods" = "'GET,POST,PUT,DELETE,OPTIONS'"
    "method.response.header.Access-Control-Allow-Origin"  = "'*'"
  }

  depends_on = [aws_api_gateway_integration.cors_options]
}

# Lambda permission
resource "aws_lambda_permission" "api_gateway" {
  statement_id_prefix = "AllowAPIGateway"
  action              = "lambda:InvokeFunction"
  function_name       = aws_lambda_function.api.function_name
  principal           = "apigateway.amazonaws.com"
  qualifier           = aws_lambda_alias.api_live.name
  source_arn          = "${aws_api_gateway_rest_api.api.execution_arn}/*/*"
}

# Gateway responses
resource "aws_api_gateway_gateway_response" "default_4xx" {
  rest_api_id   = aws_api_gateway_rest_api.api.id
  response_type = "DEFAULT_4XX"
  status_code   = "400"

  response_templates = {
    "application/json" = jsonencode({
      success = false
      error = {
        code    = "BAD_REQUEST"
        message = "$context.error.message"
      }
      correlation_id = "$context.requestId"
    })
  }

  response_parameters = {
    "gatewayresponse.header.Access-Control-Allow-Origin"  = "'*'"
    "gatewayresponse.header.Access-Control-Allow-Headers" = "'Content-Type,X-Api-Key,X-Correlation-ID'"
  }
}

resource "aws_api_gateway_gateway_response" "resource_not_found" {
  rest_api_id   = aws_api_gateway_rest_api.api.id
  response_type = "RESOURCE_NOT_FOUND"
  status_code   = "404"

  response_templates = {
    "application/json" = jsonencode({
      success = false
      error = {
        code    = "NOT_FOUND"
        message = "$context.error.message"
      }
      correlation_id = "$context.requestId"
    })
  }

  response_parameters = {
    "gatewayresponse.header.Access-Control-Allow-Origin"  = "'*'"
    "gatewayresponse.header.Access-Control-Allow-Headers" = "'Content-Type,X-Api-Key,X-Correlation-ID'"
  }
}

# API deployment
resource "aws_api_gateway_deployment" "api" {
  rest_api_id = aws_api_gateway_rest_api.api.id

  depends_on = [
    aws_api_gateway_integration.root_methods,
    aws_api_gateway_integration.id_methods,
    aws_api_gateway_integration.cors_options,
    aws_api_gateway_integration_response.cors_options,
    aws_api_gateway_gateway_response.default_4xx,
    aws_api_gateway_gateway_response.resource_not_found
  ]

  triggers = {
    redeployment = sha1(jsonencode([
      aws_api_gateway_rest_api.api.id,
      aws_api_gateway_resource.users.id,
      aws_api_gateway_resource.users_id.id,
      aws_api_gateway_resource.products.id,
      aws_api_gateway_resource.products_id.id,
      aws_api_gateway_model.create_user.id,
      aws_api_gateway_model.create_product.id
    ]))
  }

  lifecycle {
    create_before_destroy = true
  }
}

# API Gateway CloudWatch role
resource "aws_iam_role" "apigw_cloudwatch" {
  name = "${local.name}-apigw-cloudwatch-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "apigateway.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "apigw_logs" {
  role       = aws_iam_role.apigw_cloudwatch.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonAPIGatewayPushToCloudWatchLogs"
}

resource "aws_api_gateway_account" "account" {
  cloudwatch_role_arn = aws_iam_role.apigw_cloudwatch.arn
}

resource "aws_api_gateway_stage" "dev" {
  rest_api_id   = aws_api_gateway_rest_api.api.id
  deployment_id = aws_api_gateway_deployment.api.id
  stage_name    = var.environment

  xray_tracing_enabled = true

  access_log_settings {
    destination_arn = aws_cloudwatch_log_group.apigw_access.arn

    format = jsonencode({
      requestId      = "$context.requestId"
      extendedId     = "$context.extendedRequestId"
      ip             = "$context.identity.sourceIp"
      caller         = "$context.identity.caller"
      user           = "$context.identity.user"
      requestTime    = "$context.requestTime"
      httpMethod     = "$context.httpMethod"
      resourcePath   = "$context.resourcePath"
      status         = "$context.status"
      protocol       = "$context.protocol"
      responseLength = "$context.responseLength"
      apiKeyId       = "$context.identity.apiKeyId"
    })
  }

  depends_on = [
    aws_api_gateway_account.account,
    aws_cloudwatch_log_group.apigw_access
  ]
}

resource "aws_api_gateway_method_settings" "dev" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  stage_name  = aws_api_gateway_stage.dev.stage_name
  method_path = "*/*"

  settings {
    logging_level          = "INFO"
    metrics_enabled        = true
    data_trace_enabled     = false
    throttling_rate_limit  = 10
    throttling_burst_limit = 20
  }
}

resource "aws_cloudwatch_log_group" "apigw_access" {
  name              = "/aws/apigateway/${local.name}"
  retention_in_days = 14
}

# API key + usage plan
resource "aws_api_gateway_api_key" "client" {
  name    = "${local.name}-client-key"
  enabled = true
}

resource "aws_api_gateway_usage_plan" "basic" {
  name        = "${local.name}-basic-plan"
  description = "Basic API usage plan - approximately 100 requests/minute average"

  # API Gateway REST API uses rate/burst throttling rather than a native
  # per-minute quota. 1.6667 req/sec ~= 100 req/min average.
  throttle_settings {
    rate_limit  = 1.6667
    burst_limit = 5
  }

  quota_settings {
    limit  = 3000
    period = "MONTH"
  }

  api_stages {
    api_id = aws_api_gateway_rest_api.api.id
    stage  = aws_api_gateway_stage.dev.stage_name
  }
}

resource "aws_api_gateway_usage_plan_key" "client" {
  key_id        = aws_api_gateway_api_key.client.id
  key_type      = "API_KEY"
  usage_plan_id = aws_api_gateway_usage_plan.basic.id
}

# -----------------------------
# Custom CloudWatch metrics
# -----------------------------

resource "aws_cloudwatch_log_group" "api" {
  name              = "/aws/lambda/${aws_lambda_function.api.function_name}"
  retention_in_days = 14
}

resource "aws_cloudwatch_log_group" "s3" {
  name              = "/aws/lambda/${aws_lambda_function.s3.function_name}"
  retention_in_days = 14
}

resource "aws_cloudwatch_log_group" "sqs" {
  name              = "/aws/lambda/${aws_lambda_function.sqs.function_name}"
  retention_in_days = 14
}

resource "aws_cloudwatch_log_group" "scheduled" {
  name              = "/aws/lambda/${aws_lambda_function.scheduled.function_name}"
  retention_in_days = 14
}

resource "aws_cloudwatch_log_metric_filter" "api_duration" {
  name           = "${local.name}-api-duration"
  log_group_name = aws_cloudwatch_log_group.api.name
  pattern        = "{ $.event = \"request_completed\" }"

  metric_transformation {
    name      = "RequestDurationMs"
    namespace = "ServerlessApp"
    value     = "$.duration_ms"
    unit      = "Milliseconds"
  }
}

resource "aws_cloudwatch_log_metric_filter" "api_memory" {
  name           = "${local.name}-api-memory"
  log_group_name = aws_cloudwatch_log_group.api.name
  pattern        = "{ $.event = \"request_completed\" }"

  metric_transformation {
    name      = "MemoryUsedMB"
    namespace = "ServerlessApp"
    value     = "$.memory_used_mb"
    unit      = "Megabytes"
  }
}

resource "aws_cloudwatch_log_metric_filter" "api_requests" {
  name           = "${local.name}-api-requests"
  log_group_name = aws_cloudwatch_log_group.api.name
  pattern        = "{ $.event = \"request_received\" }"

  metric_transformation {
    name      = "RequestCount"
    namespace = "ServerlessApp"
    value     = "1"
    unit      = "Count"
  }
}