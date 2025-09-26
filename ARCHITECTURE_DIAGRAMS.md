# Architecture Diagrams: Previous vs Current Design

## A) Previous Design (Original Implementation)

### DNS Architecture - Before Changes
```
┌─────────────────────────────────────────────────────────────────────────────┐
│                           ORIGINAL DESIGN                                   │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│  ┌─────────────────────────────────────────────────────────────────────────┐│
│  │                    ec2deployer.com (Main Zone)                          ││
│  │                 Zone ID: Z0084331259547XDSW20Q                          ││
│  │                        (HARD-CODED)                                     ││
│  │                                                                         ││
│  │  ┌─────────────────────────────────────────────────────────────────────┐││
│  │  │              www.dev.ec2deployer.com                                │││
│  │  │                 (Environment Zone)                                  │││
│  │  │                                                                     │││
│  │  │  DNS Records Created:                                               │││
│  │  │  • dev.ec2deployer.com → ALB                                        │││
│  │  │  • beta.dev → ALB                                                   │││
│  │  │  • supertest.ec2deployer.com → NS records                          │││
│  │  │                                                                     │││
│  │  │  Issues:                                                            │││
│  │  │  ❌ Zone ID hard-coded in data.tf                                  │││
│  │  │  ❌ Organization name exposed                                       │││
│  │  │  ❌ No variable flexibility                                         │││
│  │  └─────────────────────────────────────────────────────────────────────┘││
│  └─────────────────────────────────────────────────────────────────────────┘│
│                                                                             │
│  Data Sources:                                                              │
│  • terraform_remote_state.compute → ALB info                               │
│  • aws_route53_zone.main_zone (hard-coded ID)                              │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘

Security Issues:
❌ Hard-coded Zone ID: Z0084331259547XDSW20Q in data.tf
❌ Hard-coded Organization: "EC2-DEPLOYER-DEV" in providers.tf  
❌ Hard-coded Domain: "ec2deployer.com" in variables
❌ No environment variable support
❌ Sensitive values in source code
```

### Infrastructure Flow - Before Changes
```
┌─────────────────────────────────────────────────────────────────────────────┐
│                        WORKSPACE DEPENDENCIES                               │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│  VPC Workspace                                                              │
│  ├── Creates: VPC, Subnets, IGW, Route Tables                              │
│  └── Outputs: vpc_id, subnet_id_list                                       │
│                           │                                                 │
│                           ▼                                                 │
│  Compute Workspace                                                          │
│  ├── Uses: VPC outputs via remote state                                    │
│  ├── Creates: EC2 instances, ALB, Security Groups, EIPs                    │
│  └── Outputs: alb_dns_name, alb_zone_id                                    │
│                           │                                                 │
│                           ▼                                                 │
│  Zone Infrastructure (THIS REPO - ORIGINAL)                                │
│  ├── Uses: Compute outputs via remote state                                │
│  ├── Hard-coded: Zone IDs, organization names                              │
│  ├── Creates: Route53 zones, DNS records, SSM parameters                   │
│  └── Issues: No flexibility, security concerns                             │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

## B) Current Design (After Improvements)

### DNS Architecture - After Changes
```
┌─────────────────────────────────────────────────────────────────────────────┐
│                           IMPROVED DESIGN                                   │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│  ┌─────────────────────────────────────────────────────────────────────────┐│
│  │                    ec2deployer.com (Main Zone)                          ││
│  │                 Zone ID: var.main_zone_id                               ││
│  │                    (CONFIGURABLE)                                       ││
│  │                                                                         ││
│  │  ┌─────────────────────────────────────────────────────────────────────┐││
│  │  │              www.dev.ec2deployer.com                                │││
│  │  │                 (Environment Zone)                                  │││
│  │  │                                                                     │││
│  │  │  DNS Records Created:                                               │││
│  │  │  • dev.ec2deployer.com → ALB                                        │││
│  │  │  • beta.dev → ALB                                                   │││
│  │  │  • supertest.ec2deployer.com → NS records                          │││
│  │  │                                                                     │││
│  │  │  Improvements:                                                      │││
│  │  │  ✅ Zone ID from variables                                         │││
│  │  │  ✅ Environment variable support                                   │││
│  │  │  ✅ Proper variable typing                                         │││
│  │  │  ✅ Flexible configuration                                         │││
│  │  └─────────────────────────────────────────────────────────────────────┘││
│  └─────────────────────────────────────────────────────────────────────────┘│
│                                                                             │
│  Data Sources:                                                              │
│  • terraform_remote_state.compute → ALB info                               │
│  • aws_route53_zone.main_zone (using var.main_zone_id)                     │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘

