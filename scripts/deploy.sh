#!/bin/bash 
set -e 
echo "Starting deployment of Serverless Step Function ETL pipeline..."

# Steps: package lambda > initialise terraform > plan infra > apply infra > test step function
echo "Packaging Lambda function..."
./scripts/lambda_package.sh
echo "Lambda function packaged successfully."

echo "Initializing Terraform..."
cd "$(dirname "$0")/../infrastructure/terraform"
terraform init
echo "Terraform initialized successfully."
echo "Planning Terraform deployment..."
terraform plan -out=tfplan
echo "Terraform plan created successfully."
echo "Applying Terraform deployment..."
terraform apply tfplan

echo "testing step function execution..."
aws cli stepfunctions start-execution --state-machine-arn $(terraform output -raw step_function_arn) --name "test-execution-$(date +%s)" --input '{}'
echo "step function execution started."


echo "Deployment script executed successfully."

echo "Deployment complete"