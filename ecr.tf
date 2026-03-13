# Ecr repositories for Flask and Express applications
resource "aws_ecr_repository" "flask_backend" {
  name = "flask-backend"
}

resource "aws_ecr_repository" "express_frontend" {
  name = "express-frontend"
}
