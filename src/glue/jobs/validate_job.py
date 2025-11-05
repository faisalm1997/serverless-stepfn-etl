# Import packages 
# Add args 
# Spark context 
# Read curated data from s3 curated bucket
# Data quality checks - count total records, null records, duplicate records and print their values 
# Determine a quality score = total records - null records - duplicate records / total records
# If quality score < 95 threshold, raise exception to fail job
# Commit job