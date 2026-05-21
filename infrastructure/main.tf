# --- Data sources to get available AZs in the chosen region ---
data "aws_availability_zones" "available" {
  state = "available"
}

# --- Local variables for networking configuration ---
locals {
  vpc_cidr             = "10.0.0.0/16"
  public_subnet_cidrs  = ["10.0.1.0/24", "10.0.2.0/24"]
  private_subnet_cidrs = ["10.0.101.0/24", "10.0.102.0/24"]
  availability_zones   = slice(data.aws_availability_zones.available.names, 0, 2)
}

# --- Networking Module ---
module "vpc" {
  source = "./modules/vpc"

  project_name         = var.project_name
  vpc_cidr             = local.vpc_cidr
  public_subnet_cidrs  = local.public_subnet_cidrs
  private_subnet_cidrs = local.private_subnet_cidrs
  availability_zones   = local.availability_zones
}

# --- EKS Cluster Module ---
module "eks" {
  source = "./modules/eks"

  project_name       = var.project_name
  cluster_version    = var.cluster_version
  private_subnet_ids = module.vpc.private_subnet_ids
  instance_types     = var.instance_types
  
  # Node group scaling
  desired_size       = 2
  max_size           = 3
  min_size           = 1
}


#---------- Change after the LOCAL Access Issue ----------------
#ISSUE : When bootstraping the IAM User in the EKS Cluster, ITS IDENTITY IS CREATED INSIDE THE CLUSTER [with master acces]
# For GitHub IAM User --> Since Bootstraped, this User has both Authentication and authorization
                          # It can talk the EKs API and has RBAC permissions in K8

# For the Local IAM User --> EKs allows authentication via the IAM [Hence, we did not get issue while updating kubeconfig]
                            # Till here aws knew that we are the same IAM user, AUTHENTICATEd
                            # PROBLEM IS HERE : This user is not mapped in the aws auth configMap 
                            
                            
# Means,Bootstraping[concept tried earlier] --> AUTOMATICALLY GIVES THE CLUSTER CREATOR IAM ENTITY RBAC RIGHTs
        # Therefore the IAM User [whoever created the Cluster] was never added to the aws-auth ConfigMap
        # So authentication was passing from the AWS side
        # Authorization was failing from the RBAC side because IAM user was never added to the aws-auth ConfigMap

#---------------------------------------------------------------------------------------------------------------------------------------------
# SECTION : To add the IAM User to the aws-auth ConfigMap, 
# --------------------> granting it admin privileges.

#  Using here "kubernetes_config_map_v1" to ensure that it safely merges the changes without overwriting the entire ConfigMap
resource "kubernetes_config_map_v1" "aws_auth" {
  metadata {
    name      = "aws-auth"
    namespace = "kube-system"
  }

  data = {
  # creates a mapping in the aws-auth ConfigMap that tells Kubernetes 
  #how to handle requests from the EC2 Ins (worker nodes)

 
    "mapRoles" = yamlencode([
      {
        rolearn  = module.eks.node_role_arn
        username = "system:node:{{EC2PrivateDNSName}}"
        groups = [
          "system:bootstrappers",
          "system:nodes",
        ]
      },
    ])

    # admin user, giving  access to the IAM user.
    "mapUsers" = yamlencode([
      {
        # MAIN LOGIC: Taking the IAM User ARN on the flow and splitting the username from it after "/"
        userarn  = var.cluster_creator_arn
        username = split("/", var.cluster_creator_arn)[1]
        groups   = ["system:masters"]
      },
    ])
  }


# Making sure that the eks cluster is created
  depends_on = [module.eks]
}


#RDS
# --- Security Group for RDS ---
resource "aws_security_group" "rds_sg" {
  name        = "local-rds-postgres-sg"
  description = "Allow inbound PostgreSQL traffic"
  
  # Grabbing the VPC ID from your VPC module
  vpc_id      = module.vpc.vpc_id 

  ingress {
    description = "PostgreSQL access"
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] 
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "rds-security-group"
  }
}

# --- RDS Database Module ---
module "rds_postgres" {
  source = "./modules/rds"

  environment = "dev"
  
  # FIX: Matched your exact VPC module output
  subnet_ids             = module.vpc.private_subnet_ids 
  vpc_security_group_ids = [aws_security_group.rds_sg.id]

  # Database Credentials (matches what your backend expects)
  db_name     = "backenddb"
  db_username = "dbadmin"
  db_password = "dbpassword123"

  tags = {
    Project = "GitOps-Local"
  }
}

output "database_endpoint" {
  value = module.rds_postgres.db_endpoint
}