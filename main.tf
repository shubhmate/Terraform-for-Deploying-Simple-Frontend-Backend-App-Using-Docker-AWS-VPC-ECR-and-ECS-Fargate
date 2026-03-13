# provider configuration for AWS
provider "aws" {
  region = var.aws_region
}

# terraform.tfstate will be stored in S3 for state management and collaboration 
terraform {
  backend "s3" {
    bucket         = "YOUR_S3_BUCKET_NAME" # Replace with your actual S3 bucket name
    key            = "deploy/flask-express-docker-aws-services-vpc-ecr-ecs/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "terraform-state-lock" # Optional, for state locking
  }
}