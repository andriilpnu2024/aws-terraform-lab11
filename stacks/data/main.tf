locals {
  common_tags = {
    Project     = var.project
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}

module "authors_table" {
  source = "../../modules/dynamodb_table"

  aws_region = var.aws_region
  name       = "authors"
  tags       = local.common_tags
}

module "courses_table" {
  source = "../../modules/dynamodb_table"

  aws_region = var.aws_region
  name       = "courses"
  tags       = local.common_tags
}

resource "aws_dynamodb_table_item" "author_cory_house" {
  table_name = module.authors_table.name
  hash_key   = "id"

  item = jsonencode({
    id = { S = "cory-house" }
    firstName = { S = "Cory" }
    lastName = { S = "House" }
  })
}

resource "aws_dynamodb_table_item" "author_samer_buma" {
  table_name = module.authors_table.name
  hash_key   = "id"

  item = jsonencode({
    id = { S = "samer-buma" }
    firstName = { S = "Samer" }
    lastName = { S = "Buma" }
  })
}

resource "aws_dynamodb_table_item" "author_deborah_kurata" {
  table_name = module.authors_table.name
  hash_key   = "id"

  item = jsonencode({
    id = { S = "deborah-kurata" }
    firstName = { S = "Deborah" }
    lastName = { S = "Kurata" }
  })
}

resource "aws_dynamodb_table_item" "course_web_components" {
  table_name = module.courses_table.name
  hash_key   = "id"

  item = jsonencode({
    id = { S = "web-component-fundamentals" }
    title = { S = "Web Component Fundamentals" }
    watchHref = { S = "http://www.pluralsight.com/courses/web-components-shadow-dom" }
    authorId = { S = "cory-house" }
    length = { S = "5:10" }
    category = { S = "HTML5" }
  })
}
