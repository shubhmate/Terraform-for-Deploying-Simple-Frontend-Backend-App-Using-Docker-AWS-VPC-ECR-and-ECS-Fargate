# container logs
resource "aws_cloudwatch_log_group" "flask-backend-container-logs" {
  name              = "/ecs/flask-backend"
  retention_in_days = 1 # Adjust retention as needed
}

resource "aws_cloudwatch_log_group" "express-frontend-container-logs" {
  name              = "/ecs/express-frontend"
  retention_in_days = 1 # Adjust retention as needed
}