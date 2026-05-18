terraform {
  # Passed dynamically during workflow execution via `terraform init -backend-config="..."`
  backend "s3" {}
}

# =========================================================================================
# ENTERPRISE VS LOCALSTACK BACKEND DOCUMENTATION:
# =========================================================================================
#
# [WHEN RUNNING LOCALLY VIA ACT + LOCALSTACK]:
# Your initialization command in your workflow step must look exactly like this:
# 
# terraform init \
#   -backend-config="bucket=ashwin11-microservice-app-s3" \
#   -backend-config="key=state/terraform.tfstate" \
#   -backend-config="region=us-east-1" \
#   -backend-config="dynamodb_table=ashwin11-microservice-app-dynamo-db" \
#   -backend-config="endpoint=http://host.docker.internal:4566" \
#   -backend-config="skip_credentials_validation=true" \
#   -backend-config="skip_metadata_api_check=true" \
#   -backend-config="use_path_style=true"
#
# [WHEN RUNNING IN REAL AWS ENTERPRISE PRODUCTION]:
# Drop all the skip/endpoint flags. Your initialization command will simplify back to standard AWS parameters:
#
# terraform init \
#   -backend-config="bucket=your-real-prod-s3-bucket" \
#   -backend-config="key=state/terraform.tfstate" \
#   -backend-config="region=us-east-1" \
#   -backend-config="dynamodb_table=your-real-prod-dynamodb-table"
# =========================================================================================