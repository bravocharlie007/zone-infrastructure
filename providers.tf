terraform {
  cloud {
    organization = "EC2-DEPLOYER-DEV"
    workspaces {
      name = "zone-infrastructure"
    }
  }
  required_version = "1.4.0"
  required_providers {
    aws = {
      #      source = "hashicorps/aws"
      version = "4.0.0"
    }
  }
}

provider "aws" {
  region = var.region
}

