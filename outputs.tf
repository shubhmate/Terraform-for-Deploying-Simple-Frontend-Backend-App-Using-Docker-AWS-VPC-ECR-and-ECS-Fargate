# Outputs for ALB DNS name, Flask and Express URLs, and ECR repository URLs
output "alb_dns_name" {
  value = aws_lb.main.dns_name
}

output "flask_url" {
  value = "http://${aws_lb.main.dns_name}:5000"
}

output "express_url" {
  value = "http://${aws_lb.main.dns_name}:80"
}

output "flask_ecr_repo_url" {
  value = aws_ecr_repository.flask_backend.repository_url
}

output "express_ecr_repo_url" {
  value = aws_ecr_repository.express_frontend.repository_url
}