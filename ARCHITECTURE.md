# Architecture Diagram

## System Architecture

```mermaid
graph TB
    subgraph "Users"
        User1[👤 User]
    end

    subgraph "AWS Cloud - Region: us-east-1"
        subgraph "VPC - 10.0.0.0/16"
            IGW[Internet Gateway]
            
            subgraph "Availability Zone 1"
                PubSub1[Public Subnet<br/>10.0.1.0/24]
                PrivSub1[Private Subnet<br/>10.0.10.0/24]
            end
            
            subgraph "Availability Zone 2"
                PubSub2[Public Subnet<br/>10.0.2.0/24]
                PrivSub2[Private Subnet<br/>10.0.11.0/24]
            end
            
            subgraph "Application Load Balancer"
                ALB[ALB<br/>Port 80 & 5000]
                LBSG[Security Group<br/>Allow: 80, 5000]
            end
            
            subgraph "ECS Cluster - Fargate"
                subgraph "Express Service"
                    Express1[Express Container<br/>Port 3000<br/>256 CPU / 512 MB]
                end
                
                subgraph "Flask Service"
                    Flask1[Flask Container<br/>Port 5000<br/>256 CPU / 512 MB]
                end
                
                ECSSG[Security Group<br/>Allow from ALB only]
                ServiceConnect[Service Connect<br/>flask-backend.apps.local]
            end
        end
        
        subgraph "Container Registry"
            ECR1[ECR Repository<br/>flask-backend]
            ECR2[ECR Repository<br/>express-frontend]
        end
        
        subgraph "Monitoring & Logging"
            CW[CloudWatch Logs<br/>KMS Encrypted]
            KMS[KMS Key<br/>Auto-rotation enabled]
        end
        
        subgraph "IAM"
            IAMRole[ECS Task Execution Role<br/>ECR Pull + CloudWatch Write]
        end
        
        subgraph "Service Discovery"
            SD[HTTP Namespace<br/>apps.local]
        end
        
        subgraph "State Management"
            S3[S3 Bucket<br/>Terraform State<br/>Encrypted]
            DDB[DynamoDB Table<br/>State Lock]
        end
    end

    User1 -->|HTTP Request| IGW
    IGW --> ALB
    ALB -->|Port 80| Express1
    ALB -->|Port 5000| Flask1
    Express1 -.->|Service Connect| ServiceConnect
    ServiceConnect -.->|Internal Call| Flask1
    
    Express1 --> ECR2
    Flask1 --> ECR1
    
    Express1 -->|Logs| CW
    Flask1 -->|Logs| CW
    CW -->|Encrypted by| KMS
    
    Express1 -.->|Uses| IAMRole
    Flask1 -.->|Uses| IAMRole
    
    Flask1 -.->|Registers| SD
    Express1 -.->|Discovers| SD
    
    ALB --- LBSG
    Express1 --- ECSSG
    Flask1 --- ECSSG
    
    PubSub1 -.-> Express1
    PubSub2 -.-> Flask1

    style User1 fill:#e1f5ff
    style ALB fill:#ff9800
    style Express1 fill:#4caf50
    style Flask1 fill:#2196f3
    style ECR1 fill:#9c27b0
    style ECR2 fill:#9c27b0
    style CW fill:#ffc107
    style KMS fill:#f44336
    style S3 fill:#00bcd4
    style DDB fill:#00bcd4
    style ServiceConnect fill:#8bc34a
    style SD fill:#8bc34a
```

## Detailed Component Flow

```mermaid
sequenceDiagram
    participant User
    participant ALB as Application Load Balancer
    participant Express as Express Container
    participant Flask as Flask Container
    participant ECR as ECR Registry
    participant CW as CloudWatch Logs
    participant SC as Service Connect

    Note over User,CW: Initial Deployment
    ECR->>Express: Pull express-frontend:latest
    ECR->>Flask: Pull flask-backend:latest
    Flask->>SC: Register as flask-backend.apps.local
    
    Note over User,CW: User Request Flow
    User->>ALB: HTTP Request (Port 80)
    ALB->>Express: Forward to Express (Port 3000)
    Express->>SC: Lookup flask-backend.apps.local
    SC->>Express: Return Flask IP
    Express->>Flask: Internal API Call (Port 5000)
    Flask->>Express: API Response
    Express->>ALB: HTTP Response
    ALB->>User: Final Response
    
    Note over User,CW: Logging
    Express->>CW: Send logs to /ecs/express-frontend
    Flask->>CW: Send logs to /ecs/flask-backend
    CW->>CW: Encrypt with KMS
```

## Network Security Flow

```mermaid
graph LR
    subgraph "Internet"
        Internet[🌐 Internet]
    end
    
    subgraph "Security Layers"
        SG1[ALB Security Group<br/>✅ Allow 80, 5000 from 0.0.0.0/0<br/>✅ Allow all outbound]
        SG2[ECS Security Group<br/>✅ Allow 3000, 5000 from ALB SG<br/>✅ Allow 5000 from self<br/>✅ Allow all outbound]
    end
    
    subgraph "Resources"
        ALB2[Application Load Balancer]
        ECS[ECS Tasks]
    end
    
    Internet -->|HTTP 80, 5000| SG1
    SG1 --> ALB2
    ALB2 -->|Filtered| SG2
    SG2 --> ECS
    ECS -.->|Inter-service| SG2

    style SG1 fill:#4caf50
    style SG2 fill:#2196f3
    style Internet fill:#ff9800
```

## Data Flow Diagram

