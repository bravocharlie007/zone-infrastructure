resource "aws_route53_zone" zone {
  name = local.zone_name
  tags_all = local.zone_tags
}

resource "aws_route53_record" "alias_alb_record_in_main_zone" {
  zone_id = var.main_zone_id
  name =  "${var.environment}.${var.domain}"
  type = "A"

  alias {
    name = data.terraform_remote_state.compute.outputs.alb_dns_name
    zone_id = data.terraform_remote_state.compute.outputs.alb_zone_id
    evaluate_target_health = true
  }
}

resource "aws_route53_record" "alias_alb_record_in_env_zone" {
  zone_id = aws_route53_zone.zone.zone_id
  name =  "beta.${var.environment}"
  type = "A"

  alias {
    name = data.terraform_remote_state.compute.outputs.alb_dns_name
    zone_id = data.terraform_remote_state.compute.outputs.alb_zone_id
    evaluate_target_health = true
  }
}

resource "aws_route53_record" "dev-ns" {
  zone_id = data.aws_route53_zone.main_zone.id
  name    = "supertest.ec2deployer.com"
  type    = "NS"
  ttl     = "30"
  records = aws_route53_zone.zone.name_servers
}