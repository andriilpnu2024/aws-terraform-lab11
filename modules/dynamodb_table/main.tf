module "label" {
  source  = "cloudposse/label/null"
  version = "0.25.0"

  name        = var.name
  label_order = ["name"]
}

resource "aws_dynamodb_table" "this" {
  name         = module.label.id
  billing_mode = var.billing_mode
  hash_key     = var.hash_key

  attribute {
    name = var.hash_key
    type = var.hash_key_type
  }

  tags = merge(var.tags, module.label.tags)
}
