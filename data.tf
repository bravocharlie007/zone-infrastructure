data "terraform_remote_state" "compute" {
  backend =  "remote"
  config = {
    organization = var.org
    workspaces = {
      name = var.previous_workspace
    }
  }
}


data "aws_route53_zone" "main_zone" {
zone_id = "Z0084331259547XDSW20Q"
}