# Flask & Express Deployment on AWS ECS with Terraform

## 📋 Project Overview

This project automatically deploys two web applications (Flask backend and Express frontend) to AWS cloud using Docker containers. Everything is managed by Terraform, which means you can create or destroy the entire infrastructure with simple commands.

### What This Project Does:
- Creates a complete cloud infrastructure on AWS
- Deploys Flask (Python backend) and Express (Node.js frontend) applications
- Sets up automatic communication between services
- Provides load balancing for high availability
- Monitors applications with logging

## 🏗️ Architecture

**Simple Explanation**: Think of this as building a complete city infrastructure:

- **VPC (Virtual Private Cloud)**: Your private neighborhood in AWS cloud
- **Subnets**: Different streets in your neighborhood (public and private)
- **ECS Fargate**: Automated container management (no servers to manage!)
- **ECR (Elastic Container Registry)**: Storage for your Docker images
- **ALB (Application Load Balancer)**: Traffic cop directing users to your apps
- **Service Connect**: Phone directory so services can find each other
- **CloudWatch**: Security cameras recording everything that happens

## 📸 Architecture & Screenshots

### 📐 Architecture Diagrams

**Interactive Diagrams (Mermaid)**: See [ARCHITECTURE.md](ARCHITECTURE.md)
- System Architecture
- Sequence Diagrams
- Network Security Flow
- Data Flow Diagram
- Cost Breakdown
- Deployment Flow

**Simple ASCII Diagrams**: See [ARCHITECTURE_ASCII.md](ARCHITECTURE_ASCII.md)
- Quick reference diagrams
- Terminal-friendly format
- Request flow visualization

### 📷 Project Screenshots

> **Note**: Add your actual screenshots to a `screenshots/` folder

#### AWS Console - ECS Cluster
<p align="center">
<img width="1605" height="628" alt="image" src="https://github.com/user-attachments/assets/e07d1590-01af-4372-afb9-bac14e2a5189" />
</p>

*Screenshot of running ECS cluster with both services*

#### AWS Console - Load Balancer
<p align="center">
<img width="1625" height="444" alt="image" src="https://github.com/user-attachments/assets/753d1194-e140-4330-82a9-93563ece6358" />
</p>

*Screenshot of Application Load Balancer configuration*

#### Target Groups Health
<p align="center">
<img width="1642" height="265" alt="image" src="https://github.com/user-attachments/assets/79bd7a2a-9cfb-4b42-bb30-8b0274a98d08" />
<img width="1638" height="292" alt="image" src="https://github.com/user-attachments/assets/3821b55f-1374-4303-a740-ca690d8cc60b" />
</p>

*Screenshot showing healthy targets*

#### Flask Application Running
<p align="center">
<img width="288" height="142" alt="image" src="https://github.com/user-attachments/assets/8f4f3924-71bc-4a62-8f0e-85f5add09b62" />
</p>
<p align="center">
<img width="278" height="66" alt="image" src="https://github.com/user-attachments/assets/90de41ed-3473-46ca-a346-0d6022c78e51" />
</p>

*Screenshot of Flask backend API response*

#### Express Application Running
<p align="center">
<img width="303" height="416" alt="image" src="https://github.com/user-attachments/assets/bfae303b-a3e9-4ead-a35b-b89df7162f25" />
</p>

*Screenshot of Express frontend interface*

#### CloudWatch Logs
<p align="center">
<img width="575" height="546" alt="image" src="https://github.com/user-attachments/assets/9587672a-c455-4b5d-bb86-675086b9c5f9" />
</p>
<p align="center">
<img width="475" height="351" alt="image" src="https://github.com/user-attachments/assets/116aae47-8784-45a7-91c7-2efe0fad8381" />
</p>

*Screenshot of container logs with KMS encryption*

#### ECR Repositories
<p align="center">
<img width="376" height="279" alt="image" src="https://github.com/user-attachments/assets/6da0164c-6eaf-46a2-ad7d-bd2fbf005216" />
</p>

*Screenshot of Docker images in ECR*

#### VPC Network Diagram
<p align="center">
<img width="1609" height="339" alt="image" src="https://github.com/user-attachments/assets/e3e84d13-1222-420d-8573-19495c4c245c" />
</p>

*Screenshot of VPC resource map from AWS Console*

---

## ✅ Prerequisites

### What You Need Before Starting:

