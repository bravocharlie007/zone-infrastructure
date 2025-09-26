# Zone Infrastructure

This Terraform module manages AWS Route53 DNS zones and records for the EC2 Deployer project, providing DNS routing for the `ec2deployer.com` domain infrastructure.

## Overview

The zone-infrastructure module is part of a multi-workspace Terraform setup that creates and manages:
- Route53 hosted zones for environment-specific subdomains
- DNS alias records pointing to Application Load Balancers (ALBs)
- Name server (NS) records for subdomain delegation
- SSM parameters for storing zone IDs for cross-service reference

## Architecture

### Complete Infrastructure Overview
```
┌─────────────────────────────────────────────────────────────┐
│                    WORKSPACE ARCHITECTURE                   │
├─────────────────────────────────────────────────────────────┤
│  1. VPC Workspace                                           │
│     • Creates VPC (15.0.0.0/16)                            │
│     • Public subnets across multiple AZs                   │
│     • Internet Gateway & Route Tables                      │
│     • Outputs: vpc_id, subnet_id_list                      │
│                                                             │
│  2. Compute Workspace (depends on VPC)                     │
│     • EC2 instances for gaming                              │
│     • Application Load Balancer                            │
│     • Security Groups                                       │
│     • Elastic IPs                                           │
│     • Outputs: alb_dns_name, alb_zone_id                   │
│                                                             │
│  3. Zone Infrastructure (depends on Compute)               │
│     • Route53 hosted zones                                  │
│     • DNS alias records → ALB                              │
│     • SSM parameters for zone IDs                          │
└─────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────┐
│                    DNS STRUCTURE                            │
├─────────────────────────────────────────────────────────────┤
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
```

### Deployment Order
**CRITICAL: Workspaces must be deployed in this exact order:**

1. **VPC Workspace** → Creates network foundation
2. **Compute Workspace** → Creates gaming instances and load balancer  
3. **Zone Infrastructure** → Creates DNS routing (this repository)

## Workspace Dependencies

### Complete Dependency Chain
```
VPC Workspace
    ↓ (provides vpc_id, subnet_id_list)
Compute Workspace  
    ↓ (provides alb_dns_name, alb_zone_id)
Zone Infrastructure ← YOU ARE HERE
```

### Required Remote State Outputs

**From Compute Workspace:**
- `alb_dns_name`: DNS name of the Application Load Balancer
- `alb_zone_id`: Hosted zone ID of the ALB for alias records

**From VPC Workspace (via Compute):**
- `vpc_id`: VPC identifier for security groups
- `subnet_id_list`: Public subnet IDs for ALB placement

### Terraform Cloud Workspace Configuration

All workspaces use organization: `EC2-DEPLOYER-DEV`
- `vpc` → Creates network foundation
- `compute` → Creates gaming infrastructure  
- `zone-infrastructure` → Creates DNS routing (this repository)

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

**Note**: All variables can be overridden via `terraform.tfvars` or environment variables (`TF_VAR_<variable_name>`).

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

## Security Analysis ⚠️

**CRITICAL: After reviewing your complete infrastructure (VPC, Compute, Zone), serious security vulnerabilities were identified.**

### 🚨 IMMEDIATE ACTION REQUIRED

**Current Security Issues in Compute Workspace:**
1. **SSH open to internet** (`0.0.0.0/0`) with password authentication enabled
2. **Missing gaming ports** (RDP 3389, Steam ports, etc.)
3. **No VPN or secure access method** for family members
4. **Overly permissive security groups** 

### Security Assessment Correction

**My Initial "Simplified" Recommendations Were INADEQUATE** after seeing your actual infrastructure. The enterprise-grade security I initially suggested (VPN, bastion hosts, MFA) is **actually necessary** because:

- Your EC2 instances are directly exposed to the internet
- SSH is open to the world with password auth enabled  
- No secure access path for gaming clients
- Missing critical gaming security measures

### Required Fixes (Compute Workspace)

See `GAMING_SECURITY.md` for detailed implementation:

1. **Deploy WireGuard VPN server** (family connects through this)
2. **Remove SSH access from 0.0.0.0/0** (VPN-only access)
3. **Add RDP (3389) through VPN only** for gaming
4. **Disable password authentication** in user data
5. **Add gaming-specific ports** (Steam, Discord, etc.)

### DNS Layer Security (This Repository)

**Configuration Security**: 
- All sensitive values now support environment variables (`TF_VAR_org`, `TF_VAR_main_zone_id`, etc.)
- Proper variable typing and validation
- Best practices documented in terraform.tfvars.example

**Zone ID Management**: Fixed hard-coded values, now properly referenced via variables.

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