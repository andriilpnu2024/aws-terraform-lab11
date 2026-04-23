resource "aws_lambda_permission" "allow_api_gateway_get_all_authors" {
  statement_id  = "AllowExecutionFromAPIGatewayGetAllAuthors"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.get_all_authors.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.this.execution_arn}/*/*"
}

resource "aws_lambda_permission" "allow_api_gateway_get_all_courses" {
  statement_id  = "AllowExecutionFromAPIGatewayGetAllCourses"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.get_all_courses.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.this.execution_arn}/*/*"
}

resource "aws_lambda_permission" "allow_api_gateway_save_course" {
  statement_id  = "AllowExecutionFromAPIGatewaySaveCourse"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.save_course.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.this.execution_arn}/*/*"
}

resource "aws_lambda_permission" "allow_api_gateway_get_course" {
  statement_id  = "AllowExecutionFromAPIGatewayGetCourse"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.get_course.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.this.execution_arn}/*/*"
}

resource "aws_lambda_permission" "allow_api_gateway_update_course" {
  statement_id  = "AllowExecutionFromAPIGatewayUpdateCourse"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.update_course.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.this.execution_arn}/*/*"
}

resource "aws_lambda_permission" "allow_api_gateway_delete_course" {
  statement_id  = "AllowExecutionFromAPIGatewayDeleteCourse"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.delete_course.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.this.execution_arn}/*/*"
}