```mermaid
flowchart TD
    A[User Browser] -->|1. HTTP GET /| B[ALB Port 80]
    B -->|2. Route to Target Group| C[Express Container]
    C -->|3. Lookup Flask Service| D[Service Connect DNS]
    D -->|4. Resolve to IP| C
    C -->|5. HTTP GET /api/data| E[Flask Container]
    E -->|6. Process Request| E
    E -->|7. JSON Response| C
    C -->|8. Render HTML| C
    C -->|9. HTTP Response| B
    B -->|10. Final Response| A
    
    C -.->|Logs| F[CloudWatch]
    E -.->|Logs| F
    F -.->|Encrypted| G[KMS Key]

    style A fill:#e1f5ff
    style B fill:#ff9800
    style C fill:#4caf50
    style E fill:#2196f3
    style D fill:#8bc34a
    style F fill:#ffc107
    style G fill:#f44336
```

## Infrastructure as Code Structure

```mermaid
graph TD
    subgraph "Terraform Configuration"
        Main[main.tf<br/>Provider & Backend]
        Vars[variables.tf<br/>Input Variables]
        
        subgraph "Infrastructure Modules"
            VPC[vpc.tf<br/>Network Resources]
            ECR[ecr.tf<br/>Container Registry]
            ECS[ecs.tf<br/>Cluster & Services]
            ALB2[alb.tf<br/>Load Balancer]
            Roles[roles.tf<br/>IAM Permissions]
            Logs[logs.tf<br/>CloudWatch & KMS]
        end
        
        Outputs[outputs.tf<br/>Export Values]
    end
    
    subgraph "State Management"
        S3State[S3 Bucket<br/>terraform.tfstate]
        DDBLock[DynamoDB<br/>State Lock]
    end
    
    Main --> VPC
    Main --> ECR
    Main --> ECS
    Main --> ALB2
    Main --> Roles
    Main --> Logs
    Vars --> VPC
    Vars --> ECS
    
    VPC --> Outputs
    ECR --> Outputs
    ALB2 --> Outputs
    
    Main -.->|Store State| S3State
    Main -.->|Lock State| DDBLock

    style Main fill:#ff9800
    style VPC fill:#4caf50
    style ECR fill:#9c27b0
    style ECS fill:#2196f3
    style ALB2 fill:#ff5722
    style S3State fill:#00bcd4
    style DDBLock fill:#00bcd4
```

## Cost Breakdown

```mermaid
pie title Monthly Cost Distribution (~$60-70)
    "ECS Fargate Tasks" : 40
    "Application Load Balancer" : 20
    "Data Transfer" : 8
    "CloudWatch Logs" : 2
    "ECR Storage" : 1
    "KMS Key" : 1
```

## Deployment Flow

```mermaid
flowchart TD
    Start([Start Deployment]) --> Init[terraform init]
    Init --> CreateECR[Create ECR Repositories]
    CreateECR --> BuildFlask[Build Flask Docker Image]
    CreateECR --> BuildExpress[Build Express Docker Image]
    BuildFlask --> PushFlask[Push to ECR flask-backend]
    BuildExpress --> PushExpress[Push to ECR express-frontend]
    PushFlask --> TFApply[terraform apply]
    PushExpress --> TFApply
    
    TFApply --> CreateVPC[Create VPC & Subnets]
    CreateVPC --> CreateSG[Create Security Groups]
    CreateSG --> CreateALB[Create Load Balancer]
    CreateALB --> CreateIAM[Create IAM Roles]
    CreateIAM --> CreateLogs[Create CloudWatch Logs]
    CreateLogs --> CreateKMS[Create KMS Key]
    CreateKMS --> CreateCluster[Create ECS Cluster]
    CreateCluster --> CreateFlaskTask[Create Flask Task Definition]
    CreateCluster --> CreateExpressTask[Create Express Task Definition]
    CreateFlaskTask --> StartFlask[Start Flask Service]
    CreateExpressTask --> StartExpress[Start Express Service]
    StartFlask --> HealthCheck{Health Checks Pass?}
    StartExpress --> HealthCheck
    HealthCheck -->|Yes| Complete([✅ Deployment Complete])
    HealthCheck -->|No| Rollback[Circuit Breaker Rollback]
    Rollback --> CheckLogs[Check CloudWatch Logs]
    CheckLogs --> Fix[Fix Issues]
    Fix --> TFApply

    style Start fill:#4caf50
    style Complete fill:#4caf50
    style Rollback fill:#f44336
    style TFApply fill:#2196f3
```

---

## How to View These Diagrams

### Option 1: GitHub (Recommended)
Upload this file to GitHub - Mermaid diagrams render automatically.

### Option 2: VS Code
Install the "Markdown Preview Mermaid Support" extension.

### Option 3: Online Viewers
- [Mermaid Live Editor](https://mermaid.live/)
- Copy and paste the code blocks

### Option 4: Export as Images
Use the Mermaid CLI to generate PNG/SVG:
```bash
npm install -g @mermaid-js/mermaid-cli
mmdc -i ARCHITECTURE.md -o architecture.png
```

## Architecture Highlights

### 🔒 Security
- Multi-layer security groups
- KMS encryption for logs
- No public IPs for containers (uses ALB)
- IAM roles with least privilege

### 🚀 High Availability
- Multi-AZ deployment
- Auto-scaling capable
- Health checks with circuit breaker
- Load balancing across zones

### 📊 Observability
- CloudWatch Logs integration
- Container Insights enabled
- Centralized logging
- Encrypted log storage

### 💰 Cost Optimization
- Fargate (pay per use)
- 1-day log retention
- Right-sized containers (256 CPU)
- No NAT Gateway (uses public subnets)

### 🔄 Service Communication
- Service Connect for discovery
- No hardcoded IPs
- Automatic DNS resolution
- Internal service mesh
