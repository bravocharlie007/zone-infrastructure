resource "aws_route53_zone" zone {
  name = local.zone_name
  tags_all = local.zone_tags
}