terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 4.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 2.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = ">= 2.0"
    }
  }
}

provider "aws" {
  region = var.aws_region

  # -----------------------------------------------------------------------------------
  # [LOCALSTACK TESTING CONFIGURATION] - UNCOMMENT THIS BLOCK FOR LOCAL RUNS
  # -----------------------------------------------------------------------------------
  access_key                  = "test"
  secret_key                  = "test"
  skip_credentials_validation = true
  skip_metadata_api_check     = true
  skip_requesting_account_id  = true
  s3_use_path_style           = true

  endpoints {
    ec2            = "http://host.docker.internal:4566"
    eks            = "http://host.docker.internal:4566"
    s3             = "http://host.docker.internal:4566"
    dynamodb       = "http://host.docker.internal:4566"
    iam            = "http://host.docker.internal:4566"
    route53        = "http://host.docker.internal:4566"
    secretsmanager = "http://host.docker.internal:4566"
    sts            = "http://host.docker.internal:4566"
    rds            = "http://localhost:4566"
  }
  # -----------------------------------------------------------------------------------
  # [REAL AWS ENTERPRISE CONFIGURATION] - COMMENT OUT THE BLOCK ABOVE IN PRODUCTION
  # -----------------------------------------------------------------------------------
  # In true enterprise execution, remove access_key, secret_key, skip_* rules, and 
  # endpoints completely. Let Terraform automatically assume the GitHub Actions IAM OIDC Role.
}


provider "kubernetes" {
  host                   = module.eks.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks.cluster_ca_certificate)

  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "aws"
    
    # [LOCALSTACK MODE]: Points the token generation command to the running container
    args        = ["--endpoint-url", "http://host.docker.internal:4566", "eks", "get-token", "--cluster-name", module.eks.cluster_name]
    
    # [REAL AWS ENTERPRISE MODE]: Swap with the line below when migrating to production
    # args        = ["eks", "get-token", "--cluster-name", module.eks.cluster_name]
  }
}

provider "helm" {
  kubernetes {
    host                   = module.eks.cluster_endpoint
    cluster_ca_certificate = base64decode(module.eks.cluster_ca_certificate)
    exec {
      api_version = "client.authentication.k8s.io/v1beta1"
      command     = "aws"
      
      # [LOCALSTACK MODE]: Points the Helm token generation command to the running container
      args        = ["--endpoint-url", "http://host.docker.internal:4566", "eks", "get-token", "--cluster-name", module.eks.cluster_name]
      
      # [REAL AWS ENTERPRISE MODE]: Swap with the line below when migrating to production
      # args        = ["eks", "get-token", "--cluster-name", module.eks.cluster_name]
    }
  }
}