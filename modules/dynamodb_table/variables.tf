variable "aws_region" {
  type = string
}

variable "name" {
  type = string
}

variable "billing_mode" {
  type    = string
  default = "PAY_PER_REQUEST"
}

variable "hash_key" {
  type    = string
  default = "id"
}

variable "hash_key_type" {
  type    = string
  default = "S"
}

variable "tags" {
  type    = map(string)
  default = {}
}
