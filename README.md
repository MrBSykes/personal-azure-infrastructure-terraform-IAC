# 🏗️ Personal Azure Infrastructure — Terraform IaC
### Hub & Spoke Network · NSGs · Private VM · Private Endpoints · Remote State

![Terraform](https://img.shields.io/badge/Terraform-IaC-7B42BC?style=for-the-badge&logo=terraform&logoColor=white)
![Azure](https://img.shields.io/badge/Azure-Cloud-0078D4?style=for-the-badge&logo=microsoftazure&logoColor=white)
![Status](https://img.shields.io/badge/Status-In_Progress-F5A623?style=for-the-badge)
![Security](https://img.shields.io/badge/Security-Least_Privilege-2ea44f?style=for-the-badge)

---

## Overview

> **Documentation coming soon — project begins post AZ-900 exam (September 24, 2026)**

This project builds a complete, secure, repeatable Azure environment using **Terraform Infrastructure as Code (IaC)** — no manual portal clicks, no one-off CLI commands. Every resource is defined in code, versioned in Git, and deployable consistently across development and production environments with a single `terraform apply`.

This is the next phase of the home lab Azure portfolio, building on the CLI-based work documented in:
- [Linux to Azure — Phase 1: Automated Log Backup](#)
- [Linux to Azure — Phase 2: Portal Verification & Security Hardening](#)

---

## Architecture

```
                        ┌─────────────────────────────────┐
                        │         Hub VNet                │
                        │   (Shared Services Subnet)      │
                        │                                 │
                        │  ┌─────────────────────────┐   │
                        │  │   Azure Bastion / VPN   │   │
                        │  └─────────────────────────┘   │
                        └──────────┬──────────┬──────────┘
                                   │ VNet     │ VNet
                                   │ Peering  │ Peering
                    ┌──────────────┘          └──────────────┐
                    │                                        │
          ┌─────────▼──────────┐              ┌─────────────▼──────────┐
          │    Dev Spoke VNet  │              │   Prod Spoke VNet      │
          │                    │              │                        │
          │  ┌──────────────┐  │              │  ┌──────────────────┐  │
          │  │ Private      │  │              │  │ Private          │  │
          │  │ Subnet       │  │              │  │ Subnet           │  │
          │  │              │  │              │  │                  │  │
          │  │  ┌────────┐  │  │              │  │  ┌───────────┐   │  │
          │  │  │  VM    │  │  │              │  │  │ Storage   │   │  │
          │  │  │(Linux) │  │  │              │  │  │ Account + │   │  │
          │  │  └────────┘  │  │              │  │  │ Private   │   │  │
          │  │              │  │              │  │  │ Endpoint  │   │  │
          │  └──────────────┘  │              │  └──────────────────┘  │
          │       NSG ↕        │              │         NSG ↕          │
          └────────────────────┘              └────────────────────────┘

                    Terraform Remote State
                    Azure Blob Storage Backend
                    ┌────────────────────────┐
                    │ tfstate container       │
                    │ State locking via       │
                    │ Azure Storage Table     │
                    └────────────────────────┘
```

---

## Project Components

| # | Component | Description | Status |
|---|---|---|---|
| 1 | **Hub & Spoke VNet** | Hub VNet with shared services, spoke VNets for dev/prod with VNet peering | 🔲 Planned |
| 2 | **Network Security Groups** | Least privilege NSG rules — default deny, explicit allow only | 🔲 Planned |
| 3 | **Linux VM (Private Subnet)** | Virtual machine deployed in private subnet, no public IP, SSH via Bastion | 🔲 Planned |
| 4 | **Storage Account + Private Endpoint** | Storage account accessible only from within the VNet — no public internet exposure | 🔲 Planned |
| 5 | **Terraform Remote State** | State file stored in Azure Blob Storage with state locking via Storage Table | 🔲 Planned |

---

## Repository Structure

```
terraform-azure-infrastructure/
│
├── README.md
│
├── modules/
│   ├── networking/
│   │   ├── main.tf          # Hub VNet, spoke VNets, peering
│   │   ├── variables.tf
│   │   └── outputs.tf
│   │
│   ├── nsg/
│   │   ├── main.tf          # NSG rules — least privilege
│   │   ├── variables.tf
│   │   └── outputs.tf
│   │
│   ├── compute/
│   │   ├── main.tf          # Linux VM in private subnet
│   │   ├── variables.tf
│   │   └── outputs.tf
│   │
│   └── storage/
│       ├── main.tf          # Storage account + private endpoint
│       ├── variables.tf
│       └── outputs.tf
│
├── environments/
│   ├── dev/
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── terraform.tfvars
│   │
│   └── prod/
│       ├── main.tf
│       ├── variables.tf
│       └── terraform.tfvars
│
├── backend/
│   ├── main.tf              # Remote state storage account bootstrap
│   └── README.md
│
├── screenshots/
└── docs/
    ├── architecture.md
    └── troubleshooting.md
```

---

## Prerequisites

- [ ] Terraform installed (`winget install HashiCorp.Terraform` on Windows)
- [ ] Azure CLI installed and authenticated (`az login`)
- [ ] Azure subscription with contributor access
- [ ] Terraform VS Code extension (HashiCorp Terraform)
- [ ] Git configured

---

## Setup — Phase 0: Remote State Backend

> Must be done FIRST before any other Terraform work. The remote state backend stores your terraform.tfstate file in Azure so it's never lost and can be shared across machines.

```bash
# Step 1 — Create backend storage (one time, done via CLI not Terraform)
az group create --name TerraformStateRG --location eastus

az storage account create \
  --name sykestfstate \
  --resource-group TerraformStateRG \
  --location eastus \
  --sku Standard_LRS \
  --min-tls-version TLS1_2

az storage container create \
  --name tfstate \
  --account-name sykestfstate

# Step 2 — Configure backend in Terraform
# Add to your main.tf:
terraform {
  backend "azurerm" {
    resource_group_name  = "TerraformStateRG"
    storage_account_name = "sykestfstate"
    container_name       = "tfstate"
    key                  = "dev.terraform.tfstate"
  }
}
```

---

## Terraform Workflow

```bash
# Initialize — downloads providers, configures backend
terraform init

# Plan — shows what will be created/changed/destroyed
terraform plan

# Apply — builds the infrastructure
terraform apply

# Destroy — tears everything down cleanly
terraform destroy
```

---

## NSG Rules — Least Privilege Design

| Rule | Priority | Direction | Source | Destination | Port | Action |
|---|---|---|---|---|---|---|
| Allow SSH from Bastion | 100 | Inbound | AzureBastionSubnet | VirtualNetwork | 22 | Allow |
| Allow HTTPS outbound | 200 | Outbound | VirtualNetwork | Internet | 443 | Allow |
| Deny all inbound | 4096 | Inbound | Any | Any | Any | **Deny** |
| Deny all outbound | 4096 | Outbound | Any | Any | Any | **Deny** |

---

## Skills Demonstrated

| Skill | Tool / Service |
|---|---|
| Infrastructure as Code | Terraform (HCL) |
| Azure Networking | VNet, Subnet, VNet Peering, NSG |
| Azure Compute | Linux VM, private subnet deployment |
| Azure Storage | Storage Account, Private Endpoint, DNS |
| State Management | Terraform Remote Backend, Azure Blob Storage |
| Security | Least privilege NSG, private endpoints, no public IPs |
| Repeatability | Environment-separated tfvars (dev/prod) |
| Version Control | Git — all infrastructure versioned and auditable |

---

## AZ-900 / AZ-104 Alignment

This project maps to Azure Administrator (AZ-104) exam objectives — a natural next certification after AZ-900:

| AZ-104 Domain | Coverage |
|---|---|
| Manage Azure identities and governance | RBAC, resource groups, subscriptions |
| Implement and manage virtual networking | VNet, subnets, NSG, VNet peering |
| Deploy and manage Azure compute resources | Linux VM, availability, sizing |
| Implement and manage storage | Storage accounts, private endpoints, access tiers |
| Monitor and maintain Azure resources | Terraform state, resource lifecycle |

---

## Related Projects

- [🐧 Linux Lab Machine — Swapping Kali for Ubuntu](#)
- [☁️ Linux to Azure — Phase 1: Automated Log Backup](#)
- [☁️ Linux to Azure — Phase 2: Portal Verification & Security Hardening](#)
- [🪟 Active Directory Home Lab — Phase 1](#)
- [🔒 Security Onion Home Lab](#)

---

## Documentation

Full project documentation will be added as each phase is completed following the same format as previous portfolio projects.

---

*Bryan Sykes | Home Lab Portfolio | 2026*
*[![LinkedIn](https://img.shields.io/badge/LinkedIn-SecuredByBryan-0A66C2?style=flat&logo=linkedin)](https://linkedin.com) [![GitHub](https://img.shields.io/badge/GitHub-MrBSykes-181717?style=flat&logo=github)](https://github.com/MrBSykes) [![X](https://img.shields.io/badge/X-@SecuredByBryan-000000?style=flat&logo=x)](https://x.com/SecuredByBryan)*
