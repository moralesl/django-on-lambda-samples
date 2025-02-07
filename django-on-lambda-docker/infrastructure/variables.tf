variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "eu-central-1"
}

variable "project_name" {
  description = "Project Name"
  type        = string
}

variable "db_name" {
  description = "Database name"
  type        = string
}

variable "db_username" {
  description = "Database username"
  type        = string
}

variable "db_password" {
  description = "Database password"
  type        = string
  sensitive   = true
}

variable "django_secret_key" {
  description = "Django secret key"
  type        = string
  sensitive   = true
}

data "aws_availability_zones" "available" {
  state = "available"
}

# variable "admin_username" {
#   description = "Django admin username"
#   type        = string
#   default     = "admin"
# }

# variable "admin_email" {
#   description = "Django admin email"
#   type        = string
#   default     = "admin@example.com"
# }

# variable "admin_password" {
#   description = "Django admin password"
#   type        = string
#   sensitive   = true
# }
