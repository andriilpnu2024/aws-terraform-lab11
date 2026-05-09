variable "aws_region" {
  type = string
}

variable "project" {
  type = string
}

variable "environment" {
  type = string
}

variable "state_bucket" {
  type = string
}

variable "state_lock_table" {
  type    = string
  default = "terraform-tfstate-lock"
}


variable "data_state_key" {
  type    = string
  default = "lab1/data/terraform.tfstate"
}

variable "app_state_key" {
  type    = string
  default = "lab1/app/terraform.tfstate"
}

variable "account_id" {
  description = "AWS account ID"
  type        = string
}

variable "namespace" {
  description = "Namespace for naming"
  type        = string
}

variable "stage" {
  description = "Stage/environment"
  type        = string
}

variable "name" {
  description = "Project/application name"
  type        = string
}

variable "tags" {
  description = "Common tags"
  type        = map(string)
  default     = {}
}
variable "alert_email" {
  description = "Email address for SNS alerts"
  type        = string
}
