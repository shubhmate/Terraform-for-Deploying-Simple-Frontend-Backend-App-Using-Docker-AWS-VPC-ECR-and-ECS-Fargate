# Simple Architecture Diagram (ASCII)

## High-Level Architecture

```
┌─────────────────────────────────────────────────────────────────────────┐
│                              AWS CLOUD                                   │
│  ┌───────────────────────────────────────────────────────────────────┐  │
│  │                    VPC (10.0.0.0/16)                              │  │
│  │                                                                   │  │
│  │  ┌─────────────────────────────────────────────────────────────┐ │  │
│  │  │              Internet Gateway                                │ │  │
│  │  └────────────────────┬────────────────────────────────────────┘ │  │
│  │                       │                                           │  │
│  │  ┌────────────────────▼────────────────────────────────────────┐ │  │
│  │  │     Application Load Balancer (ALB)                         │ │  │
│  │  │     • Port 80  → Express Frontend                           │ │  │
│  │  │     • Port 5000 → Flask Backend                             │ │  │
│  │  └────────┬─────────────────────────┬────────────────────────┘  │  │
│  │           │                         │                            │  │
│  │  ┌────────▼─────────┐      ┌───────▼──────────┐                │  │
│  │  │  Public Subnet   │      │  Public Subnet   │                │  │
│  │  │  10.0.1.0/24     │      │  10.0.2.0/24     │                │  │
│  │  │  (AZ-1)          │      │  (AZ-2)          │                │  │
│  │  │                  │      │                  │                │  │
│  │  │ ┌──────────────┐ │      │ ┌──────────────┐ │                │  │
│  │  │ │   Express    │ │      │ │    Flask     │ │                │  │
│  │  │ │  Container   │◄┼──────┼─┤  Container   │ │                │  │
│  │  │ │  Port: 3000  │ │      │ │  Port: 5000  │ │                │  │
│  │  │ │  CPU: 256    │ │      │ │  CPU: 256    │ │                │  │
│  │  │ │  RAM: 512MB  │ │      │ │  RAM: 512MB  │ │                │  │
│  │  │ └──────┬───────┘ │      │ └──────┬───────┘ │                │  │
│  │  │        │         │      │        │         │                │  │
│  │  └────────┼─────────┘      └────────┼─────────┘                │  │
│  │           │                         │                            │  │
│  │           └─────────┬───────────────┘                            │  │
│  │                     │                                            │  │
│  │  ┌──────────────────▼──────────────────────────────────────┐    │  │
│  │  │         Service Connect (apps.local)                    │    │  │
│  │  │         • flask-backend.apps.local → Flask IP           │    │  │
│  │  └─────────────────────────────────────────────────────────┘    │  │
│  │                                                                   │  │
│  │  ┌─────────────────┐      ┌─────────────────┐                   │  │
│  │  │ Private Subnet  │      │ Private Subnet  │                   │  │
│  │  │ 10.0.10.0/24    │      │ 10.0.11.0/24    │                   │  │
│  │  │ (Reserved)      │      │ (Reserved)      │                   │  │
│  │  └─────────────────┘      └─────────────────┘                   │  │
│  └───────────────────────────────────────────────────────────────────┘  │
│                                                                          │
│  ┌───────────────────────────────────────────────────────────────────┐  │
│  │                    Supporting Services                            │  │
│  │                                                                   │  │
│  │  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐          │  │
│  │  │     ECR      │  │  CloudWatch  │  │   KMS Key    │          │  │
│  │  │  flask-      │  │    Logs      │  │  Encryption  │          │  │
│  │  │  backend     │  │  /ecs/flask  │  │  (Rotation   │          │  │
│  │  │              │  │  /ecs/express│  │   Enabled)   │          │  │
│  │  │  express-    │  │              │  │              │          │  │
│  │  │  frontend    │  │              │  │              │          │  │
│  │  └──────────────┘  └──────────────┘  └──────────────┘          │  │
│  │                                                                   │  │
│  │  ┌──────────────┐  ┌──────────────┐                             │  │
│  │  │  IAM Role    │  │  Security    │                             │  │
│  │  │  ECS Task    │  │  Groups      │                             │  │
│  │  │  Execution   │  │  • ALB SG    │                             │  │
│  │  │              │  │  • ECS SG    │                             │  │
│  │  └──────────────┘  └──────────────┘                             │  │
│  └───────────────────────────────────────────────────────────────────┘  │
│                                                                          │
│  ┌───────────────────────────────────────────────────────────────────┐  │
│  │                    State Management                               │  │
│  │  ┌──────────────┐              ┌──────────────┐                  │  │
│  │  │  S3 Bucket   │              │  DynamoDB    │                  │  │
│  │  │  Terraform   │              │  State Lock  │                  │  │
│  │  │  State       │              │  Table       │                  │  │
│  │  └──────────────┘              └──────────────┘                  │  │
│  └───────────────────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────────────┘

                              ▲
                              │
                    ┌─────────┴─────────┐
                    │   👤 End Users    │
                    │   HTTP Requests   │
                    └───────────────────┘
```

