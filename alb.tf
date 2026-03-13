# Create an Application Load Balancer (ALB) to distribute traffic to both Flask and Express services
resource "aws_lb" "main" {
  name               = "app-lb"
  load_balancer_type = "application"
  subnets            = aws_subnet.public[*].id
  security_groups    = [aws_security_group.lb_sg.id]
  
  # Security: Drop invalid HTTP headers
  drop_invalid_header_fields = true
  
  # Enable deletion protection for production
  # enable_deletion_protection = true
}

# Create Target Groups for Flask and Express services with appropriate ports and health check settings to monitor the health of the services and ensure traffic is only sent to healthy instances 
resource "aws_lb_target_group" "flask" {
  name        = "flask-tg"
  port        = 5000
  protocol    = "HTTP"
  vpc_id      = aws_vpc.main.id
  target_type = "ip"
  
  health_check {
    path                = "/"
    interval            = 30
    timeout             = 10
    healthy_threshold   = 2
    unhealthy_threshold = 3
    matcher             = "200-299"
  }
}

resource "aws_lb_target_group" "express" {
  name        = "express-tg"
  port        = 3000
  protocol    = "HTTP"
  vpc_id      = aws_vpc.main.id
  target_type = "ip"
  
  health_check {
    path                = "/" 
    interval            = 30
    timeout             = 10
    healthy_threshold   = 2
    # ALLOW MORE FAILURES during the "Waiting for Flask DNS" phase
    unhealthy_threshold = 10 
    # Accept 404s temporarily if your app takes time to bind the port
    matcher             = "200-499" 
  }
}

# Listener for Express (Frontend) on Port 80
resource "aws_lb_listener" "express_listener" {
  load_balancer_arn = aws_lb.main.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.express.arn
  }
}

# # Listener for Flask (Backend) on Port 5000
# resource "aws_lb_listener_rule" "api" {
#   listener_arn = aws_lb_listener.express_listener.arn
#   action {
#     type             = "forward"
#     target_group_arn = aws_lb_target_group.flask.arn
#   }
#   condition {
#     path_pattern { values = ["/api/*"] }
#   }
# }

# Listener for Express (Frontend) on Port 80 and Listener for Flask (Backend) on Port 5000, forwarding to their respective
# target groups to route incoming traffic to the correct service based on the port and ensure that the ALB can distribute 
# traffic to both services correctly and allow for proper health checks to monitor the services and maintain high availability 
# Note: We are using separate listeners for each service to avoid issues with path-based routing and to ensure that the ALB can properly route traffic to both services without conflicts.

# Listener for Flask (Backend) on Port 5000
resource "aws_lb_listener" "flask_listener" {
  load_balancer_arn = aws_lb.main.arn
  port              = 5000
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.flask.arn
  }
}
