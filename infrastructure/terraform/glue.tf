# TODO: Create Glue resources
# Create glue database, metadata catalog 

resource "aws_glue_catalog_database" "glue_database" {
  name = "${var.project_name}_${var.environment}_glue_db"

  tags = merge(var.common_tags, {
    Name = "${var.project_name}-${var.environment}-glue-database"
  })
}

# Upload glue scripts from src/glue to s3 script bucket 

resource "aws_s3_bucket_object" "glue_scripts" {
  for_each = fileset("${path.module}/../../src/glue", "**/*.py")

  bucket = aws_s3_bucket.scripts_bucket.id
  key    = each.value
  source = "${path.module}/../../src/glue/${each.value}"

  etag = filemd5("${path.module}/../../src/glue/${each.value}")
}

# Glue job to transform data, configure worker type and number (G.1x with 2 workers, timeout = 30 min)

resource "aws_glue_job" "glue_etl_job" {
  name     = "${var.project_name}-${var.environment}-glue-etl-job"
  role_arn = aws_iam_role.glue_execution_role.arn

  command {
    name            = "glueetl"
    script_location = "s3://${aws_s3_bucket.scripts_bucket.bucket}/etl_job.py"
    python_version  = "3"
  }

  default_arguments = {
    "--job-language"                     = "python"
    "--continuous-log-logGroup"          = "/aws-glue/jobs"
    "--enable-continuous-cloudwatch-log" = "true"
    "--enable-continuous-log-filter"     = "true"
    "--enable-metrics"                   = ""
    "--enable-auto-scaling"              = "true"
    "--tempdir"                          = "s3://${aws_s3_bucket.scripts_bucket.bucket}/temp/"

    "--SOURCE_BUCKET" = aws_s3_bucket.raw_bucket.bucket
    "--TARGET_BUCKET" = aws_s3_bucket.curated_bucket.bucket
    "--GLUE_DATABASE" = aws_glue_catalog_database.glue_database.name
  }

  glue_version      = var.glue_version
  worker_type       = var.glue_worker_type
  number_of_workers = var.glue_number_of_workers
  timeout           = var.glue_job_timeout

  tags = merge(var.common_tags, {
    Name = "${var.project_name}-${var.environment}-glue-etl-job"
  })
}

# Create glue crawler which scans curated bucket and updates glue metadata catalog

resource "aws_glue_crawler" "glue_crawler" {
  name          = "${var.project_name}-${var.environment}-glue-crawler"
  database_name = aws_glue_catalog_database.glue_database.name
  role          = aws_iam_role.glue_execution_role.arn
  table_prefix  = "curated_"

  s3_target {
    path = "s3://${aws_s3_bucket.curated_bucket.bucket}/"
  }

  schema_change_policy {
    update_behavior = "UPDATE_IN_DATABASE"
    delete_behavior = "LOG"
  }

  tags = merge(var.common_tags, {
    Name = "${var.project_name}-${var.environment}-glue-crawler"
  })
}