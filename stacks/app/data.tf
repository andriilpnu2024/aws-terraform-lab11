data "terraform_remote_state" "data_stack" {
  backend = "s3"

  config = {
    bucket         = var.state_bucket
    key            = var.data_state_key
    region         = var.aws_region
    dynamodb_table = var.state_lock_table
    encrypt        = true
  }
}
