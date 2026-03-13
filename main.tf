# provider configuration for AWS
provider "aws" {
  region = var.aws_region
}

# terraform.tfstate will be stored in S3 for state management and collaboration 
terraform {
  backend "s3" {
    bucket         = "s3-for-flask-and-express-on-a-single-ec2-instance" # Replace with your bucket
    key            = "deploy/flask-express-docker-aws-services-vpc-ecr-ecs/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "terraform-state-lock" # Optional, for state locking
  }
}