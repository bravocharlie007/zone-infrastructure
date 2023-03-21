resource "aws_ssm_parameter" "dev_zone_id_ssm" {
  type = "String"
  name = "/application/ec2deployer/resource/terraform/${var.environment}/zone-id"
  value = aws_route53_zone.zone.zone_id
  tags = local.common_tags
}