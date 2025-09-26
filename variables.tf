variable "org" {
  type        = string
  description = "Terraform Cloud organization name"
  default     = "EC2-DEPLOYER-DEV"
}

variable "environment" {
  type = string
  default = "dev"
}

variable "region" {
  type = string
  description = "aws-deployment-region"
  default = "us-east-1"
}

variable "domain" {
  type        = string
  description = "Base domain name for the project"
  default     = "ec2deployer.com"
}

variable "previous_workspace" {
  type        = string
  description = "Name of the previous workspace for remote state dependency"
  default     = "compute"
}

variable "main_zone_id" {
  type        = string
  description = "Route53 zone ID for the main domain"
  default     = "Z0084331259547XDSW20Q"
}