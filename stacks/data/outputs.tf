output "authors_table_name" {
  value = module.authors_table.name
}

output "authors_table_arn" {
  value = module.authors_table.arn
}

output "courses_table_name" {
  value = module.courses_table.name
}

output "courses_table_arn" {
  value = module.courses_table.arn
}

output "aws_region" {
  value = var.aws_region
}