## Request Flow

```
┌──────┐     ┌─────┐     ┌─────────┐     ┌───────┐
│ User │────▶│ ALB │────▶│ Express │────▶│ Flask │
└──────┘     └─────┘     └─────────┘     └───────┘
   │            │             │               │
   │            │             │               │
   │            │             ▼               ▼
   │            │         ┌───────────────────────┐
   │            │         │  Service Connect DNS  │
   │            │         │  flask-backend.local  │
   │            │         └───────────────────────┘
   │            │                     │
   │            ▼                     ▼
   │      ┌──────────┐         ┌──────────┐
   │      │ Target   │         │ CloudW   │
   │      │ Groups   │         │ Logs     │
   │      └──────────┘         └──────────┘
   │
   ◀──────────────────────────────────────────────
              HTTP Response
```

## Security Groups

```
┌─────────────────────────────────────────────────────────┐
│              ALB Security Group                         │
│  ┌───────────────────────────────────────────────────┐  │
│  │  Inbound Rules:                                   │  │
│  │  • Port 80   ← 0.0.0.0/0 (Internet)              │  │
│  │  • Port 5000 ← 0.0.0.0/0 (Internet)              │  │
│  │                                                   │  │
│  │  Outbound Rules:                                  │  │
│  │  • All Traffic → 0.0.0.0/0                       │  │
│  └───────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────┐
│            ECS Tasks Security Group                     │
│  ┌───────────────────────────────────────────────────┐  │
│  │  Inbound Rules:                                   │  │
│  │  • Port 3000 ← ALB Security Group                │  │
│  │  • Port 5000 ← ALB Security Group                │  │
│  │  • Port 5000 ← Self (Inter-service)              │  │
│  │                                                   │  │
│  │  Outbound Rules:                                  │  │
│  │  • All Traffic → 0.0.0.0/0 (ECR, Internet)       │  │
│  └───────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────┘
```

## Service Communication

```
┌─────────────────────────────────────────────────────────┐
│                Express Container                        │
│                                                         │
│  1. Needs to call Flask API                            │
│  2. Queries: flask-backend.apps.local                  │
│     ┌───────────────────────────────────────┐          │
│     │      Service Connect DNS              │          │
│     │  Resolves to Flask Container IP       │          │
│     └───────────────────────────────────────┘          │
│  3. Makes HTTP call to resolved IP:5000                │
└─────────────────────────────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────┐
│                 Flask Container                         │
│                                                         │
│  1. Registered as flask-backend.apps.local             │
│  2. Receives request from Express                      │
│  3. Processes and returns JSON response                │
└─────────────────────────────────────────────────────────┘
```

## Deployment Steps

```
Step 1: Initialize
┌──────────────┐
│ terraform    │
│ init         │
└──────┬───────┘
       │
       ▼
Step 2: Create ECR
┌──────────────┐
│ Create ECR   │
│ Repositories │
└──────┬───────┘
       │
       ▼
Step 3: Build & Push
┌──────────────┐     ┌──────────────┐
│ Build Flask  │     │ Build Express│
│ Docker Image │     │ Docker Image │
└──────┬───────┘     └──────┬───────┘
       │                    │
       └──────────┬─────────┘
                  ▼
Step 4: Deploy Infrastructure
┌──────────────┐
│ terraform    │
│ apply        │
└──────┬───────┘
       │
       ▼
Step 5: Verify
┌──────────────┐
│ Health Checks│
│ Pass         │
└──────┬───────┘
       │
       ▼
┌──────────────┐
│ ✅ DEPLOYED  │
└──────────────┘
```

## Cost Breakdown (Monthly)

```
┌─────────────────────────────────────────┐
│  Service              Cost              │
├─────────────────────────────────────────┤
│  ECS Fargate          $30-40            │
│  ├─ Flask Task        $15-20            │
│  └─ Express Task      $15-20            │
├─────────────────────────────────────────┤
│  Load Balancer        $20               │
├─────────────────────────────────────────┤
│  Data Transfer        $5-10             │
├─────────────────────────────────────────┤
│  CloudWatch Logs      $1-2              │
├─────────────────────────────────────────┤
│  ECR Storage          $1                │
├─────────────────────────────────────────┤
│  KMS Key              $1                │
├─────────────────────────────────────────┤
│  TOTAL                $58-74/month      │
└─────────────────────────────────────────┘
```

## Key Features

```
✅ Multi-AZ Deployment
   ├─ High Availability
   └─ Fault Tolerance

✅ Auto-Scaling Ready
   ├─ Horizontal Scaling
   └─ Load Distribution

✅ Secure by Design
   ├─ Security Groups
   ├─ KMS Encryption
   └─ IAM Roles

✅ Fully Managed
   ├─ No Server Management
   ├─ Auto-Patching
   └─ Serverless Containers

✅ Observable
   ├─ CloudWatch Logs
   ├─ Container Insights
   └─ Health Checks

✅ Infrastructure as Code
   ├─ Version Controlled
   ├─ Reproducible
   └─ Documented
```
