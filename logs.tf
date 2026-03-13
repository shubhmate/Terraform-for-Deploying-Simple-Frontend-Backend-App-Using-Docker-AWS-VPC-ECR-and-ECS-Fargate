# KMS key for encrypting CloudWatch logs
resource "aws_kms_key" "cloudwatch_logs" {
  description             = "KMS key for CloudWatch log encryption"
  deletion_window_in_days = 10
  enable_key_rotation     = true

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "Enable IAM User Permissions"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        }
        Action   = "kms:*"
        Resource = "*"
      },
      {
        Sid    = "Allow CloudWatch Logs"
        Effect = "Allow"
        Principal = {
          Service = "logs.${var.aws_region}.amazonaws.com"
        }
        Action = [
          "kms:Encrypt",
          "kms:Decrypt",
          "kms:ReEncrypt*",
          "kms:GenerateDataKey*",
          "kms:CreateGrant",
          "kms:DescribeKey"
        ]
        Resource = "*"
        Condition = {
          ArnLike = {
            "kms:EncryptionContext:aws:logs:arn" = "arn:aws:logs:${var.aws_region}:${data.aws_caller_identity.current.account_id}:log-group:*"
          }
        }
      }
    ]
  })
}

resource "aws_kms_alias" "cloudwatch_logs" {
  name          = "alias/cloudwatch-logs-encryption"
  target_key_id = aws_kms_key.cloudwatch_logs.key_id
}

# Data source to get current AWS account ID
data "aws_caller_identity" "current" {}

# container logs with KMS encryption
resource "aws_cloudwatch_log_group" "flask-backend-container-logs" {
  name              = "/ecs/flask-backend"
  retention_in_days = 1 # Adjust retention as needed
  kms_key_id        = aws_kms_key.cloudwatch_logs.arn
}

resource "aws_cloudwatch_log_group" "express-frontend-container-logs" {
  name              = "/ecs/express-frontend"
  retention_in_days = 1 # Adjust retention as needed
  kms_key_id        = aws_kms_key.cloudwatch_logs.arn
}