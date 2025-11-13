# Create 3 s3 buckets: Raw bucket to store API responses, Curated bucket for storing parquet files, scripts bucket for storing glue job scripts
# Add versioning to each bucket
# Add lifecycle policies to each bucket (e.g. delete raw data after 30 days) - no lifecycle rule needed for scripts bucket
# Add tags to all s3 buckets relating to env, project

# S3 bucket for raw API data

resource "aws_s3_bucket" "raw_bucket" {
  bucket        = var.raw_bucket_name
  force_destroy = true

  tags = {
    Name    = "${var.project_name}-raw-bucket-${var.environment}"
    Layer   = "raw"
    Purpose = "API raw data storage"
  }
}

resource "aws_s3_bucket_versioning" "raw_bucket_versioning" {
  bucket = aws_s3_bucket.raw_bucket.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "raw_bucket_encryption" {
  bucket = aws_s3_bucket.raw_bucket.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "raw_bucket_public_access_block" {
  bucket = aws_s3_bucket.raw_bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_lifecycle_configuration" "raw_bucket_lifecycle" {
  bucket = aws_s3_bucket.raw_bucket.id

  rule {
    id     = "delete-raw-data-after-30-days"
    status = "Enabled"

    expiration {
      days = 30
    }
  }
}

# Curated bucket for storing parquet files 

resource "aws_s3_bucket" "curated_bucket" {
  bucket        = var.curated_bucket_name
  force_destroy = true

  tags = {
    Name    = "${var.project_name}-curated-bucket-${var.environment}"
    Layer   = "Curated"
    Purpose = "Curated bucket for parquet files storage"
  }
}

resource "aws_s3_bucket_versioning" "curated_bucket_versioning" {
  bucket = aws_s3_bucket.curated_bucket.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "curated_bucket_encryption" {
  bucket = aws_s3_bucket.curated_bucket.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "curated_bucket_public_access_block" {
  bucket = aws_s3_bucket.curated_bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Scripts bucket for storing glue scripts

resource "aws_s3_bucket" "scripts_bucket" {
  bucket        = var.scripts_bucket_name
  force_destroy = true

  tags = {
    Name    = "${var.project_name}-scripts-bucket-${var.environment}"
    Layer   = "raw"
    Purpose = "Storing glue job scripts"
  }
}

resource "aws_s3_bucket_versioning" "scripts_bucket_versioning" {
  bucket = aws_s3_bucket.scripts_bucket.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "scripts_bucket_encryption" {
  bucket = aws_s3_bucket.scripts_bucket.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "scripts_bucket_public_access_block" {
  bucket = aws_s3_bucket.scripts_bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}