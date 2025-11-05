# TODO: Create IAM roles for Lambda, Glue, Step Functions
# IAM role for lambda execution 
# Lambda policy to allow s3 writes, cloudwatch logs 
# Create glue execution role, needs S3 read/write, Glue catalog access
# Create step function execution role, needs lambda invoke/glue start job permissions
# Create IAM role for eventbridge to invoke step functions
# Create IAM policy to allow starting Step Functions execution