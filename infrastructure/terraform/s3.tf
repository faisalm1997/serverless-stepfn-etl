# Create 3 s3 buckets: Raw bucket to store API responses, Curated bucket for storing parquet files, scripts bucket for storing glue job scripts
# Add versioning to each bucket
# Add lifecycle policies to each bucket (e.g. delete raw data after 30 days) - no lifecycle rule needed for scripts bucket
# Add tags to all s3 buckets relating to env, project