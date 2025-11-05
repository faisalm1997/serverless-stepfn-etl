# Root terragrunt configuration - suitable for all environments 

# Load environment variables, add common tags for all resources

locals {
  # Load environment-specific variables
  env_vars = read_terragrunt_config(find_in_parent_folders("env.hcl"))
  
  # Common tags for all resources
  common_tags = {
    Project     = "scheduled-etl"
    ManagedBy   = "Terragrunt"
    Terraform   = "true"
    Repository  = "scheduled-etl-pipeline"
  }
}

# Configure terragrunt to use s3 backend
# Generate provider configuration
# Configuee terraform settings - TODO: Point to your terraform modules directory

