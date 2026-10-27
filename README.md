# 🏗️ Personal Azure Infrastructure with Terraform IaC
### Hub & Spoke Network · NSGs · Private Endpoint · Remote State

![Terraform](https://img.shields.io/badge/Terraform-IaC-7B42BC?style=for-the-badge&logo=terraform&logoColor=white)
![Azure](https://img.shields.io/badge/Azure-Hub_%26_Spoke-0078D4?style=for-the-badge&logo=microsoftazure&logoColor=white)
![Status](https://img.shields.io/badge/Status-Core_Deployed-2ea44f?style=for-the-badge)
![Security](https://img.shields.io/badge/Security-Default_Deny-critical?style=for-the-badge)

---

## Overview

This project defines a secure, repeatable Azure environment entirely in Terraform: no portal clicks to build it, and every resource lives in code under version control. Hub and spoke networking, a least-privilege network security group, a storage account reachable only through a private endpoint, and Terraform state kept in Azure Blob Storage.

It is the next step after my CLI-based work in [Linux to Azure: Automated Log Backup](https://github.com/MrBSykes/linux-to-azure-automated-syslog-backup). That project built and verified resources by hand with the Azure CLI. This one defines them as code so the same environment can be rebuilt or destroyed with one command.

**Status:** 20 resources deployed and tracked in Terraform state, built from three reusable modules. The Linux VM and Azure Bastion are written and plan cleanly, but sit behind cost switches that default to off (see [What is and is not built](#what-is-and-is-not-built)).

Write-ups:
- **[Version 2 (October 2026)](docs/personal-azure-infrastructure-terraform-documentation-v2.pdf)**: module refactor, prod controls, what each component does in Azure, the business problem it solves, and what I would do differently next time.
- [Original write-up (September 2026)](docs/personal-azure-infrastructure-terraform-documentation.pdf): the first version, kept for the project history.

---

## Architecture

```
                  ┌───────────────────────────┐
                  │ hub-vnet  10.0.0.0/16     │
                  │ GatewaySubnet 10.0.0.0/24 │
                  └─────────┬───────────┬─────┘
                  VNet peering         VNet peering
                  (both directions)    (both directions)
              ┌─────────────┘           └─────────────┐
   ┌──────────▼───────────┐                ┌──────────▼───────────┐
   │ dev-vnet 10.1.0.0/16 │                │ prod-vnet 10.2.0.0/16│
   │ private-subnet       │                │ private-subnet       │
   │  10.1.1.0/24         │                │  10.2.1.0/24         │
   │  ├ dev-nsg           │                │  └ prod-nsg          │
   │  └ dev-storage-pe ───┼─► sykesdevstore│                      │
   └──────────────────────┘   (public      └──────────────────────┘
                               access off)   sykesprodstore (public
                                             access off, no private
                                             endpoint yet)

Remote state: TerraformStateRG / sykestfstate / tfstate
```

Dev and prod are peered only to the hub, never to each other, so a compromise in one spoke has no direct path to the other.

---

## What is and is not built

| # | Component | Status |
|---|---|---|
| 1 | Hub and spoke VNets with bidirectional peering (hub-dev, hub-prod) | ✅ Deployed |
| 2 | Network security group on the dev private subnet (default deny inbound, SSH only from the hub range, HTTPS outbound) | ✅ Deployed |
| 3 | Storage account `sykesdevstore` with public network access off, plus a blob private endpoint in the dev subnet | ✅ Deployed |
| 4 | Remote state in Azure Blob Storage (`sykestfstate`) | ✅ Deployed |
| 5 | Linux VM in the dev private subnet, no public IP | ⏸ Code complete behind `enable_vm` (default off). Plans cleanly; not deployed to keep cost at zero. Free-tier B-series capacity was unavailable during the original build |
| 6 | Azure Bastion (Basic SKU) in the hub | ⏸ Code complete behind `enable_bastion` (default off). Plans cleanly (5 resources with the VM); billed hourly, so reserved for a timed demo |
| 7 | NSG and storage account in the prod spoke | ✅ Deployed (same baseline NSG; storage with public access off and no private endpoint, a cost trade-off) |
| 8 | Refactor into modules, spokes defined as data | ✅ Done. 14 resources moved into modules with `moved` blocks and a zero-destroy plan |

---|---|---|
| 1 | Hub and spoke VNets with bidirectional peering (hub-dev, hub-prod) | ✅ Deployed |
| 2 | Network security group on the dev private subnet (default deny inbound, SSH only from the hub range, HTTPS outbound) | ✅ Deployed |
| 3 | Storage account `sykesdevstore` with public access denied, plus a blob private endpoint in the dev subnet | ✅ Deployed |
| 4 | Remote state in Azure Blob Storage (`sykestfstate`) | ✅ Deployed |
| 5 | Linux VM in the dev private subnet, no public IP | ⏸ Code written, commented out. Azure free tier had no B-series capacity in East US or East US 2 |
| 6 | Azure Bastion in the hub | 🔲 Planned |
| 7 | NSG and storage account in the prod spoke | 🔲 Planned |
| 8 | Refactor into modules, dev/prod tfvars | 🔲 Planned |

---

## Repository Layout

```
.
├── README.md
├── terraform/
│   ├── providers.tf               # provider version and remote backend
│   ├── variables.tf               # subscription_id and the spokes map
│   ├── hub.tf                     # hub resource group, VNet, GatewaySubnet
│   ├── spokes.tf                  # calls the three modules once per spoke
│   ├── spokes.auto.tfvars         # dev and prod defined as data (no secrets)
│   ├── moved.tf                   # state moves from the old flat layout
│   ├── switches.tf                # enable_vm / enable_bastion cost switches (default false)
│   ├── vm.tf                      # dev test VM, off by default
│   ├── bastion.tf                 # hub Bastion, off by default
│   ├── terraform.tfvars.example
│   ├── .terraform.lock.hcl        # pins provider versions
│   └── modules/
│       ├── spoke-network/         # resource group, VNet, subnet, both peerings
│       ├── baseline-nsg/          # default-deny NSG and subnet association
│       └── secure-storage/        # storage account and optional private endpoint
├── docs/
│   ├── personal-azure-infrastructure-terraform-documentation.pdf      # original, Sept 2026
│   └── personal-azure-infrastructure-terraform-documentation-v2.pdf   # Oct 2026
└── screenshots/                   # Azure portal screenshots of the deployed resources
```

Adding an environment is a new entry in `spokes.auto.tfvars`, not new code.

---

## Resources deployed

| Area | Resources |
|---|---|
| Resource groups | `hub-rg` (East US), `dev-rg` (East US 2), `prod-rg` (East US) |
| Networks | `hub-vnet` 10.0.0.0/16, `dev-vnet` 10.1.0.0/16, `prod-vnet` 10.2.0.0/16 |
| Subnets | `GatewaySubnet` 10.0.0.0/24, dev `private-subnet` 10.1.1.0/24, prod `private-subnet` 10.2.1.0/24 |
| Peerings | hub-to-dev, dev-to-hub, hub-to-prod, prod-to-hub |
| Security | `dev-nsg` and `prod-nsg` (same baseline rules), each associated to its private subnet |
| Storage | `sykesdevstore` and `sykesprodstore` (TLS 1.2, default action Deny, public network access off, anonymous blob access off) and the `dev-storage-pe` private endpoint |
| State | `TerraformStateRG` / `sykestfstate` / container `tfstate` (created with the CLI before Terraform) |

### NSG rules (`dev-nsg` and `prod-nsg`)

| Rule | Priority | Direction | Source | Port | Action |
|---|---|---|---|---|---|
| allow-ssh-inbound | 100 | Inbound | 10.0.0.0/16 (hub range) | 22 | Allow |
| allow-https-outbound | 200 | Outbound | Any | 443 to Internet | Allow |
| deny-all-inbound | 4096 | Inbound | Any | Any | Deny |

Outbound traffic falls back to Azure's default rules, so there is no explicit deny-all-outbound rule.

---

## Setup

### Prerequisites

- Terraform (`winget install HashiCorp.Terraform` on Windows)
- Azure CLI, signed in with `az login`
- An Azure subscription where you can create resources

### 1. Create the remote state backend (once, with the CLI)

```bash
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
```

Storage account names are globally unique, so use your own name and update the `backend` block in `terraform/providers.tf` to match.

### 2. Set your subscription

```bash
cd terraform
# PowerShell
$env:TF_VAR_subscription_id = az account show --query id -o tsv
# bash
export TF_VAR_subscription_id=$(az account show --query id -o tsv)
```

The ID is passed through the environment, so it never lands in a file. (You can also copy `terraform.tfvars.example` to `terraform.tfvars`, which is gitignored.)

### 3. Run Terraform

```bash
terraform init      # downloads the provider, configures the backend
terraform plan      # shows what will be created
terraform apply     # builds it
terraform destroy   # tears it down
```

The VM and Bastion are off by default. To preview them without creating anything:

```bash
terraform plan -var enable_vm=true -var enable_bastion=true   # plan only
```

Applying with those switches creates billable resources (Bastion bills hourly while it exists), so only do it for a timed demo and destroy it in the same sitting.

---

## Screenshots

| # | Screenshot | What it shows |
|---|---|---|
| 01 | ![](screenshots/01-dev-rg-resources.png) | `dev-rg`: NSG, private endpoint and its NIC, VNet, storage account |
| 02 | ![](screenshots/02-hub-rg-resources.png) | `hub-rg`: hub VNet |
| 03 | ![](screenshots/03-prod-rg-resources.png) | `prod-rg` before stage 2: prod VNet only |
| 04 | ![](screenshots/04-terraform-state-rg.png) | `TerraformStateRG`: the state storage account |
| 05 | ![](screenshots/05-dev-vnet-resource-visualizer.png) | Resource visualizer: dev VNet linked to hub VNet, NSG and private endpoint |
| 06 | ![](screenshots/06-dev-nsg-security-rules.png) | `dev-nsg` inbound and outbound rules |
| 07 | ![](screenshots/07-sykesdevstore-BEFORE-lockdown.png) | `sykesdevstore` **before** the fix: public network access and anonymous blob access still enabled |
| 08 | ![](screenshots/08-hub-vnet-peerings.png) | Hub peerings to prod and dev: Connected, Fully Synchronized |
| 09 | ![](screenshots/09-dev-vnet-peerings.png) | Dev to hub peering: Connected |
| 10 | ![](screenshots/10-prod-vnet-peerings.png) | Prod to hub peering: Connected |
| 11 | ![](screenshots/11-sykesdevstore-AFTER-lockdown.png) | `sykesdevstore` **after** the fix: public network access Disabled, anonymous blob access Disabled, one private endpoint connection |
| 12 | ![](screenshots/12-prod-rg-resources-UPDATED.png) | `prod-rg` after stage 2: NSG, VNet, `sykesprodstore` |
| 13 | ![](screenshots/13-prod-nsg-security-rules.png) | `prod-nsg`: same baseline rules as dev |

Screenshots 07 and 11 show a gap found in review (the dev storage account was still reachable from selected public networks), fixed in code, and re-verified in the portal.

---|---|---|
| 01 | ![](screenshots/01-dev-rg-resources.png) | `dev-rg`: NSG, private endpoint and its NIC, VNet, storage account |
| 02 | ![](screenshots/02-hub-rg-resources.png) | `hub-rg`: hub VNet |
| 03 | ![](screenshots/03-prod-rg-resources.png) | `prod-rg`: prod VNet |
| 04 | ![](screenshots/04-terraform-state-rg.png) | `TerraformStateRG`: the state storage account |
| 05 | ![](screenshots/05-dev-vnet-resource-visualizer.png) | Resource visualizer: dev VNet linked to hub VNet, NSG and private endpoint |
| 06 | ![](screenshots/06-dev-nsg-security-rules.png) | `dev-nsg` inbound and outbound rules |
| 07 | ![](screenshots/07-sykesdevstore-properties.png) | `sykesdevstore`: TLS 1.2, one private endpoint connection, public access limited |
| 08 | ![](screenshots/08-hub-vnet-peerings.png) | Hub peerings to prod and dev: Connected, Fully Synchronized |
| 09 | ![](screenshots/09-dev-vnet-peerings.png) | Dev to hub peering: Connected |
| 10 | ![](screenshots/10-prod-vnet-peerings.png) | Prod to hub peering: Connected |

---

## Troubleshooting Log

| # | Issue | Root cause | Resolution |
|---|---|---|---|
| 1 | `terraform init`: `az` executable not found | Azure CLI was on the Ubuntu box, not the Windows machine running Terraform | Installed Azure CLI on Windows and restarted VS Code |
| 2 | `plan` failed registering resource providers | Free tier lacks permission for automatic registration | Registered Microsoft.Network, Compute and Storage with `az provider register` |
| 3 | ED25519 SSH key rejected for the VM | Azure Linux VMs accept only RSA keys | Generated a dedicated RSA 4096 key for Azure |
| 4 | `SkuNotAvailable` for B1s and B1ms | No free-tier B-series capacity in East US or East US 2 | Commented the VM out; code is kept for later |
| 5 | Peering "inconsistent result" after changing dev to East US 2 | Peering existed in Azure but was no longer in state | Brought it back with `terraform import` |
| 6 | Push rejected: provider binary over 100 MB | `.terraform/` was committed before a `.gitignore` existed | Added `.gitignore`, removed the binary from history with `git filter-branch`, force pushed |
| 7 | Subscription disabled when the free trial credit expired | Free accounts are disabled at 30 days or when the $200 credit runs out | Upgraded to pay-as-you-go; `terraform plan` then showed "No changes", proving state and resources survived |
| 8 | `terraform plan` prompted for `subscription_id` | The gitignored `terraform.tfvars` was not present after reorganizing the repo | Passed it through `TF_VAR_subscription_id` instead of a file |
| 9 | `Module not installed` errors before any plan | New modules must be installed by `terraform init` first | Ran `terraform init`, then re-ran the state backup and plan |
| 10 | New `spokes.auto.tfvars` silently ignored by Git | `.gitignore` excluded all `*.tfvars` | Added the exception `!spokes.auto.tfvars` after the `*.tfvars` line |

The full table with business lessons is in the PDFs.

---

## Skills Demonstrated

Infrastructure as Code (Terraform), Azure hub and spoke networking, VNet peering, NSG design, private endpoints, remote state management, importing existing resources into state, Git hygiene for IaC projects, and written troubleshooting documentation.

**Certifications this supports:** AZ-900 (passed September 24, 2026) and CompTIA Security+. It also lines up with the AZ-104 networking domain, which is the next goal.

---

## Next Steps

- [x] Add an NSG and storage account to the prod spoke
- [x] Refactor into modules with spokes defined as data
- [ ] Add a private DNS zone (`privatelink.blob.core.windows.net`), a VNet link and a DNS zone group so the storage name resolves to the private endpoint IP from inside the VNet
- [ ] Run a timed Bastion and VM demo (flip `enable_vm` and `enable_bastion`, capture screenshots, destroy)
- [ ] Split state per environment so a bad dev apply cannot touch prod
- [ ] Add CI that runs `terraform fmt`, `validate` and `plan` on pull requests

---

## Related Projects

- [Linux to Azure: Automated System Log Backup](https://github.com/MrBSykes/linux-to-azure-automated-syslog-backup)
- [ServiceNow Help Desk Lab](https://github.com/MrBSykes/servicenow-help-desk-lab)

---

*Bryan Sykes | Home Lab Portfolio | 2026*
*[![GitHub](https://img.shields.io/badge/GitHub-MrBSykes-181717?style=flat&logo=github)](https://github.com/MrBSykes) [![X](https://img.shields.io/badge/X-@SecuredByBryan-000000?style=flat&logo=x)](https://x.com/SecuredByBryan)*
