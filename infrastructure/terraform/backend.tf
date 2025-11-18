terraform {
  backend "s3" {
    bucket         = "serverless-stepfn-etl-tf-state-bucket"
    key            = "./.terraform/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "terraform-locks"
  }
}