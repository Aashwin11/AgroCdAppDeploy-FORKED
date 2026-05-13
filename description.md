# AgroCdAppDeploy - Complete Technical Deep-Dive

**Project Name:** AgroCdAppDeploy  
**Branch:** `applicationsetup-Aniket-ArgoRollout-BG`  
**Repository:** https://github.com/Aashwin11/AgroCdAppDeploy-FORKED.git  
**Last Updated:** May 13, 2026

---

## Table of Contents

1. [Project Overview](#project-overview)
2. [Architecture & Structure](#architecture--structure)
3. [End-to-End System Flow](#end-to-end-system-flow)
4. [Technical Implementation](#technical-implementation)
5. [Component Glossary](#component-glossary)
6. [Deployment Logic: Blue-Green Rollouts](#deployment-logic-blue-green-rollouts)
7. [Critical YAML Parameters Explained](#critical-yaml-parameters-explained)

---

## Project Overview

### Primary Objective

This repository implements a **complete end-to-end DevOps deployment pipeline** for a Python-based currency converter service. The work in this branch focuses on:

- Infrastructure automation (AWS VPC, EKS, NAT, IAM)
- Kubernetes deployment architecture with progressive delivery
- GitOps application delivery via ArgoCD
- Service exposure through AWS networking
- Robust CI/CD automation using GitHub Actions
- Blue-green deployment strategy with Argo Rollouts

**Critical Point:** The core objective is to demonstrate a **professional DevOps implementation**, not to develop the application itself. The currency converter application is a deployable target to showcase infrastructure, orchestration, and deployment automation excellence.

### Core Design Philosophy

- **Single Source of Truth**: Git repository drives all cluster state
- **Declarative Everything**: Infrastructure as Code (Terraform), manifests as YAML/Kustomize
- **Automation First**: GitHub Actions orchestrates all lifecycle events
- **Progressive Delivery**: Blue-green strategy prevents production impact of new versions
- **Safe Releases**: Manual promotion gates prevent automated traffic switches
- **Environment Isolation**: Separate overlays for production vs development
- **GitOps Native**: ArgoCD continuously reconciles cluster state with Git

### Key Technologies

| Technology | Role | Purpose |
|-----------|------|---------|
| **Terraform** | Infrastructure Automation | AWS VPC, EKS, IAM, NAT provisioning |
| **AWS EKS** | Kubernetes Distribution | Managed Kubernetes on AWS |
| **Kustomize** | Template Management | Environment-specific manifest variations |
| **Argo Rollouts** | Progressive Delivery | Blue-green deployment orchestration |
| **ArgoCD** | GitOps Controller | Continuous reconciliation of Git → Cluster |
| **GitHub Actions** | CI/CD Orchestration | Workflow automation, infrastructure provisioning |
| **AWS ALB** | Ingress Controller | External traffic routing and load balancing |
| **Python Flask** | Application Framework | Currency converter web service |
| **Docker** | Containerization | Application packaging and distribution |

---

## Architecture & Structure

### Repository Directory Hierarchy

```
AgroCdAppDeploy-FORKED/
│
├── infrastructure/                          # ✅ AWS Infrastructure as Code (Terraform)
│   ├── main.tf                             # VPC and EKS module orchestration
│   ├── providers.tf                        # Terraform provider configuration
│   ├── variables.tf                        # Input variables (region, cluster version, etc.)
│   ├── backend.tf                          # S3 state backend (injected by CI/CD)
│   ├── outputs.tf                          # Cluster endpoint, CA certificate exports
│   │
│   └── modules/
│       ├── vpc/                            # AWS VPC Module
│       │   ├── main.tf                     # VPC, subnets, NAT, Internet Gateway
│       │   ├── outputs.tf                  # Subnet IDs, VPC ID exports
│       │   └── variables.tf                # CIDR blocks, AZ configuration
│       │
│       └── eks/                            # AWS EKS Module
│           ├── main.tf                     # Cluster role, node role, cluster definition
│           ├── outputs.tf                  # Cluster endpoint, CA certificate
│           └── variables.tf                # Cluster version, instance types
│
├── k8s-kustomize/                          # ✅ Kubernetes Manifests (Kustomize-based)
│   ├── base/                               # Base resources (applied to all environments)
│   │   ├── rollout.yaml                    # Argo Rollouts resource (blue-green)
│   │   ├── active-service.yaml             # Production traffic service
│   │   ├── preview-service.yaml            # QA/staging traffic service
│   │   ├── ingress.yaml                    # Production ingress (app.trialphase.shop)
│   │   ├── preview-ingress.yaml            # Preview ingress (appdev.trialphase.shop)
│   │   ├── secret.yaml                     # API credentials (base64-encoded)
│   │   └── kustomization.yaml              # Base Kustomize configuration
│   │
│   └── overlays/                           # Environment-specific customizations
│       ├── production/                     # Production overlay
│       │   ├── kustomization.yaml          # Includes base, applies patches
│       │   └── image-patch.yaml            # Production ECR image patch
│       │
│       └── development/                    # Development overlay
│           ├── kustomization.yaml          # Includes base, applies patches
│           ├── deployment-patch.yaml       # Dev environment variables
│           └── ingress-patch.json          # Dev hostname patches
│
├── argocd/                                 # ✅ ArgoCD Applications (GitOps)
│   ├── argocd.yaml                        # Self-managed ArgoCD application
│   └── currencyconverter.yaml             # Currency converter production app
│
├── kubernetes-manifests/                   # ✅ Additional Kubernetes Resources
│   └── argocd-ingress.yaml                # ALB ingress for ArgoCD external access
│
├── .github/workflows/                      # ✅ GitHub Actions CI/CD Automation
│   ├── 1-terraform-infra.yml              # Provision/destroy AWS infrastructure
│   ├── 2-apply-to-eks.yml                 # Deploy ArgoCD, ALB, Argo Rollouts
│   ├── 3-remove-from-eks.yml              # Clean up Kubernetes deployments
│   ├── 5-terraform-statelock.yaml         # Force-unlock stuck Terraform state
│   ├── 6-deployment-switch.yaml           # Flip blue/green via GitOps
│   ├── 7-promote-rollout.yaml             # Promote preview to active
│   └── test-workflow.yaml                 # Validate EKS connectivity
│
├── app/                                    # ✅ Python Flask Application
│   ├── app.py                             # Flask app with /convert route [implied]
│   └── requirements.txt                    # Python dependencies
│
├── static/                                 # ✅ Frontend Assets
│   └── js/
│       └── app.js                         # Form handling and API calls
│
├── templates/                              # ✅ HTML Templates
│   └── index.html                         # Currency converter UI
│
├── tests/                                  # ✅ Unit Tests
│   └── test_app.py                        # Flask route tests
│
├── Dockerfile                              # ✅ Container Image Definition
├── .dockerignore                           # Docker build exclusions
├── .gitignore                              # Git exclusions
├── requirements.txt                        # Python dependencies (Flask, requests)
├── explanation.txt                         # Project documentation
└── description.md                          # This file
```

### Directory Responsibility Matrix

| Directory | Primary Owner | Responsibility | Deployment Target |
|-----------|---------------|-----------------|-------------------|
| `infrastructure/` | DevOps/SRE | AWS IaC via Terraform | AWS Account |
| `k8s-kustomize/base/` | Platform/DevOps | Base K8s manifests | All environments |
| `k8s-kustomize/overlays/` | DevOps/SRE | Environment customization | Per-environment |
| `argocd/` | DevOps/SRE | GitOps source of truth | EKS Cluster |
| `.github/workflows/` | DevOps/CI | Orchestration automation | GitHub Actions |
| `app/` | Developers | Application code | Docker image |

---

## End-to-End System Flow

### Complete Journey: From Git Commit to Production Blue-Green Switch

#### **Phase 1: Infrastructure Provisioning (One-Time Setup)**

```
┌─────────────────────────────────────────────────────────────┐
│ PHASE 1: INFRASTRUCTURE PROVISIONING                        │
├─────────────────────────────────────────────────────────────┤
│                                                               │
│ Developer Action: Trigger GitHub Action                     │
│ "1-Terraform EKS Manual Deploy" with action: "apply"       │
│                      ↓                                       │
│ GitHub Actions Runner (ubuntu-latest) executes:            │
│                      ↓                                       │
│ [1] Checkout repository (branch: applicationsetup-...)     │
│ [2] Configure AWS credentials from GitHub Secrets          │
│ [3] Install Terraform 1.6.0                                │
│ [4] Initialize Terraform backend:                          │
│     - S3 bucket for state                                  │
│     - DynamoDB table for locking                           │
│ [5] Generate my-vars.tfvars.json with:                     │
│     - AWS region, project name, instance types             │
│     - CREATOR_ARN (IAM ARN of runner)                       │
│ [6] Execute: terraform validate → plan → apply            │
│                      ↓                                       │
│ AWS Resources Created:                                      │
│ ├─ VPC (10.0.0.0/16)                                       │
│ ├─ Public subnets (10.0.1.0/24, 10.0.2.0/24)             │
│ ├─ Private subnets (10.0.101.0/24, 10.0.102.0/24)        │
│ ├─ Internet Gateway (route: 0.0.0.0/0 → IGW)             │
│ ├─ NAT Gateway (private subnets → internet via NAT)        │
│ ├─ EKS Cluster (in private subnets)                        │
│ ├─ Node Group (desired: 2, min: 1, max: 3)               │
│ ├─ IAM Roles (cluster-role, node-role)                    │
│ └─ aws-auth ConfigMap (maps CREATOR_ARN → system:masters) │
│                      ↓                                       │
│ [7] Terraform State stored in S3 with DynamoDB locking    │
│                      ↓                                       │
│ Result: ✅ EKS cluster operational, accessible via        │
│            aws eks update-kubeconfig                        │
│                                                               │
└─────────────────────────────────────────────────────────────┘
```

**Key Terraform Components:**

- **providers.tf**: AWS, Kubernetes (exec auth via aws eks get-token), Helm
- **modules/vpc/main.tf**: VPC, subnets, NAT, Internet Gateway, route tables
- **modules/eks/main.tf**: Cluster role, node role, EKS cluster, node group
- **main.tf**: aws-auth ConfigMap (IAM → Kubernetes RBAC mapping)
- **variables.tf**: Region, project name, instance types, cluster version, cluster_creator_arn
- **backend.tf**: S3 state bucket, DynamoDB lock table (injected dynamically)

**State Management:**
- Remote state in S3 prevents local state conflicts
- DynamoDB locking prevents concurrent applies
- Workflow `5-terraform-statelock.yaml` can force-unlock stuck states

---

#### **Phase 2: Cluster Deployment (Install Controllers & Platforms)**

```
┌─────────────────────────────────────────────────────────────┐
│ PHASE 2: CLUSTER DEPLOYMENT                                 │
├─────────────────────────────────────────────────────────────┤
│                                                               │
│ Developer Action: Trigger GitHub Action                     │
│ "2-Deploy Apps to EKS" with cluster name and region       │
│                      ↓                                       │
│ GitHub Actions Runner executes sequentially:               │
│                      ↓                                       │
│ [1] AWS Auth: Configure credentials, verify caller        │
│ [2] Tools: Install eksctl, kubectl argo-rollouts plugin   │
│ [3] K8s Connect: Update kubeconfig, verify nodes           │
│ [4] ALB Policy: Create IAM policy (if doesn't exist)       │
│ [5] OIDC: Associate OIDC provider (enables IRSA)           │
│ [6] IRSA: Create IAM Service Account for ALB Controller    │
│ [7] Argo Rollouts: Install controller namespace            │
│ [8] ALB Controller: Install via Helm (with IRSA)           │
│ [9] ArgoCD: Install via Helm (namespace: argocd)           │
│ [10] Ingress: Apply ArgoCD ingress manifest                │
│ [11] GitOps: Apply ArgoCD Application manifests            │
│ [12] Wait: Polling for ALB provisioning                    │
│ [13] Output: ArgoCD admin credentials                      │
│                      ↓                                       │
│ Kubernetes Resources Installed:                             │
│ ├─ argo-rollouts namespace (Argo Rollouts controller)      │
│ ├─ kube-system ns (ALB Controller, aws-load-balancer-*)   │
│ ├─ argocd namespace (ArgoCD server, repo-server, etc.)     │
│ └─ default namespace (ready for app deployment)            │
│                      ↓                                       │
│ AWS Load Balancer Controller:                              │
│ ├─ Watches for Ingress resources                           │
│ ├─ Provisions Application Load Balancers (ALBs)            │
│ ├─ Uses IRSA (IAM role attached to service account)        │
│ └─ Annotations drive ALB configuration (internet-facing)  │
│                      ↓                                       │
│ Argo Rollouts Controller:                                  │
│ ├─ Watches for Rollout resources                           │
│ ├─ Manages blue-green deployments                          │
│ ├─ Orchestrates ReplicaSet promotions                      │
│ └─ Enables manual/automatic traffic switches               │
│                      ↓                                       │
│ ArgoCD Installation:                                        │
│ ├─ Server component (UI, API)                              │
│ ├─ Repository server (Git interaction)                     │
│ ├─ Application controller (reconciliation loop)             │
│ └─ Ingress created (ALB provision begins)                  │
│                      ↓                                       │
│ Result: ✅ All control planes operational                  │
│         ✅ ALB hostname ready: argocd.trialphase.shop     │
│         ✅ ArgoCD credentials available                    │
│         ✅ Ready for application deployment                │
│                                                               │
└─────────────────────────────────────────────────────────────┘
```

**What Each Component Does:**

- **ALB Controller**: Listens for Ingress resources, creates AWS ALBs automatically
- **Argo Rollouts**: Manages blue-green transitions, pod selector management
- **ArgoCD**: Watches Git, applies manifests via Kustomize, continuous reconciliation

---

#### **Phase 3: Application Deployment (GitOps Reconciliation)**

```
┌─────────────────────────────────────────────────────────────┐
│ PHASE 3: APPLICATION DEPLOYMENT                             │
├─────────────────────────────────────────────────────────────┤
│                                                               │
│ Git Event: Developer commits new image or manifest          │
│            Pushes to applicationsetup-Aniket-ArgoRollout-BG│
│                      ↓                                       │
│ ArgoCD Polling (every ~3 seconds):                          │
│ ├─ Detects change in:                                      │
│ │  - argocd/ directory                                     │
│ │  - k8s-kustomize/overlays/production/ directory         │
│ └─ Triggers sync                                            │
│                      ↓                                       │
│ Manifest Build Phase:                                       │
│ ├─ Read: k8s-kustomize/overlays/production/kustomization  │
│ ├─ Include: ../../base (all base resources)                │
│ ├─ Apply patch: image-patch.yaml (production ECR image)   │
│ ├─ Build: Rollout, Services, Ingress, Secret              │
│ └─ Output: Complete manifest ready to apply               │
│                      ↓                                       │
│ Reconciliation Phase:                                       │
│ ├─ Compare: Git manifests vs Cluster resources             │
│ ├─ Identify: Additions, modifications, deletions           │
│ ├─ syncPolicy enforcement:                                 │
│ │  - automated: true (auto-sync enabled)                   │
│ │  - selfHeal: true (drift correction enabled)             │
│ │  - prune: true (deleted resources removed)               │
│ └─ Apply differences to cluster                            │
│                      ↓                                       │
│ Result: New Rollout resource created                       │
│                      ↓                                       │
│ Status: ✅ Git = Cluster state (reconciled)               │
│                                                               │
└─────────────────────────────────────────────────────────────┘
```

---

#### **Phase 4: Blue-Green Orchestration (Argo Rollouts)**

```
┌─────────────────────────────────────────────────────────────┐
│ PHASE 4: BLUE-GREEN ORCHESTRATION                           │
├─────────────────────────────────────────────────────────────┤
│                                                               │
│ Argo Rollouts Controller Watches: Rollout resource          │
│                      ↓                                       │
│ Detection: Image changed (v1 → v2)                         │
│                      ↓                                       │
│ STEP 1: Create New ReplicaSet (v2)                         │
│ ├─ Launch pods with new image                              │
│ ├─ NOT selected by any service yet                         │
│ ├─ Wait for readiness probes                               │
│ └─ Status: "Progressing"                                   │
│                      ↓                                       │
│ STEP 2: Blue-Green Selector Management                     │
│ ├─ activeService selector: STILL points to v1 ReplicaSet  │
│ ├─ previewService selector: SWITCHED to v2 ReplicaSet     │
│ └─ Result:                                                  │
│     ACTIVE (v1): Production traffic → v1 pods              │
│     PREVIEW (v2): Staging traffic → v2 pods                │
│                      ↓                                       │
│ Current Traffic State:                                      │
│ ┌─────────────────────────────────────────┐               │
│ │ PRODUCTION (app.trialphase.shop)       │               │
│ │ → ALB → active-service → v1 pods       │               │
│ │ (LIVE TRAFFIC - UNCHANGED)             │               │
│ ├─────────────────────────────────────────┤               │
│ │ STAGING (appdev.trialphase.shop)       │               │
│ │ → ALB → preview-service → v2 pods      │               │
│ │ (QA/TESTING - NEW VERSION)             │               │
│ └─────────────────────────────────────────┘               │
│                      ↓                                       │
│ Status: ✅ autoPromotionEnabled: false                    │
│         ✅ Waiting for manual promotion                   │
│         ✅ QA validates v2 at appdev.trialphase.shop    │
│                                                               │
└─────────────────────────────────────────────────────────────┘
```

---

#### **Phase 5: Manual Promotion (Traffic Switch to Production)**

```
┌──────────────────────────────────────────────────────────────┐
│ PHASE 5: MANUAL PROMOTION                                    │
├──────────────────────────────────────────────────────────────┤
│                                                                │
│ QA Validation: Confirmed v2 works correctly at appdev URL   │
│                      ↓                                        │
│ METHOD A: kubectl argo rollouts promote (Direct API)       │
│           OR                                                  │
│ METHOD B: 6-deployment-switch.yaml (GitOps path flip)     │
│                      ↓                                        │
│ ┌─ METHOD A FLOW ────────────────────────────────────────┐ │
│ │                                                          │ │
│ │ Developer Action: Trigger "7-Promote Rollout" workflow │ │
│ │                      ↓                                  │ │
│ │ GitHub Actions:                                        │ │
│ │ ├─ Install kubectl argo-rollouts CLI                  │ │
│ │ ├─ Connect to EKS cluster                              │ │
│ │ ├─ Execute: kubectl argo rollouts promote              │ │
│ │ │           currency-converter -n default              │ │
│ │ └─ Argo Rollouts Controller updates selectors:         │ │
│ │    - activeService NOW points to v2 ReplicaSet        │ │
│ │    - previewService NOW points to v1 ReplicaSet       │ │
│ │                      ↓                                  │ │
│ │ Result: LIVE TRAFFIC SWITCHES TO v2                    │ │
│ │                                                          │ │
│ └──────────────────────────────────────────────────────────┘ │
│                      ↓                                        │
│ ┌─ METHOD B FLOW ────────────────────────────────────────┐ │
│ │                                                          │ │
│ │ Developer Action: Trigger "6-Deployment Switch"        │ │
│ │                      ↓                                  │ │
│ │ Workflow Steps:                                        │ │
│ │ ├─ [1] Checkout repo with PAT                          │ │
│ │ ├─ [2] Check path in argocd/currencyconverter.yaml    │ │
│ │ │       Current: "production/blue" or "production/green"
│ │ ├─ [3] Flip path: sed 's|production/blue|production/ │ │
│ │ │       green|' argocd/currencyconverter.yaml          │ │
│ │ ├─ [4] Commit: "Automated Flip: Switched to GREEN"    │ │
│ │ ├─ [5] Push to Git branch                              │ │
│ │ │                      ↓                                │ │
│ │ │ ArgoCD Detects Change:                               │ │
│ │ │ ├─ New path: k8s-kustomize/overlays/production/green│
│ │ │ ├─ Different image in green vs blue                  │ │
│ │ │ ├─ Rebuild manifests, apply changes                  │ │
│ │ │ └─ Rollout updated, traffic flips                    │ │
│ │                                                          │ │
│ │ Result: LIVE TRAFFIC SWITCHES TO v2 (via GitOps)      │ │
│ │                                                          │ │
│ └──────────────────────────────────────────────────────────┘ │
│                      ↓                                        │
│ New Traffic State (After Either Method):                     │
│ ┌──────────────────────────────────────────┐                │
│ │ PRODUCTION (app.trialphase.shop)        │                │
│ │ → ALB → active-service → v2 pods        │                │
│ │ (LIVE TRAFFIC - NOW v2!)                │                │
│ ├──────────────────────────────────────────┤                │
│ │ STAGING (appdev.trialphase.shop)        │                │
│ │ → ALB → preview-service → v1 pods       │                │
│ │ (READY FOR NEXT VERSION)                │                │
│ └──────────────────────────────────────────┘                │
│                      ↓                                        │
│ Status: ✅ Traffic switched to v2                          │
│         ✅ Zero downtime                                    │
│         ✅ v1 pods still running (instant rollback)         │
│         ✅ Audit trail in Git (6-method) or kubectl logs   │
│                                                                │
└──────────────────────────────────────────────────────────────┘
```

---

#### **Phase 6: Rollback (If Needed)**

```
┌─────────────────────────────────────────────────────────────┐
│ PHASE 6: ROLLBACK (INSTANT, ZERO DOWNTIME)                 │
├─────────────────────────────────────────────────────────────┤
│                                                               │
│ Issue Detected: v2 has performance problems                 │
│                      ↓                                       │
│ Option A: kubectl argo rollouts promote (again)            │
│ ├─ activeService → v1 ReplicaSet (previous)                │
│ ├─ previewService → v2 ReplicaSet (for testing)            │
│ └─ Result: Production traffic back to v1 INSTANTLY         │
│                      ↓                                       │
│ Option B: Git revert (if using GitOps path flip)           │
│ ├─ git revert commit                                        │
│ ├─ Commit: "Revert: Rolled back to BLUE"                   │
│ ├─ Push to Git                                              │
│ ├─ ArgoCD detects path change                               │
│ └─ Result: Production traffic back to v1 (via GitOps)      │
│                      ↓                                       │
│ Time to Rollback: < 10 seconds                             │
│ Downtime: ZERO (v1 pods never stopped running)             │
│ Audit Trail: Git history or kubectl events                 │
│                                                               │
│ Status: ✅ Safe rollback always available                  │
│         ✅ Old version pods maintained during test         │
│         ✅ No cold start or image pull delays              │
│                                                               │
└─────────────────────────────────────────────────────────────┘
```

---

#### **Phase 7: Cleanup (Infrastructure Teardown)**

```
┌─────────────────────────────────────────────────────────────┐
│ PHASE 7: CLEANUP (INFRASTRUCTURE TEARDOWN)                 │
├─────────────────────────────────────────────────────────────┤
│                                                               │
│ Option 1: Destroy Infrastructure                           │
│ ├─ Trigger: "1-Terraform EKS Manual Deploy" (action: destroy)
│ ├─ Execution:                                               │
│ │  - terraform destroy -auto-approve                       │
│ │  - Removes: EKS, VPC, subnets, NAT, IGW, IAM roles      │
│ │  - Preserves: Terraform state in S3 (for audit)         │
│ └─ Result: All AWS resources deleted                       │
│                      ↓                                       │
│ Option 2: Remove Applications Only                         │
│ ├─ Trigger: "3-Remove Apps from EKS"                      │
│ ├─ Execution:                                               │
│ │  - kubectl delete app --all -n argocd                    │
│ │  - helm uninstall argocd                                 │
│ │  - helm uninstall aws-load-balancer-controller           │
│ │  - Detach ALB IAM policy from node role                  │
│ └─ Result: Cluster remains, applications removed           │
│                      ↓                                       │
│ Final State: ✅ Infrastructure clean                       │
│             ✅ AWS costs minimized                          │
│             ✅ Terraform state preserved in S3             │
│                                                               │
└─────────────────────────────────────────────────────────────┘
```

---

## Technical Implementation

### 1. Infrastructure Automation: Terraform

#### Overview

Terraform provisions the complete AWS infrastructure using a modular approach:
- **Root module** (`main.tf`): Orchestrates VPC and EKS modules
- **VPC module**: Network infrastructure (VPC, subnets, NAT, routing)
- **EKS module**: Kubernetes cluster, node groups, IAM roles
- **Providers**: AWS, Kubernetes (exec auth), Helm

#### Key Files and Their Purposes

**providers.tf** - Provider Configuration

```hcl
terraform {
  required_providers {
    aws = { source = "hashicorp/aws", version = ">= 4.0" }
    kubernetes = { source = "hashicorp/kubernetes", version = ">= 2.0" }
    helm = { source = "hashicorp/helm", version = ">= 2.0" }
  }
}

provider "aws" { region = var.aws_region }

provider "kubernetes" {
  host                   = module.eks.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks.cluster_ca_certificate)
  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "aws"
    args        = ["eks", "get-token", "--cluster-name", module.eks.cluster_name]
  }
}

provider "helm" { ... similar exec auth ... }
```

**Why This Matters:**
- **exec auth**: Uses IAM credentials dynamically (no kubeconfig file)
- **Kubernetes provider**: Enables Terraform to manage K8s resources (ConfigMaps, namespaces)
- **Helm provider**: Installs charts directly from Terraform (GitOps infrastructure)

---

**modules/vpc/main.tf** - Network Infrastructure

```hcl
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr  # 10.0.0.0/16
  enable_dns_hostnames = true
  enable_dns_support   = true
}

# Public Subnets (ALB, NAT Gateway reside here)
resource "aws_subnet" "public" {
  count                   = length(var.public_subnet_cidrs)
  cidr_block              = var.public_subnet_cidrs[count.index]
  map_public_ip_on_launch = true
  tags = {
    "kubernetes.io/role/elb"                   = "1"
    "kubernetes.io/cluster/${var.project_name}" = "owned"
  }
}

# Private Subnets (EKS nodes reside here)
resource "aws_subnet" "private" {
  count  = length(var.private_subnet_cidrs)
  cidr_block = var.private_subnet_cidrs[count.index]
  tags = {
    "kubernetes.io/role/internal-elb"               = "1"
    "kubernetes.io/cluster/${var.project_name}"      = "owned"
  }
}

# NAT Gateway (private subnets → internet)
resource "aws_nat_gateway" "nat_gw" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public[0].id
}

# Route Tables
resource "aws_route_table" "public_rt" {
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id  # Via IGW
  }
}

resource "aws_route_table" "private_rt" {
  route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat_gw.id  # Via NAT
  }
}
```

**Why This Matters:**
- **Public subnets**: ALB and NAT Gateway positioned for internet access
- **Private subnets**: EKS nodes protected from direct internet exposure
- **Kubernetes tags**: Enable AWS Load Balancer Controller to discover subnets
- **NAT Gateway**: Allows private pods to call external APIs securely

---

**modules/eks/main.tf** - Kubernetes Cluster

```hcl
# IAM Role for Cluster Control Plane
resource "aws_iam_role" "cluster_role" {
  assume_role_policy = jsonencode({
    Statement = [{
      Action    = "sts:AssumeRole"
      Principal = { Service = "eks.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "cluster_policy" {
  role       = aws_iam_role.cluster_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}

# EKS Cluster
resource "aws_eks_cluster" "main" {
  name     = var.project_name
  role_arn = aws_iam_role.cluster_role.arn
  version  = var.cluster_version

  vpc_config {
    subnet_ids = var.private_subnet_ids  # Only private subnets
  }

  access_config {
    authentication_mode                         = "API"
    bootstrap_cluster_creator_admin_permissions = true  # CRITICAL
  }
}

# IAM Role for Worker Nodes
resource "aws_iam_role" "node_role" {
  assume_role_policy = jsonencode({
    Statement = [{
      Action    = "sts:AssumeRole"
      Principal = { Service = "ec2.amazonaws.com" }
    }]
  })
}

# Attach required node policies
resource "aws_iam_role_policy_attachment" "node_worker_policy" {
  role       = aws_iam_role.node_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
}

resource "aws_iam_role_policy_attachment" "node_cni_policy" {
  role       = aws_iam_role.node_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
}

resource "aws_iam_role_policy_attachment" "node_ecr_policy" {
  role       = aws_iam_role.node_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

# EKS Node Group
resource "aws_eks_node_group" "main" {
  cluster_name    = aws_eks_cluster.main.name
  node_role_arn   = aws_iam_role.node_role.arn
  subnet_ids      = var.private_subnet_ids

  scaling_config {
    desired_size = 2
    max_size     = 3
    min_size     = 1
  }

  lifecycle {
    ignore_changes = [scaling_config[0].desired_size]  # Let Cluster Autoscaler manage
  }
}
```

**Why This Matters:**
- **bootstrap_cluster_creator_admin_permissions: true**: Auto-grants cluster creator RBAC admin (no manual aws-auth update needed)
- **Private subnets only**: Nodes not directly internet-accessible (secure)
- **Node policies**: Worker nodes can pull images (ECR), manage networking (CNI)
- **ignore_changes on desired_size**: Allows external autoscaling tools to manage

---

**main.tf** - aws-auth ConfigMap (RBAC Mapping)

```hcl
resource "kubernetes_config_map_v1" "aws_auth" {
  metadata {
    name      = "aws-auth"
    namespace = "kube-system"
  }

  data = {
    "mapRoles" = yamlencode([
      {
        rolearn  = module.eks.node_role_arn
        username = "system:node:{{EC2PrivateDNSName}}"
        groups   = ["system:bootstrappers", "system:nodes"]
      }
    ])

    "mapUsers" = yamlencode([
      {
        userarn  = var.cluster_creator_arn  # From GitHub Actions workflow
        username = split("/", var.cluster_creator_arn)[1]  # Extract username
        groups   = ["system:masters"]  # Full admin access
      }
    ])
  }

  depends_on = [module.eks]
}
```

**Why This Matters:**
- **mapRoles**: Registers EC2 node role (allows nodes to join cluster)
- **mapUsers**: Registers IAM user running workflow (allows local kubectl admin access)
- **system:masters group**: Full Kubernetes admin permissions
- **Dynamic ARN handling**: Works with any IAM user running workflow (no hardcoding)

---

**variables.tf** - Input Configuration

```hcl
variable "aws_region" {
  description = "AWS region for the infrastructure"
  type        = string
  default     = "us-east-2"
}

variable "project_name" {
  description = "Unique project name for resource tagging"
  type        = string
  default     = "staging-eks-demo"
}

variable "instance_types" {
  description = "EC2 instance types for node group"
  type        = list(string)
  default     = ["t3.medium"]
}

variable "cluster_version" {
  description = "Kubernetes version for EKS"
  type        = string
  default     = "1.31"
}

variable "cluster_creator_arn" {
  description = "ARN of IAM entity creating the cluster (for aws-auth)"
  type        = string
  # No default - must be provided by workflow
}
```

---

**backend.tf** - Remote State Configuration (Injected by CI/CD)

```hcl
terraform {
  backend "s3" {
    # These values are injected by GitHub Actions workflow
    # terraform init -backend-config="bucket=..." -backend-config="key=..."
    # Do NOT hardcode credentials here
  }
}
```

**Workflow Injection (from 1-terraform-infra.yml):**

```bash
terraform init \
  -backend-config="bucket=${{ github.event.inputs.tf_state_bucket }}" \
  -backend-config="key=staging/${{ github.event.inputs.project_name }}/terraform.tfstate" \
  -backend-config="region=${{ github.event.inputs.aws_region }}" \
  -backend-config="dynamodb_table=${{ github.event.inputs.tf_lock_table }}"
```

**Why This Matters:**
- **Dynamic backend**: Different projects/regions use different S3 prefixes
- **DynamoDB locking**: Prevents concurrent applies in shared environments
- **No hardcoded credentials**: Uses GitHub Actions IAM role (temporary credentials)

---

### 2. Kubernetes Architecture: Kustomize & Argo Rollouts

#### Overview

Kubernetes manifests are organized using Kustomize:
- **Base**: Common resources for all environments (Rollout, services, ingress)
- **Overlays**: Environment-specific patches (image, hostnames, replicas)

#### Base Resources (`k8s-kustomize/base/`)

**rollout.yaml** - Progressive Delivery Definition

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Rollout
metadata:
  name: currency-converter
  namespace: default
spec:
  replicas: 1

  selector:
    matchLabels:
      app: currency-converter

  template:
    metadata:
      labels:
        app: currency-converter
    spec:
      containers:
      - name: currency-converter
        image: 538153606685.dkr.ecr.us-east-1.amazonaws.com/currencyconverter:v1
        ports:
        - containerPort: 5555
        env:
        - name: APIKEY
          valueFrom:
            secretKeyRef:
              name: api-keys
              key: APIKEY
        - name: APIHOST
          value: "currency-conversion-and-exchange-rates.p.rapidapi.com"
        - name: FLASK_ENV
          value: "development"

  # Blue-Green Strategy Definition
  strategy:
    blueGreen:
      activeService: currency-converter-active-svc
      previewService: currency-converter-preview-svc
      autoPromotionEnabled: false  # CRITICAL: Manual promotion required
      autoPromotionSeconds: 300    # Only used if autoPromotionEnabled: true
```

**Field Explanations:**

| Field | Purpose | Value |
|-------|---------|-------|
| `activeService` | Service for LIVE production traffic | `currency-converter-active-svc` |
| `previewService` | Service for testing new versions | `currency-converter-preview-svc` |
| `autoPromotionEnabled` | Auto-flip traffic when healthy? | `false` (manual only) |
| `autoPromotionSeconds` | Wait time before auto-promotion | Ignored (false) |

**Pod Selector Behavior:**

The Rollout controller manages pod selectors dynamically:

```
BEFORE PROMOTION:
├── activeService selector: 
│   └── app: currency-converter
│       argo-rollouts-pod-template-hash: abc123  (v1 pods)
│
└── previewService selector:
    └── app: currency-converter
        argo-rollouts-pod-template-hash: def456  (v2 pods)

AFTER PROMOTION:
├── activeService selector:
│   └── app: currency-converter
│       argo-rollouts-pod-template-hash: def456  (v2 pods - SWITCHED!)
│
└── previewService selector:
    └── app: currency-converter
        argo-rollouts-pod-template-hash: abc123  (v1 pods)
```

---

**active-service.yaml** - Production Traffic Service

```yaml
apiVersion: v1
kind: Service
metadata:
  name: currency-converter-active-svc
  namespace: default
spec:
  type: ClusterIP
  ports:
  - port: 80
    targetPort: 5555
    protocol: TCP
  selector:
    app: currency-converter
    # Rollout controller REPLACES the argo-rollouts-pod-template-hash
```

**What This Does:**
- Exposes port 80 (standard HTTP)
- Routes to container port 5555
- Selector is updated by Rollout controller during promotions
- ClusterIP service (internal only; ALB routes externally)

---

**preview-service.yaml** - Staging/QA Service

```yaml
apiVersion: v1
kind: Service
metadata:
  name: currency-converter-preview-svc
  namespace: default
spec:
  type: ClusterIP
  ports:
  - port: 80
    targetPort: 5555
    protocol: TCP
  selector:
    app: currency-converter
```

**Identical to active-service**, only metadata name differs. This allows two separate endpoints.

---

**ingress.yaml** - Production Ingress

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: app-main-ingress
  namespace: default
  annotations:
    alb.ingress.kubernetes.io/scheme: internet-facing
    alb.ingress.kubernetes.io/target-type: ip
    alb.ingress.kubernetes.io/group.name: shared-ingress-group
    alb.ingress.kubernetes.io/listen-ports: '[{"HTTP":80}]'
spec:
  ingressClassName: alb
  rules:
  - host: app.trialphase.shop
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: currency-converter-active-svc
            port:
              number: 80
```

**Annotation Details:**

| Annotation | Value | Purpose |
|-----------|-------|---------|
| `alb.ingress.kubernetes.io/scheme` | `internet-facing` | Publicly accessible ALB |
| `alb.ingress.kubernetes.io/target-type` | `ip` | Direct pod IP targeting |
| `alb.ingress.kubernetes.io/group.name` | `shared-ingress-group` | Share ALB with other ingresses |
| `ingressClassName` | `alb` | Use AWS Load Balancer Controller |

**ALB Provisioning Flow:**
1. Ingress created
2. AWS Load Balancer Controller detects ingress
3. Creates ALB in AWS (via CloudFormation)
4. Registers target group for service
5. Creates listener rule for hostname
6. DNS propagates (ALB hostname populated)

---

**preview-ingress.yaml** - Staging Ingress

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: app-preview-ingress
  namespace: default
  annotations:
    alb.ingress.kubernetes.io/scheme: internet-facing
    alb.ingress.kubernetes.io/target-type: ip
    alb.ingress.kubernetes.io/group.name: shared-ingress-group
spec:
  ingressClassName: alb
  rules:
  - host: appdev.trialphase.shop
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: currency-converter-preview-svc
            port:
              number: 80
```

**Key Difference:** Points to `preview-svc` instead of `active-svc`

**Traffic Paths:**
- **app.trialphase.shop** → ALB → active-svc (production)
- **appdev.trialphase.shop** → ALB → preview-svc (staging)

Both ingresses share the same ALB (via `group.name`) for efficiency.

---

**secret.yaml** - API Credentials

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: api-keys
  namespace: default
type: Opaque
data:
  APIKEY: NWFkNzc5ODAxY21zaDE5MzUxY2M4NDYyZWU5NnAxM2UwZDdqc24wZTJmNWUzM2MzN2U=
```

**Decoded APIKEY:** (base64 decode) - RapidAPI key for currency conversion API

**Usage in Rollout:**
```yaml
env:
- name: APIKEY
  valueFrom:
    secretKeyRef:
      name: api-keys
      key: APIKEY
```

**Why This Matters:**
- **Kubernetes Secret**: Stored encrypted at rest in etcd
- **GitOps-safe**: Base64 encoding (not encryption) - consider external secrets manager for production
- **Pod injection**: Environment variable automatically populated from secret

---

**kustomization.yaml** (Base)

```yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
namespace: default

resources:
- rollout.yaml
- active-service.yaml
- preview-service.yaml
- ingress.yaml
- preview-ingress.yaml
- secret.yaml
```

**What This Does:**
- Declares all base resources
- Sets default namespace for all
- Can be extended by overlays with patches

---

#### Environment Overlays

**overlays/production/kustomization.yaml**

```yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
namespace: default

resources:
- ../../base

patches:
- path: image-patch.yaml
  target:
    kind: Rollout
    name: currency-converter
```

**Overlay Logic:**
1. Include all base resources
2. Apply patches on top
3. Output final manifests

---

**overlays/production/image-patch.yaml**

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Rollout
metadata:
  name: currency-converter
spec:
  template:
    spec:
      containers:
      - name: currency-converter
        image: 538153606685.dkr.ecr.us-east-1.amazonaws.com/currencyconverter:v1
```

**Patch Application:**
- Merges with base Rollout
- Overrides only the `image` field
- All other fields preserved from base

**Result After Kustomize Build:**
```yaml
# Final production manifest
apiVersion: argoproj.io/v1alpha1
kind: Rollout
metadata:
  name: currency-converter
  namespace: default  # From base
spec:
  replicas: 1  # From base
  selector: { ... }  # From base
  template:
    metadata:
      labels: { ... }  # From base
    spec:
      containers:
      - name: currency-converter
        image: 538153606685.dkr.ecr.us-east-1.amazonaws.com/currencyconverter:v1  # PATCHED
        ports: [ ... ]  # From base
        env: [ ... ]  # From base
  strategy:  # From base
    blueGreen:
      activeService: currency-converter-active-svc
      previewService: currency-converter-preview-svc
      autoPromotionEnabled: false
```

---

**overlays/development/kustomization.yaml**

```yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

resources:
- ../../base

patches:
- patch: |-
    - op: replace
      path: /spec/rules/0/host
      value: argocd.theutility.shop
    - op: replace
      path: /spec/rules/1/host
      value: application.theutility.shop
  target:
    kind: Ingress
    name: app-main-ingress

- path: deployment-patch.yaml
  target:
    kind: Deployment
    name: currency-converter
```

**Inline JSONPatch Operations:**
- **op: replace**: Replace field value
- **path**: JSON path to field
- **value**: New value

**Deployment Patch File:**
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: currency-converter
spec:
  template:
    spec:
      containers:
      - name: currency-converter
        env:
        - name: FLASK_ENV
          value: "development"
```

**Development Configuration:**
- Hostnames → development domain
- FLASK_ENV → development (debug mode, verbose logging)
- Same application code, different configuration

---

### 3. GitOps Delivery: ArgoCD

#### ArgoCD Applications

**argocd/argocd.yaml** - Self-Managed ArgoCD

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: argocd
  namespace: argocd
spec:
  project: default
  
  source:
    repoURL: 'https://github.com/Aashwin11/AgroCdAppDeploy-FORKED.git'
    targetRevision: applicationsetup-Aniket-ArgoRollout-BG
    path: argocd
  
  destination:
    server: 'https://kubernetes.default.svc'
    namespace: argocd
  
  syncPolicy:
    automated:
      selfHeal: true
      prune: true
```

**What This Does:**

- **Self-referential**: ArgoCD application manages itself
- **Watches Git**: `argocd/` directory in specified branch
- **Automated sync**: Any Git change automatically applied
- **selfHeal**: If cluster resources drift, ArgoCD corrects them
- **prune**: Deleted resources removed from cluster

**Reconciliation Loop:**
```
Every 3 seconds (default):
├─ Poll Git: Fetch latest argocd/ manifests
├─ Compare: Git vs Cluster resources
├─ Identify: New/changed/deleted resources
├─ Sync: Apply differences to cluster
└─ Status: Update application status
```

---

**argocd/currencyconverter.yaml** - Currency Converter Application

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: currencyconverter-production
  namespace: argocd
spec:
  project: default
  
  source:
    repoURL: 'https://github.com/Aashwin11/AgroCdAppDeploy-FORKED.git'
    targetRevision: applicationsetup-Aniket-ArgoRollout-BG
    path: k8s-kustomize/overlays/production
  
  destination:
    server: 'https://kubernetes.default.svc'
    namespace: default
  
  syncPolicy:
    automated:
      selfHeal: true
      prune: true
```

**What This Does:**

- **Watches**: `k8s-kustomize/overlays/production/` directory
- **Builds**: Kustomize manifests (base + production patches)
- **Deploys**: To `default` namespace in cluster
- **Continuous**: Every 3 seconds, reconciles Git ↔ Cluster
- **Self-healing**: Manual cluster changes auto-reverted

**Sync Process:**
```
ArgoCD Reconciliation Loop:
├─ [1] Fetch: Git resources from overlays/production/
├─ [2] Build: Kustomize (base + image-patch.yaml)
├─ [3] Compare: Generated manifests vs cluster resources
├─ [4] Identify: Additions, modifications, deletions
├─ [5] Sync: Apply differences (create, patch, delete)
└─ [6] Status: Mark as "Synced" or "OutOfSync"
```

---

#### ArgoCD Key Parameters

| Parameter | Value | Purpose |
|-----------|-------|---------|
| `repoURL` | GitHub HTTPS URL | Source of truth location |
| `targetRevision` | Branch name | Which branch to watch |
| `path` | Directory path | Manifests subdirectory |
| `destination.server` | K8s API endpoint | Target cluster |
| `destination.namespace` | Kubernetes namespace | Deploy location |
| `selfHeal: true` | Enabled | Revert manual changes |
| `prune: true` | Enabled | Delete resources not in Git |

---

### 4. CI/CD Orchestration: GitHub Actions Workflows

#### Workflow Overview

Seven workflows automate the complete lifecycle:

1. **1-terraform-infra.yml**: Provision/destroy AWS infrastructure
2. **2-apply-to-eks.yml**: Install controllers and platforms
3. **3-remove-from-eks.yml**: Clean up applications
4. **5-terraform-statelock.yaml**: Force-unlock state
5. **6-deployment-switch.yaml**: Flip blue/green via GitOps
6. **7-promote-rollout.yaml**: Promote via kubectl
7. **test-workflow.yaml**: Validate deployment

---

#### Workflow 1: Terraform Infrastructure

**File:** `.github/workflows/1-terraform-infra.yml`

**Entry Point:** Manual workflow dispatch with inputs

```yaml
on:
  workflow_dispatch:
    inputs:
      action:
        description: 'Action to perform'
        type: choice
        options: [apply, destroy]
        default: 'apply'
      aws_region:
        description: 'AWS Region'
        type: string
        default: 'us-east-2'
      project_name:
        description: 'Project Name'
        type: string
        default: 'staging-eks-demo'
      instance_types:
        description: 'EC2 Instance Types'
        type: string
        default: 't3.medium'
      cluster_version:
        description: 'Kubernetes Version'
        type: string
        default: '1.31'
      tf_state_bucket:
        description: 'S3 bucket for state'
        type: string
        default: 'staging-eks-demo-tfstate-t3'
      tf_lock_table:
        description: 'DynamoDB table for locking'
        type: string
        default: 'staging-eks-demo-tf-lock'
```

**Execution Steps:**

```bash
# 1. Checkout code
- uses: actions/checkout@v4

# 2. Configure AWS credentials
- uses: aws-actions/configure-aws-credentials@v4
  with:
    aws-access-key-id: ${{ secrets.AWS_ACCESS_KEY_ID }}
    aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
    aws-region: ${{ github.event.inputs.aws_region }}

# 3. Setup Terraform
- uses: hashicorp/setup-terraform@v3
  with:
    terraform_version: 1.6.0

# 4. Initialize backend with dynamic config
- run: |
    terraform init \
      -backend-config="bucket=${{ github.event.inputs.tf_state_bucket }}" \
      -backend-config="key=staging/${{ github.event.inputs.project_name }}/terraform.tfstate" \
      -backend-config="region=${{ github.event.inputs.aws_region }}" \
      -backend-config="dynamodb_table=${{ github.event.inputs.tf_lock_table }}"

# 5. Generate tfvars.json with CREATOR_ARN
- run: |
    CREATOR_ARN=$(aws sts get-caller-identity --query Arn --output text)
    cat > my-vars.tfvars.json <<EOF
    {
      "aws_region": "${{ github.event.inputs.aws_region }}",
      "project_name": "${{ github.event.inputs.project_name }}",
      "cluster_version": "${{ github.event.inputs.cluster_version }}",
      "instance_types": ["${{ github.event.inputs.instance_types }}"],
      "cluster_creator_arn": "$CREATOR_ARN"
    }
    EOF

# 6. Apply or destroy based on input
- if: github.event.inputs.action == 'apply'
  run: |
    terraform plan -input=false -out=tfplan -var-file="my-vars.tfvars.json"
    terraform apply -auto-approve -input=false tfplan

- if: github.event.inputs.action == 'destroy'
  run: |
    terraform destroy -auto-approve -input=false -var-file="my-vars.tfvars.json"
```

**Key Features:**
- Dynamic backend configuration (different projects/regions)
- Runtime ARN capture (cluster creator authorization)
- Validated Terraform execution
- State locking via DynamoDB

---

#### Workflow 2: Deploy to EKS

**File:** `.github/workflows/2-apply-to-eks.yml`

**High-Level Flow:**

```
┌─ Install Tools ────────────┐
│  - eksctl                   │
│  - kubectl argo-rollouts   │
│  - Helm                     │
└────────────────────────────┘
         ↓
┌─ Connect to Cluster ───────┐
│  - Update kubeconfig       │
│  - Verify node readiness   │
└────────────────────────────┘
         ↓
┌─ ALB Controller Setup ─────┐
│  - IAM Policy creation     │
│  - OIDC provider assoc.    │
│  - IRSA ServiceAccount     │
│  - Helm install ALB ctrl   │
└────────────────────────────┘
         ↓
┌─ Argo Rollouts Setup ──────┐
│  - Create namespace        │
│  - Install controller      │
│  - Wait for readiness      │
└────────────────────────────┘
         ↓
┌─ ArgoCD Setup ─────────────┐
│  - Helm install ArgoCD     │
│  - Apply ingress           │
│  - Apply app manifests     │
│  - Output credentials      │
└────────────────────────────┘
         ↓
┌─ Verify Deployment ────────┐
│  - Wait for ALB hostname   │
│  - Print ArgoCD URL        │
│  - Output admin password   │
└────────────────────────────┘
```

**Detailed Steps (Excerpts):**

```bash
# Install Argo Rollouts CLI
- name: Install Argo Rollouts kubectl plugin
  run: |
    curl -sLO https://github.com/argoproj/argo-rollouts/releases/latest/download/kubectl-argo-rollouts-linux-amd64
    chmod +x ./kubectl-argo-rollouts-linux-amd64
    sudo mv ./kubectl-argo-rollouts-linux-amd64 /usr/local/bin/kubectl-argo-rollouts

# Create IRSA for ALB Controller
- name: Create IAM Service Account for ALB Controller
  run: |
    eksctl create iamserviceaccount \
      --cluster=${{ github.event.inputs.cluster_name }} \
      --namespace=kube-system \
      --name=aws-load-balancer-controller \
      --role-name "AmazonEKSLoadBalancerControllerRole-${{ github.event.inputs.cluster_name }}" \
      --attach-policy-arn=$POLICY_ARN \
      --approve \
      --region=${{ github.event.inputs.aws_region }} \
      --override-existing-serviceaccounts

# Install Argo Rollouts Controller
- name: Install Argo Rollouts Controller
  run: |
    kubectl create namespace argo-rollouts
    kubectl apply -n argo-rollouts -f https://github.com/argoproj/argo-rollouts/releases/latest/download/install.yaml
    kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=argo-rollouts -n argo-rollouts --timeout=300s

# Install ALB Controller via Helm
- name: Install AWS Load Balancer Controller
  run: |
    VPC_ID=$(aws eks describe-cluster --name ${{ github.event.inputs.cluster_name }} --query "cluster.resourcesVpcConfig.vpcId" --output text)
    helm repo add eks https://aws.github.io/eks-charts
    helm repo update
    helm upgrade --install aws-load-balancer-controller eks/aws-load-balancer-controller \
      --namespace kube-system \
      --set clusterName=${{ github.event.inputs.cluster_name }} \
      --set serviceAccount.create=false \
      --set serviceAccount.name=aws-load-balancer-controller \
      --set vpcId=$VPC_ID \
      --set region=${{ github.event.inputs.aws_region }}

# Install ArgoCD
- name: Install ArgoCD
  run: |
    helm repo add argo https://argoproj.github.io/argo-helm
    helm repo update
    helm upgrade --install argocd argo/argo-cd \
      --namespace argocd \
      --create-namespace \
      --set server.service.type=ClusterIP \
      --set server.extraArgs={--insecure}

# Apply ArgoCD Application manifests
- name: Apply ArgoCD Application Definitions
  run: |
    kubectl apply -f argocd/
    echo "ArgoCD applications applied, syncing with Git..."
```

**Key Outcomes:**
- ✅ Argo Rollouts controller operational (argo-rollouts namespace)
- ✅ ALB Controller operational (kube-system namespace)
- ✅ ArgoCD operational (argocd namespace)
- ✅ Applications syncing from Git
- ✅ ALB provisioning ARNs for ingresses

---

#### Workflow 6: Deployment Switch (Blue-Green Flip)

**File:** `.github/workflows/6-deployment-switch.yaml`

**Purpose:** Flip production traffic from blue to green (or vice versa) via GitOps

**Flow:**

```bash
# 1. Checkout with PAT (personal access token for commit permissions)
- uses: actions/checkout@v4
  with:
    token: ${{ secrets.REPO_PAT }}
    ref: 'applicationsetup-Aniket-ArgoRollout-BG'

# 2. Determine current color and flip
- name: Find current color and flip it
  id: flip
  run: |
    FILE_PATH="argocd/currencyconverter.yaml"
    
    if grep -q 'production/blue' "$FILE_PATH"; then
      CURRENT_COLOR="BLUE"
      NEW_COLOR="GREEN"
      echo "🎨 Current color is BLUE. Flipping to GREEN."
      sed -i 's|production/blue|production/green|' "$FILE_PATH"
    
    elif grep -q 'production/green' "$FILE_PATH"; then
      CURRENT_COLOR="GREEN"
      NEW_COLOR="BLUE"
      echo "🎨 Current color is GREEN. Flipping to BLUE."
      sed -i 's|production/green|production/blue|' "$FILE_PATH"
    
    else
      echo "❌ Error: Could not determine current color."
      exit 1
    fi
    
    echo "new_color=$NEW_COLOR" >> $GITHUB_OUTPUT

# 3. Commit and push changes
- name: Commit and push changes
  run: |
    git config --global user.name "GitHub Actions Flip Bot"
    git config --global user.email "actions@github.com"
    git add argocd/currencyconverter.yaml
    git commit -m "Automated Flip: Switched production deployment to ${{ steps.flip.outputs.new_color }}"
    git push
```

**What Happens:**

1. **Reads** current ArgoCD application path (blue or green)
2. **Modifies** the path using sed to flip it
3. **Commits** change back to Git with descriptive message
4. **Pushes** to branch
5. **ArgoCD Detects** the Git change (within 3 seconds)
6. **Syncs** new path, which may have different image/configuration
7. **Traffic Flips** - activeService selector updated by Rollout

**Example Change:**

```yaml
# Before
source:
  path: k8s-kustomize/overlays/production/blue

# After
source:
  path: k8s-kustomize/overlays/production/green
```

If `blue/` has v1 image and `green/` has v2 image:
- Kustomize builds with v2
- Rollout deployed with v2
- Traffic switches to v2 (via Rollout promotion logic)

---

#### Workflow 7: Promote Rollout

**File:** `.github/workflows/7-promote-rollout.yaml`

**Purpose:** Directly promote rollout (faster than Git flip)

**Flow:**

```bash
# 1. Input parameters
on:
  workflow_dispatch:
    inputs:
      rollout_name:
        description: 'Name of the Rollout to promote'
        default: 'currency-converter'
      namespace:
        description: 'Namespace of the Rollout'
        default: 'default'
      aws_region:
        description: 'AWS Region'
        default: 'us-east-1'
      cluster_name:
        description: 'EKS Cluster Name'
        default: 'staging-eks-demo'

# 2. Setup and authentication
- uses: actions/checkout@v4
- uses: aws-actions/configure-aws-credentials@v4
  with:
    aws-access-key-id: ${{ secrets.AWS_ACCESS_KEY_ID }}
    aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
    aws-region: ${{ github.event.inputs.aws_region }}

# 3. Install Argo Rollouts CLI
- name: Install Argo Rollouts kubectl plugin
  run: |
    curl -sLO https://github.com/argoproj/argo-rollouts/releases/latest/download/kubectl-argo-rollouts-linux-amd64
    chmod +x ./kubectl-argo-rollouts-linux-amd64
    sudo mv ./kubectl-argo-rollouts-linux-amd64 /usr/local/bin/kubectl-argo-rollouts

# 4. Connect to cluster
- name: Connect to EKS Cluster
  run: |
    aws eks update-kubeconfig \
      --region ${{ github.event.inputs.aws_region }} \
      --name ${{ github.event.inputs.cluster_name }}

# 5. Promote rollout
- name: Promote Rollout
  run: |
    kubectl argo rollouts promote ${{ github.event.inputs.rollout_name }} \
      -n ${{ github.event.inputs.namespace }}
    echo "✅ Rollout promoted successfully"
```

**What Happens:**

The kubectl argo-rollouts plugin executes a Patch operation on the Rollout:

```bash
kubectl argo rollouts promote currency-converter -n default
```

Internally, this updates the Rollout status:

```yaml
status:
  blueGreen:
    activeSelector: "def456"  # Was "abc123" (v1)
    previewSelector: "abc123"  # Was "def456" (v2)
  phase: "Healthy"
```

Argo Rollouts controller sees this and:
1. Updates activeService selector to match "def456" (v2 pods)
2. Updates previewService selector to match "abc123" (v1 pods)
3. Traffic instantly switches to v2

---

### 5. Application Layer

#### Container Image

**Dockerfile**

```dockerfile
FROM python:3.9-slim

WORKDIR /app
COPY . /app

RUN pip install --no-cache-dir -r requirements.txt

EXPOSE 5555

ENV FLASK_APP=app.py
ENV FLASK_RUN_HOST=0.0.0.0

CMD ["flask", "run", "--host=0.0.0.0", "--port=5555"]
```

**Design Decisions:**
- **python:3.9-slim**: Minimal footprint (not full 3.9 image)
- **Multi-layer build**: Copy dependencies once, copy code separately
- **--no-cache-dir**: Reduces image size
- **Port 5555**: Matches container port in Rollout spec
- **FLASK_RUN_HOST**: 0.0.0.0 (listens on all interfaces, required for containers)

---

#### Requirements

**requirements.txt**

```
Flask==3.0.2           # Web framework
requests==2.31.0       # HTTP client for API calls
Werkzeug==3.0.1        # WSGI utilities
Jinja2==3.1.3          # Template engine
# ... other dependencies
```

**Key Packages:**
- **Flask**: Micro-framework for HTTP endpoints
- **requests**: Makes HTTP calls to external currency API

---

#### Application Code (Implied)

**app.py** (structure):

```python
from flask import Flask, jsonify, request
import os
import requests

app = Flask(__name__)

# Configuration from environment
APIKEY = os.environ.get('APIKEY')
APIHOST = os.environ.get('APIHOST', 'currency-conversion-and-exchange-rates.p.rapidapi.com')

@app.route('/convert', methods=['GET'])
def convert_currency():
    """Convert currency using external API"""
    from_currency = request.args.get('from')
    to_currency = request.args.get('to')
    amount = request.args.get('amount')
    
    # Call external API
    headers = {
        'X-RapidAPI-Key': APIKEY,
        'X-RapidAPI-Host': APIHOST
    }
    
    response = requests.get(
        f'https://{APIHOST}/latest',
        params={'base': from_currency, 'symbols': to_currency},
        headers=headers
    )
    
    data = response.json()
    rate = data['rates'][to_currency]
    result = float(amount) * rate
    
    return jsonify({'result': result})

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5555, debug=True)
```

**API Contract:**
- **Endpoint**: GET `/convert?from=USD&to=EUR&amount=100`
- **Response**: `{"result": 92.5}`
- **Authentication**: Via APIKEY environment variable

---

#### Frontend

**templates/index.html** (excerpt):

```html
<!DOCTYPE html>
<html>
<head>
    <title>Currency Converter</title>
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.2/dist/css/bootstrap.min.css" rel="stylesheet">
</head>
<body>
    <div class="container">
        <h1>Currency Converter (V2 for GREEN test)</h1>
        <form id="currencyForm">
            <div class="mb-3">
                <label for="sourceCurrency" class="form-label">Source Currency</label>
                <select class="form-control" id="sourceCurrency" required>
                    <option value="USD">USD - United States Dollar</option>
                    <option value="EUR">EUR - Euro</option>
                    <!-- More options -->
                </select>
            </div>
            <div class="mb-3">
                <label for="targetCurrency" class="form-label">Target Currency</label>
                <select class="form-control" id="targetCurrency" required>
                    <!-- Options -->
                </select>
            </div>
            <div class="mb-3">
                <label for="amount" class="form-label">Amount</label>
                <input type="number" class="form-control" id="amount" placeholder="Enter Amount">
            </div>
            <button type="submit" class="btn btn-primary w-100">Convert</button>
        </form>
        <div id="resultCard" class="card text-center" style="display: none;">
            <div class="card-body">
                <h5 class="card-title" id="resultTitle">Conversion Result</h5>
                <p class="card-text" id="result"></p>
            </div>
        </div>
    </div>
    <script src="{{ url_for('static', filename='js/app.js') }}"></script>
</body>
</html>
```

**Note:** Header says "V2 for GREEN test" - useful for visually confirming which version is deployed.

---

**static/js/app.js** (excerpt):

```javascript
document.getElementById("currencyForm").addEventListener("submit", function (e) {
    e.preventDefault();
    
    const sourceCurrency = document.getElementById("sourceCurrency").value;
    const targetCurrency = document.getElementById("targetCurrency").value;
    const amount = document.getElementById("amount").value;
    
    document.getElementById("loadingSpinner").style.display = "block";
    
    fetch(`/convert?from=${sourceCurrency}&to=${targetCurrency}&amount=${amount}`)
        .then(response => response.json())
        .then(data => {
            const resultText = `${amount} ${sourceCurrency} is ${data.result} ${targetCurrency}`;
            document.getElementById("result").innerText = resultText;
            document.getElementById("resultCard").style.display = "block";
            document.getElementById("loadingSpinner").style.display = "none";
        })
        .catch(error => {
            document.getElementById("resultTitle").innerText = "Conversion Failed";
            document.getElementById("resultCard").style.display = "block";
            document.getElementById("loadingSpinner").style.display = "none";
        });
});
```

**Functionality:**
- Form submission handler
- Fetch API call to `/convert` endpoint
- Display result card
- Error handling

---

## Component Glossary

### Infrastructure Components

| Component | File | Purpose | AWS Service |
|-----------|------|---------|-------------|
| **VPC** | `modules/vpc/main.tf` | Network isolation | AWS VPC (10.0.0.0/16) |
| **Public Subnets** | `modules/vpc/main.tf` | ALB, NAT Gateway | AWS Subnets (10.0.1.0/24, 10.0.2.0/24) |
| **Private Subnets** | `modules/vpc/main.tf` | EKS nodes | AWS Subnets (10.0.101.0/24, 10.0.102.0/24) |
| **Internet Gateway** | `modules/vpc/main.tf` | Public internet access | AWS IGW |
| **NAT Gateway** | `modules/vpc/main.tf` | Private egress | AWS NAT Gateway |
| **Route Tables** | `modules/vpc/main.tf` | Network routing | AWS Route Tables |
| **EKS Cluster** | `modules/eks/main.tf` | Kubernetes control plane | AWS EKS |
| **Node Group** | `modules/eks/main.tf` | Worker nodes (t3.medium) | AWS Auto Scaling Group |
| **Cluster Role** | `modules/eks/main.tf` | Cluster permissions | AWS IAM Role |
| **Node Role** | `modules/eks/main.tf` | Node permissions | AWS IAM Role |
| **aws-auth ConfigMap** | `main.tf` | IAM → RBAC mapping | Kubernetes ConfigMap |

---

### Kubernetes Components

| Component | File | Purpose | Orchestrator |
|-----------|------|---------|--------------|
| **Rollout** | `base/rollout.yaml` | Progressive deployment | Argo Rollouts |
| **Active Service** | `base/active-service.yaml` | Production traffic | Kubernetes Service |
| **Preview Service** | `base/preview-service.yaml` | Staging traffic | Kubernetes Service |
| **Production Ingress** | `base/ingress.yaml` | app.trialphase.shop | AWS ALB Controller |
| **Preview Ingress** | `base/preview-ingress.yaml` | appdev.trialphase.shop | AWS ALB Controller |
| **Secret** | `base/secret.yaml` | API credentials | Kubernetes Secret |
| **ALB Controller** | (Helm installed) | Ingress provisioning | AWS Load Balancer Controller |
| **Argo Rollouts** | (Helm installed) | Blue-green orchestration | Argo Rollouts Controller |
| **ArgoCD** | (Helm installed) | GitOps reconciliation | ArgoCD Controller |

---

### CI/CD Workflows

| Workflow | File | Trigger | Purpose |
|----------|------|---------|---------|
| **Terraform Infra** | `1-terraform-infra.yml` | Manual dispatch | Provision/destroy AWS |
| **Deploy to EKS** | `2-apply-to-eks.yml` | Manual dispatch | Install controllers |
| **Remove from EKS** | `3-remove-from-eks.yml` | Manual dispatch | Clean up applications |
| **Unlock Terraform** | `5-terraform-statelock.yaml` | Manual dispatch | Force-unlock state |
| **Deployment Switch** | `6-deployment-switch.yaml` | Manual dispatch | Flip blue/green |
| **Promote Rollout** | `7-promote-rollout.yaml` | Manual dispatch | Promote via kubectl |
| **Test Workflow** | `test-workflow.yaml` | Manual dispatch | Validate deployment |

---

### Configuration Parameters

| Parameter | File | Default | Purpose |
|-----------|------|---------|---------|
| `aws_region` | `1-terraform-infra.yml` | `us-east-2` | AWS region for infrastructure |
| `project_name` | `1-terraform-infra.yml` | `staging-eks-demo` | Unique project identifier |
| `instance_types` | `1-terraform-infra.yml` | `t3.medium` | EC2 node instance type |
| `cluster_version` | `1-terraform-infra.yml` | `1.31` | Kubernetes version |
| `tf_state_bucket` | `1-terraform-infra.yml` | `staging-eks-demo-tfstate-t3` | S3 bucket for Terraform state |
| `tf_lock_table` | `1-terraform-infra.yml` | `staging-eks-demo-tf-lock` | DynamoDB table for locking |

---

## Deployment Logic: Blue-Green Rollouts

### How Blue-Green Works in This Setup

#### Conceptual Model

```
BEFORE DEPLOYMENT:
┌─────────────────────────────────────────────────┐
│ ACTIVE (Blue)          PREVIEW (Green)          │
│ currency-converter-active-svc ← LIVE TRAFFIC   │
│ Pods: v1, v1          (empty)                  │
│ Port 80 → 5555                                  │
│ App.trialphase.shop                             │
└─────────────────────────────────────────────────┘

NEW VERSION COMMITTED TO GIT:
│
├─ ArgoCD detects change
├─ Kustomize builds manifests (base + production patches)
├─ Rollout spec updated with new image (v2)
│
└─ Argo Rollouts Controller creates new ReplicaSet (v2)

AFTER DEPLOYMENT (BEFORE PROMOTION):
┌─────────────────────────────────────────────────┐
│ ACTIVE (Blue)          PREVIEW (Green)          │
│ currency-converter-active-svc ← LIVE TRAFFIC   │
│ Pods: v1, v1          currency-converter-preview-svc
│                       Pods: v2, v2
│ Port 80 → v1 (prod)   Port 80 → v2 (staging)
│ App.trialphase.shop   Appdev.trialphase.shop
│                       (QA validates v2 here)
└─────────────────────────────────────────────────┘

AFTER PROMOTION:
┌─────────────────────────────────────────────────┐
│ ACTIVE (Blue)          PREVIEW (Green)          │
│ currency-converter-active-svc ← LIVE TRAFFIC   │
│ Pods: v2, v2          currency-converter-preview-svc
│ (NEW version now!)     Pods: v1, v1
│                        (old version, ready for next)
│ Port 80 → v2 (prod)   Port 80 → v1 (staging)
│ App.trialphase.shop   Appdev.trialphase.shop
└─────────────────────────────────────────────────┘

ZERO-DOWNTIME CHARACTERISTICS:
✅ No pod restart during switch
✅ No connection drops (both sets running during transition)
✅ v1 pods remain for instant rollback
✅ Service selector switch < 1 second
✅ DNS/ALB unchanged (same hostnames)
```

---

#### Step-by-Step Execution

**STEP 1: Git Commit Triggers ArgoCD**

```
Developer: git commit new image or manifest
           git push to applicationsetup-Aniket-ArgoRollout-BG
                      ↓
ArgoCD Polling (every ~3 seconds):
├─ Fetches Git: k8s-kustomize/overlays/production/
├─ Detects: Image changed (v1 → v2) in image-patch.yaml
├─ Triggers: Sync operation
└─ Status: Syncing
```

**STEP 2: Kustomize Manifest Building**

```
Kustomize Build Process:
├─ [1] Read: k8s-kustomize/overlays/production/kustomization.yaml
├─ [2] Include: ../../base (all base resources)
├─ [3] Apply: image-patch.yaml
│       - Replaces /spec/template/spec/containers/0/image
│       - Old: 538153606685.dkr.ecr.us-east-1.amazonaws.com/currencyconverter:v1
│       - New: 538153606685.dkr.ecr.us-east-1.amazonaws.com/currencyconverter:v2
├─ [4] Output: Complete Rollout, Services, Ingress manifests
└─ Result: Ready to apply to cluster
```

**STEP 3: Rollout Creation**

```
ArgoCD Apply Phase:
├─ [1] Compare: Git manifest vs Cluster resource
├─ [2] Detect: Image changed from v1 to v2
├─ [3] Sync: Update Rollout spec with new image
└─ Result: Rollout.spec.template.spec.containers[0].image = v2

Argo Rollouts Controller Detects Change:
├─ [1] Watches: Rollout resource
├─ [2] Detects: Spec changed (new image)
├─ [3] Decision: New ReplicaSet needed
└─ Action: Create ReplicaSet with v2 image
```

**STEP 4: Blue-Green Selector Management**

```
Argo Rollouts Status Update:
├─ [1] Current ReplicaSet (v1): argo-rollouts-pod-template-hash: abc123
├─ [2] New ReplicaSet (v2): argo-rollouts-pod-template-hash: def456
│
├─ activeService selector: app=currency-converter, hash=abc123 (v1)
├─ previewService selector: app=currency-converter, hash=def456 (v2)
│
└─ Result:
    - activeService → v1 pods (LIVE TRAFFIC)
    - previewService → v2 pods (STAGING)

Wait for Pod Readiness:
├─ [1] Pod scheduler: Launch v2 pods
├─ [2] Container startup: Pull image, start Flask app
├─ [3] Health check: Readiness probes pass
├─ [4] Argo Rollouts: Mark as "Healthy"
└─ Status: "Waiting for promotion" (because autoPromotionEnabled: false)
```

**STEP 5: QA Validation**

```
QA Process:
├─ [1] Access: appdev.trialphase.shop
│       ALB → preview-service → v2 pods
├─ [2] Test: Currency conversions, API calls, functionality
├─ [3] Validate: All features working correctly
├─ [4] Approve: "Ready for production"
└─ Result: Promotion decision made
```

**STEP 6: Manual Promotion (Method A: kubectl)**

```
Developer Action: kubectl argo rollouts promote currency-converter -n default
                      ↓
Argo Rollouts Controller Update:
├─ [1] Update activeService selector:
│       OLD: hash=abc123 (v1)
│       NEW: hash=def456 (v2)
├─ [2] Update previewService selector:
│       OLD: hash=def456 (v2)
│       NEW: hash=abc123 (v1)
├─ [3] Kubernetes Service Controller updates endpoints
│       - activeService endpoints: SWITCH to v2 pods
│       - previewService endpoints: SWITCH to v1 pods
└─ [4] ALB health checks: Target health updated
        - app.trialphase.shop targets: v2 pods now
        - appdev.trialphase.shop targets: v1 pods now

Result: LIVE TRAFFIC → v2 INSTANTLY
Time: < 1 second
Downtime: NONE
```

**STEP 6B: Manual Promotion (Method B: GitOps)**

```
Developer Action: Trigger "6-Deployment Switch" workflow
                      ↓
Workflow Execution:
├─ [1] Checkout repository
├─ [2] Read: argocd/currencyconverter.yaml
├─ [3] Check path: "production/blue" or "production/green"
├─ [4] Flip: sed 's|production/blue|production/green|'
├─ [5] Commit: "Automated Flip: Switched to GREEN"
├─ [6] Push: Update Git branch
│
└─ Git Update Detected by ArgoCD:
    ├─ [1] Fetch: New argocd/currencyconverter.yaml
    ├─ [2] Path changed: overlays/production/green
    ├─ [3] Build: Kustomize with new path
    │       (green/ has different image than blue/)
    ├─ [4] Rollout: New manifest applied
    ├─ [5] Selector: Updated by Argo Rollouts
    └─ Result: LIVE TRAFFIC → v2 (via GitOps)

Result: LIVE TRAFFIC → v2 (via Git + ArgoCD)
Time: 3-10 seconds (ArgoCD polling interval)
Downtime: NONE
```

---

#### Rollback Mechanism

```
Scenario: v2 has issues after promotion

Option 1: Promote Again (Fastest)
├─ kubectl argo rollouts promote currency-converter -n default
├─ Selectors FLIP back:
│   - activeService: hash=abc123 (v1)
│   - previewService: hash=def456 (v2)
├─ v1 pods immediately receive live traffic
├─ v2 pods moved to preview
└─ Result: INSTANT ROLLBACK (< 1 second)

Option 2: Git Revert (Auditable)
├─ git revert <commit-that-flipped-to-green>
├─ git push
├─ ArgoCD detects: path changed back to blue
├─ Kustomize builds with blue image
├─ Rollout updated, selectors switched
└─ Result: ROLLBACK via Git (3-10 seconds)

Both Methods:
✅ Zero downtime
✅ v1 pods still running (no cold start)
✅ Instant traffic redirection
✅ Audit trail (kubectl logs or Git history)
```

---

## Critical YAML Parameters Explained

### Rollout Strategy Parameters

#### `spec.strategy.blueGreen`

```yaml
strategy:
  blueGreen:
    activeService: currency-converter-active-svc
    previewService: currency-converter-preview-svc
    autoPromotionEnabled: false
    autoPromotionSeconds: 300  # Ignored when false
```

**activeService**
- Name of Kubernetes Service for LIVE production traffic
- Argo Rollouts controller updates this service's pod selector
- Initially points to current (blue) ReplicaSet
- After promotion, points to new (green) ReplicaSet

**previewService**
- Name of Kubernetes Service for testing new versions
- Used for QA validation before production promotion
- Argo Rollouts controller updates this service's pod selector
- Initially points to new ReplicaSet
- After promotion, points to old ReplicaSet (ready for next version)

**autoPromotionEnabled**
- `false`: Requires explicit promotion (kubectl argo rollouts promote or GitOps)
- `true`: Automatically promotes after autoPromotionSeconds elapse
- **CRITICAL in this setup**: Always `false` for manual control

**autoPromotionSeconds**
- Only effective if `autoPromotionEnabled: true`
- Not used in this deployment (false)

---

### Ingress Annotations

#### ALB Annotations

```yaml
annotations:
  alb.ingress.kubernetes.io/scheme: internet-facing
  alb.ingress.kubernetes.io/target-type: ip
  alb.ingress.kubernetes.io/group.name: shared-ingress-group
  alb.ingress.kubernetes.io/listen-ports: '[{"HTTP":80}]'
```

**scheme: internet-facing**
- ALB is publicly routable
- Alternative: `internal` (private VPC only)
- Effect: ALB security group allows 0.0.0.0/0 ingress

**target-type: ip**
- ALB targets Kubernetes pod IPs directly
- Alternative: `instance` (route to node IP:NodePort)
- Why IP: Direct pod targeting, no intermediate node NAT

**group.name: shared-ingress-group**
- Multiple ingresses share single ALB
- Production ingress + preview ingress → same ALB
- Efficiency: One ALB serves both endpoints
- Alternative: No grouping (each ingress gets own ALB - expensive)

**listen-ports**
- ALB listens on port 80 (HTTP)
- Format: JSON array of port configurations
- Effect: Single ALB can listen on 80, 443, custom ports

---

### ArgoCD Application Parameters

#### source.path

```yaml
source:
  path: k8s-kustomize/overlays/production
```

- Subdirectory containing manifests
- **Kustomize detection**: If `kustomization.yaml` exists, builds via Kustomize
- **Plain YAML detection**: If no kustomization.yaml, applies YAML directly
- **Effect**: ArgoCD builds manifests before applying

**How Kustomize is Detected:**
```
ArgoCD checks: Does overlays/production/kustomization.yaml exist?
├─ YES: Run `kustomize build overlays/production/` → output manifests
└─ NO: Apply YAML files as-is
```

---

#### syncPolicy Parameters

```yaml
syncPolicy:
  automated:
    selfHeal: true
    prune: true
```

**selfHeal: true**
- If Kubernetes resource drifts from Git declaration, ArgoCD corrects it
- Example: Manual `kubectl edit service` change is reverted
- Prevents cluster state divergence
- Default: false (manual sync only)

**prune: true**
- If resource removed from Git, ArgoCD deletes it from cluster
- Example: Delete `service.yaml` from Git, service is removed from cluster
- Keeps cluster = Git exactly
- Default: false (manual deletion only)

**Reconciliation Loop (with both enabled):**
```
Every 3 seconds:
├─ [1] Fetch Git manifests
├─ [2] Fetch Cluster resources
├─ [3] Compare: Git vs Cluster
│       ├─ Additions: Apply new resources
│       ├─ Modifications: Update existing resources
│       ├─ Deletions: Remove missing resources (prune: true)
│       └─ Drifts: Correct drifted resources (selfHeal: true)
├─ [4] Status: Update application status
└─ [5] Sleep 3 seconds, repeat
```

---

### Kustomize Patch Parameters

#### JSONPatch Operations

```yaml
patches:
- patch: |-
    - op: replace
      path: /spec/rules/0/host
      value: argocd.theutility.shop
  target:
    kind: Ingress
    name: app-main-ingress
```

**op: replace**
- Operation type: Replace (modify existing field)
- Alternatives: `add`, `remove`, `move`, `copy`, `test`

**path: /spec/rules/0/host**
- JSON path to field
- `/`: Root of resource
- `spec/rules/0/host`: Ingress hostname

**value: argocd.theutility.shop**
- New value for field

**target.kind: Ingress**
- Which resource type to patch

**target.name: app-main-ingress**
- Which resource by name to patch

**Common Patch Operations:**

| Operation | Example | Effect |
|-----------|---------|--------|
| `replace` | `path: /spec/image, value: nginx:1.20` | Change image |
| `add` | `path: /spec/replicas, value: 3` | Add new field |
| `remove` | `path: /spec/volumeMounts/0` | Delete array element |
| `move` | `from: /spec/oldPath, path: /spec/newPath` | Rename field |
| `copy` | `from: /spec/source, path: /spec/destination` | Duplicate field |

---

### Service Selector Parameters

```yaml
spec:
  selector:
    app: currency-converter
```

**Static Selector**
- Matches pods with label `app: currency-converter`
- Kubernetes Service routes traffic to matching pods

**Dynamic Management by Rollout**
- Rollout controller adds label: `argo-rollouts-pod-template-hash: <hash>`
- Service selector unchanged in spec
- But Kubernetes only matches pods with both labels:
  1. `app: currency-converter` (always)
  2. `argo-rollouts-pod-template-hash: <specific-hash>` (controlled by Rollout)

**Selector Update Process:**
```
Argo Rollouts Controller:
├─ activeService selector target: OLD hash (v1 pods)
├─ previewService selector target: NEW hash (v2 pods)
│
After Promotion:
├─ activeService selector target: NEW hash (v2 pods) ← CHANGED
└─ previewService selector target: OLD hash (v1 pods) ← CHANGED

Kubernetes Service Controller:
├─ Updates endpoints for activeService → v2 pods
└─ Updates endpoints for previewService → v1 pods

ALB Targets Updated:
├─ app.trialphase.shop targets: v2 pods (new)
└─ appdev.trialphase.shop targets: v1 pods (old)
```

---

## Summary: The Complete Picture

### Continuous Deployment Flow

```
┌────────────────────────────────────────────────────────────┐
│ 1. INFRASTRUCTURE PROVISIONING (Terraform)                │
├────────────────────────────────────────────────────────────┤
│ ├─ AWS VPC, subnets, NAT, IGW                             │
│ ├─ EKS cluster in private subnets                         │
│ ├─ IAM roles, ec2 instance profiles                       │
│ ├─ State in S3 with DynamoDB locking                      │
│ └─ aws-auth ConfigMap (IAM → RBAC)                        │
└────────────────────────────────────────────────────────────┘
                          ↓
┌────────────────────────────────────────────────────────────┐
│ 2. PLATFORM DEPLOYMENT (GitHub Actions + Helm)            │
├────────────────────────────────────────────────────────────┤
│ ├─ ALB Controller (watches Ingress → creates ALBs)        │
│ ├─ Argo Rollouts (watches Rollout → orchestrates blue/gr)│
│ ├─ ArgoCD (watches Git → applies manifests)               │
│ └─ All controllers operational, waiting for apps          │
└────────────────────────────────────────────────────────────┘
                          ↓
┌────────────────────────────────────────────────────────────┐
│ 3. GIT REPOSITORY (Single Source of Truth)                │
├────────────────────────────────────────────────────────────┤
│ ├─ argocd/: ArgoCD application definitions                │
│ ├─ k8s-kustomize/: Kubernetes manifests                   │
│ │  ├─ base/: Common resources (Rollout, services)        │
│ │  └─ overlays/: Environment-specific patches             │
│ └─ All resources declared, ready to deploy                │
└────────────────────────────────────────────────────────────┘
                          ↓
┌────────────────────────────────────────────────────────────┐
│ 4. GIT CHANGE TRIGGER (Developer Action)                  │
├────────────────────────────────────────────────────────────┤
│ ├─ Developer commits new image to argocd/currencyconverter│
│ ├─ OR new patch in k8s-kustomize/overlays/production/    │
│ ├─ OR changes argocd/currencyconverter.yaml path          │
│ └─ Push to applicationsetup-Aniket-ArgoRollout-BG branch │
└────────────────────────────────────────────────────────────┘
                          ↓
┌────────────────────────────────────────────────────────────┐
│ 5. ARGOCD RECONCILIATION (Continuous)                     │
├────────────────────────────────────────────────────────────┤
│ ├─ Fetch Git manifests (every ~3 seconds)                 │
│ ├─ Build Kustomize (base + patches)                       │
│ ├─ Compare Git vs Cluster                                 │
│ ├─ Apply differences                                       │
│ └─ Rollout resource updated with new image                │
└────────────────────────────────────────────────────────────┘
                          ↓
┌────────────────────────────────────────────────────────────┐
│ 6. ARGO ROLLOUTS BLUE-GREEN ORCHESTRATION                 │
├────────────────────────────────────────────────────────────┤
│ ├─ Create new ReplicaSet (v2)                             │
│ ├─ Wait for pod readiness                                 │
│ ├─ Update previewService selector → v2 pods               │
│ ├─ Keep activeService selector → v1 pods                  │
│ └─ Status: Waiting for promotion (autoPromotionEnabled:F) │
└────────────────────────────────────────────────────────────┘
                          ↓
┌────────────────────────────────────────────────────────────┐
│ 7. QA VALIDATION & TESTING                                │
├────────────────────────────────────────────────────────────┤
│ ├─ QA accesses appdev.trialphase.shop (preview ingress)   │
│ ├─ Tests v2 application features                          │
│ ├─ Validates currency conversions                         │
│ └─ Approves for production                                │
└────────────────────────────────────────────────────────────┘
                          ↓
┌────────────────────────────────────────────────────────────┐
│ 8. PRODUCTION PROMOTION (Manual)                          │
├────────────────────────────────────────────────────────────┤
│ ├─ METHOD A: kubectl argo rollouts promote (direct API)  │
│ ├─ METHOD B: Git path flip (6-deployment-switch workflow) │
│ ├─ Either method updates service selectors:               │
│ │  ├─ activeService → v2 pods (LIVE TRAFFIC)             │
│ │  └─ previewService → v1 pods (ready for next)           │
│ └─ Traffic switches < 1 second                            │
└────────────────────────────────────────────────────────────┘
                          ↓
┌────────────────────────────────────────────────────────────┐
│ 9. PRODUCTION SERVING (Blue-Green Active)                 │
├────────────────────────────────────────────────────────────┤
│ ├─ app.trialphase.shop → active-svc → v2 pods (LIVE)     │
│ ├─ appdev.trialphase.shop → preview-svc → v1 pods        │
│ ├─ Zero downtime during promotion                         │
│ └─ v1 pods remain for instant rollback                    │
└────────────────────────────────────────────────────────────┘
                          ↓
┌────────────────────────────────────────────────────────────┐
│ 10. ROLLBACK (Anytime, Instantly)                         │
├────────────────────────────────────────────────────────────┤
│ ├─ kubectl argo rollouts promote (reverses selectors)     │
│ ├─ Production traffic → v1 pods immediately               │
│ ├─ Zero downtime, no pod restarts                         │
│ └─ Full audit trail preserved                             │
└────────────────────────────────────────────────────────────┘
```

---

This comprehensive technical reference documents every file, parameter, and process in the AgroCdAppDeploy project on the applicationsetup-Aniket-ArgoRollout-BG branch. It serves as the master reference for understanding the complete DevOps pipeline from infrastructure to blue-green deployment.
