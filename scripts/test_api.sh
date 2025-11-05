#!/bin/bash
set -e

echo "🧪 Testing API ingestion Lambda..."

# Get lambda function name from Terraform output
# Add a test event 
# Invoke the lambda function using AWS CLI
# Check and display response for success status