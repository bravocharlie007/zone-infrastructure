# Zone Infrastructure

This Terraform module manages AWS Route53 DNS zones and records for the EC2 Deployer project, providing DNS routing for the `ec2deployer.com` domain infrastructure.

## Overview

The zone-infrastructure module is part of a multi-workspace Terraform setup that creates and manages:
- Route53 hosted zones for environment-specific subdomains
- DNS alias records pointing to Application Load Balancers (ALBs)
- Name server (NS) records for subdomain delegation
- SSM parameters for storing zone IDs for cross-service reference

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    Main Zone (ec2deployer.com)              │
│                    Zone ID: Z0084331259547XDSW20Q           │
├─────────────────────────────────────────────────────────────┤
│  ┌─────────────────────────────────────────────────────────┐│
│  │     Environment Zone (www.dev.ec2deployer.com)         ││
│  │                                                         ││
│  │  Records Created:                                       ││
│  │  • dev.ec2deployer.com → ALB (in main zone)            ││
│  │  • beta.dev → ALB (in environment zone)                ││
│  │  • supertest.ec2deployer.com → NS delegation           ││
│  └─────────────────────────────────────────────────────────┘│
└─────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────┐
│                     Dependencies                            │
├─────────────────────────────────────────────────────────────┤
│  Compute Workspace (Remote State)                          │
│  • alb_dns_name    ← ALB DNS endpoint                      │
│  • alb_zone_id     ← ALB hosted zone ID                    │
└─────────────────────────────────────────────────────────────┘
```

## Workspace Dependencies

This module depends on the **compute** workspace through Terraform remote state, which must provide:
- `alb_dns_name`: The DNS name of the Application Load Balancer
- `alb_zone_id`: The hosted zone ID of the ALB for alias records

## Resources Created

### Route53 Resources
1. **Primary Hosted Zone**: `www.dev.ec2deployer.com`
   - Environment-specific zone for DNS management
   - Tagged with project metadata and deployment ID

2. **Main Zone Alias Record**: `dev.ec2deployer.com`
   - Points to ALB from compute workspace
   - Type: A record with alias configuration
   - Health checks enabled

3. **Environment Zone Alias Record**: `beta.dev`
   - Points to same ALB within the environment zone
   - Type: A record with alias configuration
   - Health checks enabled

4. **NS Delegation Record**: `supertest.ec2deployer.com`
   - Delegates subdomain to environment zone name servers
   - TTL: 30 seconds

### AWS Systems Manager
- **Zone ID Parameter**: `/application/ec2deployer/resource/terraform/{environment}/zone-id`
  - Stores the created zone ID for other services to reference
  - Tagged with common project tags

## Configuration

### Variables

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `org` | string | `"EC2-DEPLOYER-DEV"` | Terraform Cloud organization |
| `environment` | string | `"dev"` | Deployment environment |
| `region` | string | `"us-east-1"` | AWS deployment region |
| `domain` | string | `"ec2deployer.com"` | Base domain name |
| `previous_workspace` | string | `"compute"` | Name of compute workspace for remote state |
| `main_zone_id` | string | `"Z0084331259547XDSW20Q"` | Main zone ID for NS records |

### Outputs

| Output | Description |
|--------|-------------|
| `zone_id` | The hosted zone ID of the created environment zone |

## Terraform Configuration

- **Version**: 1.4.0 (pinned)
- **Provider**: AWS 4.0.0 (pinned)
- **Backend**: Terraform Cloud
- **Organization**: EC2-DEPLOYER-DEV
- **Workspace**: zone-infrastructure

## Deployment

### Prerequisites
1. Terraform Cloud account with EC2-DEPLOYER-DEV organization
2. AWS credentials configured with Route53 permissions
3. Compute workspace deployed with ALB outputs available
4. Access to the main ec2deployer.com hosted zone

### Commands
```bash
# Initialize Terraform
terraform init

# Plan deployment
terraform plan

# Apply changes
terraform apply
```

## Tagging Strategy

All resources are tagged with:
- `PROJECT_NAME`: ec2deployer
- `PROJECT_COMPONENT`: zone-infrastructure  
- `ENVIRONMENT`: DEV (uppercase)
- `DEPLOYMENT_ID`: Random 6-byte hex string
- `Name`/`NAME`: Formatted resource name
- `TYPE`: Resource type identifier

## Security Considerations ⚠️

**Important Security Notes:**

1. **Hard-coded Zone IDs**: The main zone ID `Z0084331259547XDSW20Q` is hard-coded in multiple files. Consider using variables or data sources for better security and flexibility.

2. **Organization Exposure**: The Terraform Cloud organization name "EC2-DEPLOYER-DEV" is exposed in the code. While not necessarily sensitive, consider using environment variables.

3. **Domain Information**: The domain `ec2deployer.com` is hard-coded. For production deployments, consider parameterizing this.

4. **Provider Source**: There's a commented-out provider source line in `providers.tf` (`#source = "hashicorps/aws"`) which could cause issues. This should either be uncommented with the correct source `hashicorp/aws` or removed.

5. **State Security**: Ensure Terraform Cloud workspace has appropriate access controls and that remote state is encrypted.

## Recommendations

1. Create a `terraform.tfvars.example` file showing required variables
2. Move hard-coded values to variables with appropriate defaults
3. Add validation blocks for critical variables
4. Consider using data sources instead of hard-coded zone IDs
5. Implement proper RBAC for Terraform Cloud workspaces
6. Add lifecycle rules to prevent accidental deletion of DNS zones

## Version History

- **0.0.1**: Initial implementation with basic Route53 zone and record management

## Related Workspaces

This module is part of a larger infrastructure setup:
- **compute**: Provides ALB endpoints (dependency)
- **zone-infrastructure**: This module (DNS management)

---

*Last Updated: Based on commit `c59f904` - "added links to compute ws"*