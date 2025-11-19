#!/bin/bash 
set -e

echo "Packaging Lambda ingestion function..."

cd "$(dirname "$0")/../src/lambda"
mkdir -p build

# Package Ingestion Lambda
echo ""
echo "Packaging ingestion Lambda..."
rm -rf package

# Install dependencies
python3 -m pip install pandas boto3 --quiet -t package/

cp lambda_ingestion.py package/

cd package
zip -r ../build/lambda_ingestion.zip . -q
cd ..

LAMBDA_INGESTION_SIZE=$(du -h build/lambda_ingestion.zip | cut -f1)
echo "Ingestion Lambda: $LAMBDA_INGESTION_SIZE"
rm -rf package

echo ""
echo "Summary:"
echo ""
echo "Lambda Packaged: lambda_ingestion.zip created successfully, size: $LAMBDA_INGESTION_SIZE"