1. **AWS Account**: Sign up at [aws.amazon.com](https://aws.amazon.com)
2. **AWS CLI**: Install from [here](https://aws.amazon.com/cli/)
   ```bash
   # Verify installation
   aws --version
   ```
3. **Terraform**: Install from [terraform.io](https://www.terraform.io/downloads)
   ```bash
   # Verify installation
   terraform --version
   ```
4. **Docker**: Install from [docker.com](https://www.docker.com/get-started)
   ```bash
   # Verify installation
   docker --version
   ```
5. **Your Applications**: Flask and Express Docker images ready

### AWS Setup Required:
- **S3 Bucket**: `<your-s3-bucket-name>` (for storing Terraform state)
- **DynamoDB Table**: `<your-dynamodb-table-name>` (prevents multiple people from changing infrastructure simultaneously)

## 📁 Project Structure

```
.
├── main.tf           # AWS provider and backend configuration
├── variables.tf      # Configurable values (region, CIDR blocks)
├── vpc.tf           # Network setup (VPC, subnets, security groups)
├── ecr.tf           # Docker image repositories
├── ecs.tf           # Container cluster and services
├── alb.tf           # Load balancer configuration
├── roles.tf         # IAM permissions
├── logs.tf          # CloudWatch logging setup
├── outputs.tf       # URLs and important information after deployment
└── README.md        # This file
```

## 🔧 Infrastructure Components Explained

### 1. Networking (vpc.tf)
**What it does**: Creates your private network in AWS
- Custom VPC (your private cloud space)
- 2 public subnets (accessible from internet) across different availability zones
- 2 private subnets (internal only)
- Internet Gateway (door to the internet)
- Security groups (firewall rules)

### 2. Container Registry (ecr.tf)
**What it does**: Stores your Docker images
- `flask-backend` repository
- `express-frontend` repository

### 3. ECS Cluster (ecs.tf)
**What it does**: Runs your containers without managing servers
- Cluster with monitoring enabled
- Flask service (256 CPU, 512 MB RAM)
- Express service (256 CPU, 512 MB RAM)
- Automatic service discovery

### 4. Load Balancer (alb.tf)
**What it does**: Distributes traffic to your applications
- Routes port 80 traffic to Express (frontend)
- Routes port 5000 traffic to Flask (backend)
- Health checks to ensure apps are running

### 5. IAM Roles (roles.tf)
**What it does**: Gives permissions to ECS to access other AWS services
- Pull images from ECR
- Write logs to CloudWatch

### 6. Logging (logs.tf)
**What it does**: Stores application logs for debugging
- Separate log groups for Flask and Express
- 1-day retention (configurable)

## 🚀 Step-by-Step Deployment Guide

### Step 1: Configure AWS Credentials
```bash
# Configure your AWS credentials
aws configure
# Enter your AWS Access Key ID
# Enter your AWS Secret Access Key
# Enter your default region (us-east-1)
# Enter output format (json)
```

### Step 2: Create S3 Bucket and DynamoDB Table
```bash
# Create S3 bucket for Terraform state
aws s3 mb s3://<your-s3-bucket-name> --region us-east-1

# Create DynamoDB table for state locking
aws dynamodb create-table \
  --table-name <your-dynamodb-table-name> \
  --attribute-definitions AttributeName=LockID,AttributeType=S \
  --key-schema AttributeName=LockID,KeyType=HASH \
  --billing-mode PAY_PER_REQUEST \
  --region us-east-1
```

### Step 3: Initialize Terraform
```bash
# Navigate to project directory
cd "Deploy Both Flask and Express Using Docker Container and AWS VPC ECR ECS Services"

# Initialize Terraform (downloads required providers)
terraform init
```

### Step 4: Review Infrastructure Plan
```bash
# See what Terraform will create
terraform plan
```

### Step 5: Create ECR Repositories First
```bash
# Apply only ECR resources first
terraform apply -target=aws_ecr_repository.flask_backend -target=aws_ecr_repository.express_frontend
```

### Step 6: Build and Push Docker Images

**Get your AWS account ID:**
```bash
aws sts get-caller-identity --query Account --output text
```

**Login to ECR:**
```bash
aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin <your-account-id>.dkr.ecr.us-east-1.amazonaws.com
```

**Build, tag, and push Flask image:**
```bash
# Build your Flask app
docker build -t flask-app ./flask-app

# Tag for ECR
docker tag flask-app:latest <your-account-id>.dkr.ecr.us-east-1.amazonaws.com/flask-backend:latest

# Push to ECR
docker push <your-account-id>.dkr.ecr.us-east-1.amazonaws.com/flask-backend:latest
```

**Build, tag, and push Express image:**
```bash
# Build your Express app
docker build -t express-app ./express-app

# Tag for ECR
docker tag express-app:latest <your-account-id>.dkr.ecr.us-east-1.amazonaws.com/express-frontend:latest

# Push to ECR
docker push <your-account-id>.dkr.ecr.us-east-1.amazonaws.com/express-frontend:latest
```

### Step 7: Deploy Complete Infrastructure
```bash
# Deploy everything
terraform apply

# Type 'yes' when prompted
```

**⏱️ Deployment takes approximately 5-10 minutes**

### Step 8: Access Your Applications

After successful deployment, Terraform will output:
```
alb_dns_name = "<your-alb-dns-name>"
flask_url = "http://<your-alb-dns-name>:5000"
express_url = "http://<your-alb-dns-name>:80"
```

**Test your applications:**
```bash
# Test Express frontend
curl http://<alb-dns-name>:80

# Test Flask backend
curl http://<alb-dns-name>:5000
```

Or open the URLs in your web browser!

## ⚙️ Configuration Options

### Customizable Variables (variables.tf)

You can modify these values by creating a `terraform.tfvars` file:

```hcl
aws_region = "us-west-2"  # Change AWS region
vpc_cidr = "10.0.0.0/16"  # Change VPC IP range
public_subnet_cidrs = ["10.0.1.0/24", "10.0.2.0/24"]
private_subnet_cidrs = ["10.0.10.0/24", "10.0.11.0/24"]
```

### What You Get After Deployment (outputs.tf)

- `alb_dns_name`: Your load balancer URL
- `flask_url`: Direct link to Flask backend
- `express_url`: Direct link to Express frontend
- `flask_ecr_repo_url`: Where your Flask Docker image is stored
- `express_ecr_repo_url`: Where your Express Docker image is stored

## 🔗 How Services Communicate

**Simple Explanation**: Express (frontend) needs to talk to Flask (backend)

1. **Service Discovery**: Flask registers itself as `flask-backend.apps.local`
2. **Express Connection**: Express finds Flask automatically using the service name
3. **Security**: Only allowed services can talk to each other
4. **Load Balancer**: Routes external traffic to the correct service

```
User → Load Balancer → Express (port 80)
                     → Flask (port 5000)

Express → Service Connect → Flask (internal communication)
```

## 🔒 Security Features

- ✅ Load Balancer only accepts HTTP traffic on ports 80 and 5000
- ✅ ALB drops invalid HTTP headers for security
- ✅ ECS containers only accept traffic from Load Balancer
- ✅ Services can communicate with each other securely
- ✅ Outbound internet access for pulling Docker images
- ✅ No SSH access needed (serverless!)
- ✅ Logs stored securely in CloudWatch with KMS encryption
- ✅ KMS key rotation enabled for log encryption
- ⚠️ HTTP only (no HTTPS) - See [HTTPS_SETUP.md](HTTPS_SETUP.md) for production configuration

## 🧹 Cleanup (Destroy Infrastructure)

**⚠️ Warning**: This will delete everything and stop all charges

```bash
# Destroy all resources
terraform destroy

# Type 'yes' when prompted
```

**What gets deleted:**
- All running containers
- Load balancer
- VPC and networking
- ECR repositories (Docker images)
- CloudWatch logs
- IAM roles

**What remains:**
- S3 bucket (Terraform state)
- DynamoDB table (state lock)

## 🐛 Troubleshooting

### Issue: Terraform init fails
**Solution**: Check AWS credentials and S3 bucket exists
```bash
aws s3 ls s3://<your-s3-bucket-name>
```

### Issue: Docker push fails
**Solution**: Re-authenticate with ECR
```bash
aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin <account-id>.dkr.ecr.us-east-1.amazonaws.com
```

### Issue: ECS tasks not starting
**Solution**: Check CloudWatch logs
```bash
aws logs tail /ecs/flask-backend --follow
aws logs tail /ecs/express-frontend --follow
```

### Issue: Can't access applications
**Solution**: Wait 2-3 minutes for health checks to pass, then check target group health
```bash
aws elbv2 describe-target-health --target-group-arn <target-group-arn>
```

## 💰 Cost Estimation

**Approximate monthly costs (us-east-1):**
- ECS Fargate (2 tasks): ~$30-40/month
- Application Load Balancer: ~$20/month
- Data transfer: ~$5-10/month
- CloudWatch Logs: ~$1-2/month
- **Total**: ~$56-72/month

**💡 Tip**: Destroy resources when not in use to save costs!

## 📚 Additional Resources

- [Terraform AWS Provider Documentation](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [AWS ECS Documentation](https://docs.aws.amazon.com/ecs/)
- [AWS Fargate Pricing](https://aws.amazon.com/fargate/pricing/)
- [Docker Documentation](https://docs.docker.com/)

## 📝 Important Notes

- ⚠️ ECS tasks run in public subnets (for simplicity). For production, use private subnets with NAT Gateway
- ⚠️ HTTP only (no HTTPS). For production, add SSL certificate to ALB
- ✅ Health checks configured with extended thresholds for startup time
- ✅ Circuit breaker enabled for automatic rollback on failed deployments
- ✅ State stored in S3 with DynamoDB locking for team collaboration
- ✅ Container Insights enabled for detailed monitoring

## 🤝 Contributing

Feel free to submit issues and enhancement requests!

## 📄 License

This project is open source and available under the MIT License.

---

**Happy Deploying! 🚀**
