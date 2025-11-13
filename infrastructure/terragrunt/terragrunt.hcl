# Root terragrunt configuration - suitable for all environments 

# Load environment variables, add common tags for all resources

locals {
  env_vars = read_terragrunt_config(find_in_parent_folders("env.hcl"))
  
  common_tags = {
    Project     = "scheduled-etl"
    ManagedBy   = "Terragrunt"
    Terraform   = "true"
    Repository  = "scheduled-etl-pipeline"
  }
}

# Configure terragrunt to use s3 backend

remote_state {
  backend = "s3"
  generate = {
    path      = "backend.tf"
    if_exists = "overwrite_terragrunt"
  }
  config = {
    bucket         = "serverless-etl-terraform-state-${local.env_vars.locals.environment}"
    key            = "${path_relative_to_include()}/terraform.tfstate"
    region         = local.env_vars.locals.aws_region
    encrypt        = true
    dynamodb_table = "terraform-locks"
  }
}

# Generate provider configuration
# Configuee terraform settings - TODO: Point to your terraform modules directory

