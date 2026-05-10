locals {
  common_tags = {
    Project     = var.project
    Environment = var.environment
    ManagedBy   = "Terraform"
  }

  lambda_definitions = {
    get_all_authors = {
      function_name = "get-all-authors"
      source_dir    = "../../lambdas/get-all-authors"
      handler       = "index.handler"
      runtime       = "nodejs20.x"
      actions       = ["dynamodb:Scan"]
      resource_arns = [data.terraform_remote_state.data_stack.outputs.authors_table_arn]
      env = {
        AUTHORS_TABLE_NAME = data.terraform_remote_state.data_stack.outputs.authors_table_name
      }
    }
    get_all_courses = {
      function_name = "get-all-courses"
      source_dir    = "../../lambdas/get-all-courses"
      handler       = "index.handler"
      runtime       = "nodejs20.x"
      actions       = ["dynamodb:Scan"]
      resource_arns = [data.terraform_remote_state.data_stack.outputs.courses_table_arn]
      env = {
        COURSES_TABLE_NAME = data.terraform_remote_state.data_stack.outputs.courses_table_name
      }
    }
    get_course = {
      function_name = "get-course"
      source_dir    = "../../lambdas/get-course"
      handler       = "index.handler"
      runtime       = "nodejs20.x"
      actions       = ["dynamodb:GetItem"]
      resource_arns = [data.terraform_remote_state.data_stack.outputs.courses_table_arn]
      env = {
        COURSES_TABLE_NAME = data.terraform_remote_state.data_stack.outputs.courses_table_name
      }
    }
    save_course = {
      function_name = "save-course"
      source_dir    = "../../lambdas/save-course"
      handler       = "index.handler"
      runtime       = "nodejs20.x"
      actions       = ["dynamodb:PutItem"]
      resource_arns = [data.terraform_remote_state.data_stack.outputs.courses_table_arn]
      env = {
        COURSES_TABLE_NAME = data.terraform_remote_state.data_stack.outputs.courses_table_name
      }
    }
    update_course = {
      function_name = "update-course"
      source_dir    = "../../lambdas/update-course"
      handler       = "index.handler"
      runtime       = "nodejs20.x"
      actions       = ["dynamodb:PutItem"]
      resource_arns = [data.terraform_remote_state.data_stack.outputs.courses_table_arn]
      env = {
        COURSES_TABLE_NAME = data.terraform_remote_state.data_stack.outputs.courses_table_name
      }
    }
    delete_course = {
      function_name = "delete-course"
      source_dir    = "../../lambdas/delete-course"
      handler       = "index.handler"
      runtime       = "nodejs20.x"
      actions       = ["dynamodb:DeleteItem"]
      resource_arns = [data.terraform_remote_state.data_stack.outputs.courses_table_arn]
      env = {
        COURSES_TABLE_NAME = data.terraform_remote_state.data_stack.outputs.courses_table_name
      }
    }
  }
}

module "api_label" {
  source  = "cloudposse/label/null"
  version = "0.25.0"

  name        = "courses-api"
  label_order = ["name"]
}

module "frontend_bucket_label" {
  source  = "cloudposse/label/null"
  version = "0.25.0"

  namespace   = var.project
  stage       = var.environment
  name        = "frontend"
  label_order = ["namespace", "stage", "name"]
}

module "cloudfront_label" {
  source  = "cloudposse/label/null"
  version = "0.25.0"

  name        = "courses-cdn"
  label_order = ["name"]
}

data "archive_file" "lambda_zip" {
  for_each = local.lambda_definitions

  type        = "zip"
  source_dir  = each.value.source_dir
  output_path = "${path.module}/build/${each.value.function_name}.zip"
}

resource "aws_iam_role" "lambda_role" {
  for_each = local.lambda_definitions

  name = "${each.value.function_name}-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = local.common_tags
}

resource "aws_iam_role_policy" "lambda_policy" {
  for_each = local.lambda_definitions

  name = "${each.value.function_name}-policy"
  role = aws_iam_role.lambda_role[each.key].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "cloudwatch:PutMetricData"
        ]
        Resource = "arn:aws:logs:*:*:*"
      },
      {
        Effect   = "Allow"
        Action   = each.value.actions
        Resource = each.value.resource_arns
      }
    ]
  })
}

