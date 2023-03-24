variable "org" {
  default = "EC2-DEPLOYER-DEV"
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
  default = "ec2deployer.com"
}

variable "previous_workspace" {
  default = "compute"
}

variable "main_zone_id" {
  default = "Z0084331259547XDSW20Q"

}