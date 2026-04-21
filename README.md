# XSIAM-LAB-V2

Infrastructure as Code to deploy an XSIAM lab using **Terraform** and **GitHub Actions**..

---

## Description

This repository defines a complete lab environment including:

- Network (VPC, subnets, routing)
- Jumpbox (the only one with Public IP)
- Palo Alto VM-Series Firewall - BYOL - 4 vCPU
- XSIAM components (optional)
  - Broker VM  
  - Engine 
- Virtual machines
  - Windows Server 2022
  - Linux Ubuntu 22.04
  - Kali Linux

The deployment is fully automated and reproducible using Terraform.

---

## Architecture Diagram

![Architecture Diagram](xsiam-lab.png)

## Prerequisites

### AWS

An AWS account with permissions to create:

- EC2
- VPC
- Subnets
- Security Groups
- Route Tables
- Internet Gateway
- Elastic IP
- S3 (for backend)

Once you have the AWS account, you must manually create and configure:

- EC2 Key Pair (download the private key) (`SSH_KEY_NAME`)
- S3 Bucket for Terraform Backend (`S3_BACKEND`) - example name `<your-name>-xsiam-lab-tf-state`
- AWS Access Key / AWS Secret Access Key
- Accept EULA for Palo Alto Networks VM-Series: [AWS Marketplace EULA Palo Alto Networks](https://aws.amazon.com/marketplace/pp?sku=6njl1pau431dv1qxipg63mvah)
- Accept EULA for Kali Linux (if apply): [AWS Marketplace EULA Kali Linux](https://aws.amazon.com/marketplace/pp?sku=7lgvy7mt78lgoi4lant0znp5h)

Tools we use:

- AWS CLI - [Install here](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html)
- Visual Studio Code - [Install here](https://code.visualstudio.com/download)
- Github Desktop - [Install here](https://desktop.github.com/download/)

You will also need a GitHub account and fork this repository.

Then go to:

**Settings → Secrets and Variables → Actions**

Create the following:

**GitHub Secrets**
| Variable | Description | Example / Allowed Values |
|----------|-------------|--------------------------|
| `AWS_ACCESS_KEY_ID` | AWS Access Key | `****` |
| `AWS_SECRET_ACCESS_KEY` | AWS Accress Secret Key | `****` |
| `CORTEX_API_KEY` | Cortex API Key | `****` |
| `CORTEX_API_KEY_ID` | Cortex API Key ID | `****` |

**GitHub Variables**

| Variable | Description | Example / Allowed Values |
|----------|-------------|--------------------------|
| `AWS_REGION` | AWS region where resources will be deployed | `us-east-2` |
| `DEPLOYMENT_NAME` | Prefix used for naming all resources | `davila-xsiam-lab` |
| `AUTHCODES` | Authcode for VM-Series Licensing from Customer Support Portal | `D681112X` |
| `GLOBAL_TAGS` | Resource tag for application name | `{ ManagedBy = "terraform", Application = "XSIAM Lab", Owner = "David Avila" }` |
| `SSH_KEY_NAME` | SSH key pair name for EC2 access | `xsiam-lab-v2` |
| `MGT_PUBLIC_IP` | Allowed public IPs for management access | `["YOUR PUBLIC IP ADDRESS"]` |
| `S3_BACKEND` | S3 Backend | `davila-s3-tf-state` |

---

## Repository Structure

```text
.
├── .github/
│   └── workflows/
│       └── xsiam-lab.yaml
├── infra/
│   ├── files/
│   ├── modules/
│   ├── 0_network.tf
│   ├── 1_jumpbox.tf
│   ├── 2_fw.tf
│   ├── 3_xsiam_components.tf
│   ├── 4_vms.tf
│   ├── backend.tf
│   ├── configuration.json
│   ├── data_sources.tf
│   ├── outputs.tf
│   ├── terraform.tfvars
│   ├── variables.tf
│   └── versions.tf
├── .gitignore
└── README.md
```

## Variables

Defined in **infra/terraform.tfvars**, you need to update the following values:

| Variable | Description | Example / Allowed Values |
|----------|-------------|--------------------------|
| `cidr` | CIDR block for the VPC | `10.10.0.0/16` |
| `broker_vm` | Deploy Broker VM | `true / false` |
| `broker_vm_key` | VMDK file name for Broker VM | `"file.vmdk"` |
| `broker_vm_subnet` | Subnet for Broker VM | `vlan1 / vlan2` |
| `engine_vm` | Deploy Engine VM | `true / false` |
| `engine_vm_subnet` | Subnet for Engine VM | `vlan1 / vlan2` |
| `linux_deploy` | Deploy Linux VM | `true / false` |
| `windows_server_deploy` | Deploy Windows Server VM | `true / false` |
| `kali_deploy` | Deploy Kali Linux VM | `true / false` |
| `create_public_ip_mgmt` | Create Public IP on VM-Series | `true / false` |

---

## Broker VM Deployment (VMDK → AMI)

Follow these steps to deploy the Broker VM:

### Step 1 — Download VMDK

- Download the Broker VM `.vmdk` file from your XSIAM tenant.

- Place the file inside the `infra/` directory.

---

### Step 2 — Update Variables

Edit `infra/terraform.tfvars`:

```hcl
broker_vm     = true
broker_vm_key = "your-vmdk-file-name.vmdk"
```

### Step 3 — Execute de Github Actions (terraform apply)

Terraform will:

- Create required resources (S3, IAM roles, etc.)
- Prepare the environment for VM import
- Generate required AWS CLI commands

### Step 4 — Import VMDK to AMI

After execution, Terraform outputs will include AWS CLI commands. Run them locally to:

- Upload the VMDK
- Import it as an AMI

### Step 5 — Verify AMI
- Go to EC2 → AMIs
- Validate the image is available

### Broker VM Documentation

[Set up Broker VM on AWS (XSIAM Documentation)](https://docs-cortex.paloaltonetworks.com/r/Cortex-XSIAM/Cortex-XSIAM-Documentation/Set-up-Broker-VM-on-Amazon-Web-Services)

## Security

- Do not commit .pem files
- Do not hardcode credentials
- Prefer IAM roles over static keys
- Rotate credentials regularly