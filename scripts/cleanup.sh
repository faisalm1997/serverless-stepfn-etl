#!/bin/bash
set -e

echo "Cleaning up Scheduled ETL Pipeline..."

# destroy infrastructure with terraform
echo "Destroying Terraform-managed infrastructure..."

cd "$(dirname "$0")/../infrastructure/terraform"
terraform destroy -auto-approve

echo "Terraform infrastructure destroyed."

# cleanup lambda and build artifacts
echo "Removing Lambda build artifacts..."
cd "$(dirname "$0")/../src/lambda"
rm -rf build package
echo "Lambda build artifacts removed."

echo "Cleanup completed successfully."