resource "aws_lambda_function" "this" {
  for_each = local.lambda_definitions

  function_name    = each.value.function_name
  role             = aws_iam_role.lambda_role[each.key].arn
  handler          = each.value.handler
  runtime          = each.value.runtime
  filename         = data.archive_file.lambda_zip[each.key].output_path
  source_code_hash = data.archive_file.lambda_zip[each.key].output_base64sha256
  timeout          = 10

  environment {
    variables = each.value.env
  }

  tags = local.common_tags
}

resource "aws_api_gateway_rest_api" "this" {
  name = module.api_label.id

  endpoint_configuration {
    types = ["REGIONAL"]
  }

  tags = local.common_tags
}

resource "aws_api_gateway_resource" "authors" {
  rest_api_id = aws_api_gateway_rest_api.this.id
  parent_id   = aws_api_gateway_rest_api.this.root_resource_id
  path_part   = "authors"
}

resource "aws_api_gateway_resource" "courses" {
  rest_api_id = aws_api_gateway_rest_api.this.id
  parent_id   = aws_api_gateway_rest_api.this.root_resource_id
  path_part   = "courses"
}

resource "aws_api_gateway_resource" "course_id" {
  rest_api_id = aws_api_gateway_rest_api.this.id
  parent_id   = aws_api_gateway_resource.courses.id
  path_part   = "{id}"
}


