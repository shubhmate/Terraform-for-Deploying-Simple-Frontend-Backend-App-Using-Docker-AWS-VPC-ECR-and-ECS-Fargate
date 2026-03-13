# Flask & Express Deployment on AWS ECS with Terraform

This project deploys Flask (backend) and Express (frontend) applications as Docker containers on AWS ECS Fargate using Terraform infrastructure as code.

## Architecture

- **VPC**: Custom VPC with public/private subnets across 2 availability zones
- **ECS Fargate**: Serverless container orchestration for Flask and Express
- **ECR**: Container image repositories
- **ALB**: Application Load Balancer for traffic distribution
- **Service Connect**: Service discovery for inter-service communication
- **CloudWatch**: Container logging and monitoring

## Prerequisites

- AWS CLI configured with appropriate credentials
- Terraform >= 1.0
- Docker images for Flask and Express applications
- S3 bucket for Terraform state: `s3-for-flask-and-express-on-a-single-ec2-instance`
- DynamoDB table for state locking: `terraform-state-lock`

## Infrastructure Components

### Networking (vpc.tf)
- VPC with CIDR 10.0.0.0/16
- 2 public subnets (10.0.1.0/24, 10.0.2.0/24)
- 2 private subnets (10.0.10.0/24, 10.0.11.0/24)
- Internet Gateway and route tables
- Security groups for ALB and ECS tasks

### Container Registry (ecr.tf)
- `flask-backend` ECR repository
- `express-frontend` ECR repository

### ECS Cluster (ecs.tf)
- ECS cluster with Container Insights enabled
- Service Connect namespace: `apps.local`
- Flask task definition (256 CPU, 512 MB memory)
- Express task definition (256 CPU, 512 MB memory)
- Service discovery for inter-service communication

### Load Balancer (alb.tf)
- Application Load Balancer in public subnets
- Target groups for Flask (port 5000) and Express (port 3000)
- Listener on port 80 for Express frontend
- Listener on port 5000 for Flask backend

### IAM Roles (roles.tf)
- ECS task execution role with ECR and CloudWatch permissions

### Logging (logs.tf)
- CloudWatch log groups for Flask and Express containers
- 1-day log retention

## Deployment

### 1. Initialize Terraform
```bash
terraform init
```

### 2. Push Docker Images to ECR
```bash
# Login to ECR
aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin <account-id>.dkr.ecr.us-east-1.amazonaws.com

# Tag and push Flask image
docker tag flask-app:latest <flask-ecr-url>:latest
docker push <flask-ecr-url>:latest

# Tag and push Express image
docker tag express-app:latest <express-ecr-url>:latest
docker push <express-ecr-url>:latest
```

### 3. Deploy Infrastructure
```bash
terraform plan
terraform apply
```

### 4. Access Applications
After deployment, Terraform outputs the ALB DNS name:
- **Express Frontend**: `http://<alb-dns-name>:80`
- **Flask Backend**: `http://<alb-dns-name>:5000`

## Configuration

### Variables (variables.tf)
- `aws_region`: AWS region (default: us-east-1)
- `vpc_cidr`: VPC CIDR block (default: 10.0.0.0/16)
- `public_subnet_cidrs`: Public subnet CIDRs
- `private_subnet_cidrs`: Private subnet CIDRs

### Outputs (outputs.tf)
- `alb_dns_name`: Load balancer DNS name
- `flask_url`: Flask application URL
- `express_url`: Express application URL
- `flask_ecr_repo_url`: Flask ECR repository URL
- `express_ecr_repo_url`: Express ECR repository URL

## Service Communication

Express communicates with Flask using Service Connect:
- Flask service is discoverable at `flask-backend.apps.local:5000`
- Express uses socat to relay requests from localhost:5000 to Flask service
- Security groups allow traffic between services

## Security

- ALB accepts HTTP traffic on ports 80 and 5000
- ECS tasks only accept traffic from ALB
- Inter-service communication allowed via security group rules
- Outbound internet access for image pulls and updates

## Cleanup

```bash
terraform destroy
```

## Notes

- ECS tasks run in public subnets with public IPs (modify for production)
- Health checks configured with extended thresholds for startup time
- Circuit breaker enabled for automatic rollback on failed deployments
- State stored in S3 with DynamoDB locking for team collaboration
