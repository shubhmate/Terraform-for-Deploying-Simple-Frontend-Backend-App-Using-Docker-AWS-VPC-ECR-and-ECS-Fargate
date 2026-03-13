# ECS Cluster and Services with Service Connect for Flask and Express applications deployed on AWS Fargate, 
# using ECR for container images and an Application Load Balancer (ALB) for routing traffic. 

# namespaces and service discovery are configured to allow seamless communication between the services without hardcoding IP addresses,
# and security groups are set up to allow only necessary traffic between the ALB and the ECS tasks, as well as between the services themselves,
# while allowing outbound internet access for updates and image pulls. 
resource "aws_service_discovery_http_namespace" "main" {
  name        = "apps.local"
  description = "Service Connect Namespace"
}

# cluster with Service Connect enabled to allow seamless communication between the Flask and Express services without hardcoding IP addresses,
# and to enable features like automatic service discovery and load balancing between the services, improving the overall architecture and maintainability of the application. 
resource "aws_ecs_cluster" "main" {
  name = "app-cluster"

  setting {
    name  = "containerInsights"
    value = "enabled"
  }

  service_connect_defaults {
    namespace = aws_service_discovery_http_namespace.main.arn
  }
}

# Task Definitions
# Flask Task Definition 
resource "aws_ecs_task_definition" "flask" {
  family                   = "flask-task"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256"
  memory                   = "512"
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn

#   container_definitions = jsonencode([{
#     name      = "flask-app"
#     image     = "${aws_ecr_repository.flask_backend.repository_url}:latest"
#     portMappings = [{ containerPort = 5000 }]
#   }])

  container_definitions = jsonencode([{
  name      = "flask-app"
  image     = "${aws_ecr_repository.flask_backend.repository_url}:latest"
  portMappings = [{
      name          = "flask-port" # Matches service config
      containerPort = 5000
      hostPort      = 5000
      protocol      = "tcp"
      appProtocol   = "http" # REQUIRED for HTTP proxying
    }]
    logConfiguration = {
      logDriver = "awslogs"
      options = {
        "awslogs-group"         = "/ecs/flask-backend"
        "awslogs-region"        = var.aws_region
        "awslogs-stream-prefix" = "flask"
      }
    }
  }])
}

# Express Task Definition
resource "aws_ecs_task_definition" "express" {
  family                   = "express-task"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256"
  memory                   = "512"
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn

  # container_definitions = jsonencode([{
  #   name      = "express-app"
  #   image     = "${aws_ecr_repository.express_frontend.repository_url}:latest"
  #   portMappings = [{ containerPort = 3000 }]
  # }])

  container_definitions = jsonencode([{
    # The script: Wait for DNS -> Extract IP -> Update /etc/hosts -> Start Node
    command = [
      "/bin/sh",
      "-c",
      "apk add --no-cache socat && until getent ahostsv4 flask-backend.apps.local | grep STREAM; do echo 'Waiting for Flask IPv4...'; sleep 2; done && FLASK_IP=$(getent ahostsv4 flask-backend.apps.local | grep STREAM | head -n 1 | awk '{ print $1 }') && echo \"Relaying 127.0.0.1:5000 -> $FLASK_IP:5000\" && socat TCP-LISTEN:5000,fork,reuseaddr TCP4:$FLASK_IP:5000 & node app.js"
    ]
    name      = "express-app"
    image     = "${aws_ecr_repository.express_frontend.repository_url}:latest"
    portMappings = [{ 
      name          = "express-port" # Add this
      containerPort = 3000 
      hostPort      = 3000
      appProtocol   = "http"         # Add this
    }]
    logConfiguration = {
      logDriver = "awslogs"
      options = {
        "awslogs-group"         = "/ecs/express-frontend"
        "awslogs-region"        = var.aws_region
        "awslogs-stream-prefix" = "express"
      }
    }
  }])
}

# Services
# Flask Service  
resource "aws_ecs_service" "flask" {
  name            = "flask-service"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.flask.arn
  launch_type     = "FARGATE"
  desired_count   = 1

  # Network configuration for Fargate
  network_configuration {
    subnets         = aws_subnet.public[*].id
    security_groups = [aws_security_group.ecs_tasks.id]
    assign_public_ip = true
  }

  # Enable Service Connect in "Server Mode" to allow other services (like Express) to discover and call this
  # service without hardcoding IP addresses, and to allow the ALB to route traffic to this service based on 
  # the target group configuration, improving the overall architecture and maintainability of the application.
  service_connect_configuration {
    enabled   = true
    namespace = aws_service_discovery_http_namespace.main.arn
    service {
      port_name      = "flask-port" # Defined in Task Definition port mapping
      discovery_name = "flask-backend"
      client_alias {
        port     = 5000
        dns_name = "flask-backend.apps.local" # Use service discovery name for better readability
      }
    }
  }

  # Link the service to the ALB Target Group 
  load_balancer {
    target_group_arn = aws_lb_target_group.flask.arn
    container_name   = "flask-app"
    container_port   = 5000
  }

  # Optional: Prevents service from hanging if deployment fails
  deployment_circuit_breaker {
      enable   = true
      rollback = true
  }

  # Ensure the ALB listener for Flask is created before this service to avoid deployment issues and 
  # to ensure that the service can properly register with the target group and receive traffic from the ALB. 
  depends_on = [aws_lb_listener.flask_listener]
}

# Express Service
resource "aws_ecs_service" "express" {
  name            = "express-service"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.express.arn
  launch_type     = "FARGATE"
  desired_count   = 1

  # Network configuration for Fargate 
  network_configuration {
    subnets          = aws_subnet.public[*].id
    security_groups  = [aws_security_group.ecs_tasks.id]
    assign_public_ip = true # Set to true if you are not using a NAT Gateway
  }

  # Enable Service Connect in "Client Mode" to allow this service to discover and call the Flask service without hardcoding IP addresses,
  # and to allow the ALB to route traffic to this service based on the target group configuration, improving the overall architecture and maintainability of the application.
  service_connect_configuration {
    enabled   = true
    namespace = aws_service_discovery_http_namespace.main.arn
    # No 'service' block needed here as Express is only a client
  }

  # Link the service to the ALB Target Group
  load_balancer {
    target_group_arn = aws_lb_target_group.express.arn
    container_name   = "express-app" # Must match container name in task definition
    container_port   = 3000          # The port your Express app listens on
  }

  # Optional: Prevents service from hanging if deployment fails
  deployment_circuit_breaker {
    enable   = true
    rollback = true
  }

  # Ensure Flask service is deployed first for proper service discovery
  # Ensure the ALB listener for Express is created before this service to avoid deployment issues and
  # to ensure that the service can properly register with the target group and receive traffic from the ALB. 
  depends_on = [
    aws_ecs_service.flask, 
    aws_lb_listener.express_listener
  ]
}


