
resource "aws_api_gateway_rest_api" "this" {
    name = "corses-api"
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
resource "aws_api_gateway_deployment" "this" {
  depends_on = [
    aws_api_gateway_integration.authors_get,
    aws_api_gateway_integration.courses_get,
    aws_api_gateway_integration.courses_post,
    aws_api_gateway_integration.course_get,
    aws_api_gateway_integration.course_put,
    aws_api_gateway_integration.course_delete,
    aws_api_gateway_integration.courses_options
  ]
    rest_api_id = aws_api_gateway_rest_api.this.id
 
}