resource "aws_api_gateway_method" "authors_get" {
  rest_api_id   = aws_api_gateway_rest_api.this.id
  resource_id   = aws_api_gateway_resource.authors.id
  http_method   = "GET"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "authors_get" {
  rest_api_id             = aws_api_gateway_rest_api.this.id
  resource_id             = aws_api_gateway_resource.authors.id
  http_method             = aws_api_gateway_method.authors_get.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.this["get_all_authors"].invoke_arn
}

resource "aws_api_gateway_method" "courses_get_all" {
  rest_api_id   = aws_api_gateway_rest_api.this.id
  resource_id   = aws_api_gateway_resource.courses.id
  http_method   = "GET"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "courses_get_all" {
  rest_api_id             = aws_api_gateway_rest_api.this.id
  resource_id             = aws_api_gateway_resource.courses.id
  http_method             = aws_api_gateway_method.courses_get_all.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.this["get_all_courses"].invoke_arn
}

resource "aws_api_gateway_method" "courses_post" {
  rest_api_id   = aws_api_gateway_rest_api.this.id
  resource_id   = aws_api_gateway_resource.courses.id
  http_method   = "POST"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "courses_post" {
  rest_api_id             = aws_api_gateway_rest_api.this.id
  resource_id             = aws_api_gateway_resource.courses.id
  http_method             = aws_api_gateway_method.courses_post.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.this["save_course"].invoke_arn
}

resource "aws_api_gateway_method" "course_get" {
  rest_api_id   = aws_api_gateway_rest_api.this.id
  resource_id   = aws_api_gateway_resource.course_id.id
  http_method   = "GET"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "course_get" {
  rest_api_id             = aws_api_gateway_rest_api.this.id
  resource_id             = aws_api_gateway_resource.course_id.id
  http_method             = aws_api_gateway_method.course_get.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.this["get_course"].invoke_arn
}

resource "aws_api_gateway_method" "course_put" {
  rest_api_id   = aws_api_gateway_rest_api.this.id
  resource_id   = aws_api_gateway_resource.course_id.id
  http_method   = "PUT"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "course_put" {
  rest_api_id             = aws_api_gateway_rest_api.this.id
  resource_id             = aws_api_gateway_resource.course_id.id
  http_method             = aws_api_gateway_method.course_put.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.this["update_course"].invoke_arn
}

resource "aws_api_gateway_method" "course_delete" {
  rest_api_id   = aws_api_gateway_rest_api.this.id
  resource_id   = aws_api_gateway_resource.course_id.id
  http_method   = "DELETE"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "course_delete" {
  rest_api_id             = aws_api_gateway_rest_api.this.id
  resource_id             = aws_api_gateway_resource.course_id.id
  http_method             = aws_api_gateway_method.course_delete.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.this["delete_course"].invoke_arn
}

resource "aws_lambda_permission" "allow_api_gateway" {
  for_each = local.lambda_definitions

  statement_id  = "AllowExecutionFromAPIGateway-${each.value.function_name}"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.this[each.key].function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.this.execution_arn}/*/*"
}

resource "aws_api_gateway_method" "authors_options" {
  rest_api_id   = aws_api_gateway_rest_api.this.id
  resource_id   = aws_api_gateway_resource.authors.id
  http_method   = "OPTIONS"
  authorization = "NONE"
}

resource "aws_api_gateway_method_response" "authors_options" {
  rest_api_id = aws_api_gateway_rest_api.this.id
  resource_id = aws_api_gateway_resource.authors.id
  http_method = aws_api_gateway_method.authors_options.http_method
  status_code = "200"

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = true
    "method.response.header.Access-Control-Allow-Methods" = true
    "method.response.header.Access-Control-Allow-Origin"  = true
  }
}

resource "aws_api_gateway_integration" "authors_options" {
  rest_api_id = aws_api_gateway_rest_api.this.id
  resource_id = aws_api_gateway_resource.authors.id
  http_method = aws_api_gateway_method.authors_options.http_method
  type        = "MOCK"

  request_templates = {
    "application/json" = "{\"statusCode\": 200}"
  }
}

resource "aws_api_gateway_integration_response" "authors_options" {
  rest_api_id = aws_api_gateway_rest_api.this.id
  resource_id = aws_api_gateway_resource.authors.id
  http_method = aws_api_gateway_method.authors_options.http_method
  status_code = aws_api_gateway_method_response.authors_options.status_code

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = "'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token'"
    "method.response.header.Access-Control-Allow-Methods" = "'GET,OPTIONS'"
    "method.response.header.Access-Control-Allow-Origin"  = "'*'"
  }
}

resource "aws_api_gateway_method" "courses_options" {
  rest_api_id   = aws_api_gateway_rest_api.this.id
  resource_id   = aws_api_gateway_resource.courses.id
  http_method   = "OPTIONS"
  authorization = "NONE"
}

resource "aws_api_gateway_method_response" "courses_options" {
  rest_api_id = aws_api_gateway_rest_api.this.id
  resource_id = aws_api_gateway_resource.courses.id
  http_method = aws_api_gateway_method.courses_options.http_method
  status_code = "200"

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = true
    "method.response.header.Access-Control-Allow-Methods" = true
    "method.response.header.Access-Control-Allow-Origin"  = true
  }
}

resource "aws_api_gateway_integration" "courses_options" {
  rest_api_id = aws_api_gateway_rest_api.this.id
  resource_id = aws_api_gateway_resource.courses.id
  http_method = aws_api_gateway_method.courses_options.http_method
  type        = "MOCK"

  request_templates = {
    "application/json" = "{\"statusCode\": 200}"
  }
}

resource "aws_api_gateway_integration_response" "courses_options" {
  rest_api_id = aws_api_gateway_rest_api.this.id
  resource_id = aws_api_gateway_resource.courses.id
  http_method = aws_api_gateway_method.courses_options.http_method
  status_code = aws_api_gateway_method_response.courses_options.status_code

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = "'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token'"
    "method.response.header.Access-Control-Allow-Methods" = "'GET,POST,OPTIONS'"
    "method.response.header.Access-Control-Allow-Origin"  = "'*'"
  }
}

resource "aws_api_gateway_method" "course_id_options" {
  rest_api_id   = aws_api_gateway_rest_api.this.id
  resource_id   = aws_api_gateway_resource.course_id.id
  http_method   = "OPTIONS"
  authorization = "NONE"
}

resource "aws_api_gateway_method_response" "course_id_options" {
  rest_api_id = aws_api_gateway_rest_api.this.id
  resource_id = aws_api_gateway_resource.course_id.id
  http_method = aws_api_gateway_method.course_id_options.http_method
  status_code = "200"

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = true
    "method.response.header.Access-Control-Allow-Methods" = true
    "method.response.header.Access-Control-Allow-Origin"  = true
  }
}

resource "aws_api_gateway_integration" "course_id_options" {
  rest_api_id = aws_api_gateway_rest_api.this.id
  resource_id = aws_api_gateway_resource.course_id.id
  http_method = aws_api_gateway_method.course_id_options.http_method
  type        = "MOCK"

  request_templates = {
    "application/json" = "{\"statusCode\": 200}"
  }
}

resource "aws_api_gateway_integration_response" "course_id_options" {
  rest_api_id = aws_api_gateway_rest_api.this.id
  resource_id = aws_api_gateway_resource.course_id.id
  http_method = aws_api_gateway_method.course_id_options.http_method
  status_code = aws_api_gateway_method_response.course_id_options.status_code

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = "'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token'"
    "method.response.header.Access-Control-Allow-Methods" = "'GET,PUT,DELETE,OPTIONS'"
    "method.response.header.Access-Control-Allow-Origin"  = "'*'"
  }
}

resource "aws_api_gateway_deployment" "this" {
  rest_api_id = aws_api_gateway_rest_api.this.id

  depends_on = [
    aws_api_gateway_integration.authors_get,
    aws_api_gateway_integration.courses_get_all,
    aws_api_gateway_integration.courses_post,
    aws_api_gateway_integration.course_get,
    aws_api_gateway_integration.course_put,
    aws_api_gateway_integration.course_delete,
    aws_api_gateway_integration_response.authors_options,
    aws_api_gateway_integration_response.courses_options,
    aws_api_gateway_integration_response.course_id_options,
  ]

  triggers = {
    redeployment = sha1(jsonencode([
      aws_api_gateway_resource.authors.id,
      aws_api_gateway_resource.courses.id,
      aws_api_gateway_resource.course_id.id,
      aws_api_gateway_method.authors_get.id,
      aws_api_gateway_method.courses_get_all.id,
      aws_api_gateway_method.courses_post.id,
      aws_api_gateway_method.course_get.id,
      aws_api_gateway_method.course_put.id,
      aws_api_gateway_method.course_delete.id,
    ]))
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_api_gateway_stage" "dev" {
  rest_api_id   = aws_api_gateway_rest_api.this.id
  deployment_id = aws_api_gateway_deployment.this.id
  stage_name    = var.environment

  tags = local.common_tags
}

resource "aws_s3_bucket" "frontend" {
  bucket = module.frontend_bucket_label.id

  tags = local.common_tags
}

resource "aws_s3_bucket_public_access_block" "frontend" {
  bucket = aws_s3_bucket.frontend.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

resource "aws_s3_bucket_website_configuration" "frontend" {
  bucket = aws_s3_bucket.frontend.id

  index_document {
    suffix = "index.html"
  }
}

resource "aws_s3_bucket_policy" "frontend_public_read" {
  bucket = aws_s3_bucket.frontend.id

  depends_on = [aws_s3_bucket_public_access_block.frontend]

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "PublicReadGetObject"
        Effect    = "Allow"
        Principal = "*"
        Action    = ["s3:GetObject"]
        Resource  = "${aws_s3_bucket.frontend.arn}/*"
      }
    ]
  })
}

locals {
  frontend_build_dir = "${path.module}/../../frontend/build"
  frontend_files     = fileset(local.frontend_build_dir, "**/*")
}

resource "aws_s3_object" "frontend_files" {
  for_each = local.frontend_files

  bucket = aws_s3_bucket.frontend.id
  key    = each.value
  source = "${local.frontend_build_dir}/${each.value}"
  etag   = filemd5("${local.frontend_build_dir}/${each.value}")
}

resource "aws_cloudfront_distribution" "frontend" {
  enabled             = true
  default_root_object = "index.html"
  price_class         = "PriceClass_100"

  origin {
    domain_name = aws_s3_bucket_website_configuration.frontend.website_endpoint
    origin_id   = module.cloudfront_label.id

    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = "http-only"
      origin_ssl_protocols   = ["TLSv1.2"]
    }
  }

  default_cache_behavior {
    allowed_methods  = ["GET", "HEAD"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = module.cloudfront_label.id

    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }

    viewer_protocol_policy = "redirect-to-https"
    min_ttl                = 0
    default_ttl            = 3600
    max_ttl                = 86400
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }

  tags = local.common_tags
}

output "api_invoke_url" {
  value = "https://${aws_api_gateway_rest_api.this.id}.execute-api.${var.aws_region}.amazonaws.com/${aws_api_gateway_stage.dev.stage_name}"
}