Security Improvements:
✅ Zone ID via variable: var.main_zone_id
✅ Organization configurable: var.org
✅ Domain parameterized: var.domain  
✅ Environment variable support: TF_VAR_*
✅ Sensitive values externalized
✅ terraform.tfvars.example provided
```

### Infrastructure Flow - After Changes
```
┌─────────────────────────────────────────────────────────────────────────────┐
│                     IMPROVED WORKSPACE FLOW                                 │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│  1. VPC Workspace                                                           │
│  ├── Creates: VPC (15.0.0.0/16), Public Subnets, IGW                      │
│  ├── Outputs: vpc_id, subnet_id_list, igw_id                               │
│  └── Status: ✅ Secure (no external exposure)                              │
│                           │                                                 │
│                           ▼                                                 │
│  2. Compute Workspace                                                       │
│  ├── Uses: VPC outputs via remote state                                    │
│  ├── Creates: Gaming EC2s, ALB, Security Groups, EIPs                      │
│  ├── Outputs: alb_dns_name, alb_zone_id, ec2_instances                     │
│  └── Status: ⚠️ Security issues (separate from this repo)                 │
│                           │                                                 │
│                           ▼                                                 │
│  3. Zone Infrastructure (THIS REPO - IMPROVED)                             │
│  ├── Uses: Compute outputs via remote state                                │
│  ├── Configurable: All values via variables/env vars                       │
│  ├── Creates: Route53 zones, DNS records, SSM parameters                   │
│  ├── Security: Proper variable management                                  │
│  └── Status: ✅ Secure DNS layer                                           │
│                                                                             │
│  Configuration Options:                                                     │
│  ├── terraform.tfvars (git-ignored)                                        │
│  ├── Environment variables: TF_VAR_org, TF_VAR_main_zone_id               │
│  ├── Terraform Cloud variables (encrypted)                                 │
│  └── Default values for development                                         │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

## Key Differences Summary

| Aspect | Previous Design | Current Design |
|--------|----------------|----------------|
| **Zone ID** | Hard-coded in data.tf | Variable with environment support |
| **Organization** | Hard-coded in providers.tf | Configurable via variables |
| **Domain** | Hard-coded string | Parameterized variable |
| **Flexibility** | None - fixed values | Full variable support |
| **Security** | Values exposed in code | Externalized configuration |  
| **Environment Support** | No TF_VAR_ support | Full environment variable support |
| **Documentation** | Minimal | Comprehensive with examples |
| **Git Security** | Sensitive values in repo | .gitignore protects terraform.tfvars |

## Zone ID Security Concerns

### Why Zone ID Exposure Matters:

1. **Information Disclosure**
   - Zone IDs reveal your AWS account structure
   - Attackers can enumerate your DNS infrastructure
   - Provides reconnaissance information for attacks

2. **Targeted Attacks**
   - Known zone IDs enable DNS enumeration attacks
   - Attackers can attempt zone transfers
   - Social engineering attacks against your domain

3. **Compliance Issues**
   - Many security frameworks require protecting infrastructure identifiers
   - Audit failures if sensitive IDs are in source code
   - Best practice violation

4. **Operational Security**
   - Hard-coded values make rotation impossible
   - No way to use different zones for different environments
   - Breaks infrastructure as code flexibility

### Risk Level: MEDIUM
While not as critical as exposed credentials, Zone ID exposure:
- ❌ Violates security best practices
- ❌ Provides attack reconnaissance data
- ❌ Reduces infrastructure flexibility
- ✅ Fixed by using variables and environment configuration