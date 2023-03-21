resource "random_id" "deployment_id" {
  byte_length = 6
}

locals {
  project_name           = "ec2deployer"
  replace_string         = "REPLACEME"
  localized_project_name = "${local.project_name}-${local.replace_string}-${local.upper_env}"
  project_component      = "zone-infrastructure"
  upper_env              = upper(var.environment)
  zone_name              = "www.dev.${var.domain}"
  timestamp              = timestamp()
  zone_type              = "zone"
  common_tags            = tomap({
    "PROJECT_NAME"      = local.project_name,
    "PROJECT_COMPONENT" = local.project_component,
    "ENVIRONMENT"       = local.upper_env,
    "DEPLOYMENT_ID"     = random_id.deployment_id.hex
  })

  zone_tags = merge(
    tomap({
      "Name" = replace(local.localized_project_name, local.replace_string, local.zone_type),
      "NAME" = replace(local.localized_project_name, local.replace_string, local.zone_type),
      "TYPE" = local.zone_type
    }),
    local.common_tags
  )
}