resource "aws_sns_topic" "alerts" {
  name = "serverless-alerts"

  tags = local.common_tags
}
resource "aws_sns_topic_subscription" "email_alerts" {
  topic_arn = aws_sns_topic.alerts.arn
  protocol  = "email"
  endpoint  = var.alert_email
}
resource "aws_cloudwatch_metric_alarm" "lambda_errors" {
  for_each = local.lambda_definitions

  alarm_name          = "${each.value.function_name}-errors-alarm"
  alarm_description   = "Alarm when Lambda function has errors"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 1
  metric_name         = "Errors"
  namespace           = "AWS/Lambda"
  period              = 300
  statistic           = "Sum"
  threshold           = 1
  alarm_actions       = [aws_sns_topic.alerts.arn]

  dimensions = {
    FunctionName = aws_lambda_function.this[each.key].function_name
  }

  tags = local.common_tags
}
resource "aws_cloudwatch_metric_alarm" "save_course_duration" {
  alarm_name          = "save-course-duration-alarm"
  alarm_description   = "Alarm when save-course Lambda duration is too high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "Duration"
  namespace           = "AWS/Lambda"
  period              = 300
  statistic           = "Average"
  threshold           = 3000
  alarm_actions       = [aws_sns_topic.alerts.arn]

  dimensions = {
    FunctionName = aws_lambda_function.this["save_course"].function_name
  }

  tags = local.common_tags
}
resource "aws_cloudwatch_metric_alarm" "courses_created_alarm" {
  alarm_name          = "courses-created-alarm"
  alarm_description   = "Alarm when many courses are created"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "CoursesCreated"
  namespace           = "ServerlessApp"
  period              = 300
  statistic           = "Sum"
  threshold           = 10
  alarm_actions       = [aws_sns_topic.alerts.arn]

  tags = local.common_tags
}
resource "aws_sns_topic" "billing_alerts" {
  provider = aws.eu_east_1

  name = "billing-alerts"

}
resource "aws_sns_topic_subscription" "billing_email_alerts" {
  provider = aws.eu_east_1

  topic_arn = aws_sns_topic.billing_alerts.arn
  protocol  = "email"
  endpoint  = var.alert_email
}
resource "aws_cloudwatch_metric_alarm" "billing-alarm" {
  provider = aws.eu_east_1

  alarm_name          = "billing-alarm"
  alarm_description   = "Alarm when estimated charges exceed 5 USD"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "EstimatedCharges"
  namespace           = "AWS/Billing"
  period              = 21600
  statistic           = "Maximum"
  threshold           = 5
  alarm_actions       = [aws_sns_topic.billing_alerts.arn]

  dimensions = {
    Currency = "USD"
  }

}