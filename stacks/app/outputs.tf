output "lambda_function_names" {
  value = [for item in values(aws_lambda_function.this) : item.function_name]
}

output "api_base_url" {
  value = "${aws_api_gateway_stage.dev.invoke_url}"
}

output "frontend_bucket_name" {
  value = aws_s3_bucket.frontend.bucket
}

output "frontend_website_endpoint" {
  value = aws_s3_bucket_website_configuration.frontend.website_endpoint
}

output "cloudfront_domain_name" {
  value = aws_cloudfront_distribution.frontend.domain_name
}
