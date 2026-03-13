# HTTPS Configuration Guide

## Current Status
The ALB is currently configured with HTTP only. For production environments, HTTPS should be enabled.

## Why HTTPS is Not Enabled by Default
HTTPS requires an SSL/TLS certificate, which needs:
1. A domain name (e.g., example.com)
2. Certificate validation through AWS Certificate Manager (ACM)
3. DNS configuration

## How to Enable HTTPS

### Option 1: Using AWS Certificate Manager (Recommended)

1. **Request a certificate in ACM:**
```bash
aws acm request-certificate \
  --domain-name yourdomain.com \
  --validation-method DNS \
  --region us-east-1
```

2. **Add the certificate ARN to variables.tf:**
```hcl
variable "certificate_arn" {
  description = "ARN of the SSL certificate from ACM"
  type        = string
  default     = ""  # Leave empty for HTTP only
}
```

3. **Update alb.tf to add HTTPS listener:**
```hcl
# HTTPS Listener for Express (Frontend) on Port 443
resource "aws_lb_listener" "express_https_listener" {
  count             = var.certificate_arn != "" ? 1 : 0
  load_balancer_arn = aws_lb.main.arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS-1-2-2017-01"
  certificate_arn   = var.certificate_arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.express.arn
  }
}

# Redirect HTTP to HTTPS
resource "aws_lb_listener" "express_http_redirect" {
  count             = var.certificate_arn != "" ? 1 : 0
  load_balancer_arn = aws_lb.main.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type = "redirect"
    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}
```

4. **Update security group in vpc.tf:**
```hcl
# Add HTTPS ingress rule to lb_sg
ingress {
  protocol    = "tcp"
  from_port   = 443
  to_port     = 443
  cidr_blocks = ["0.0.0.0/0"]
}
```

### Option 2: Self-Signed Certificate (Development Only)

For development/testing, you can use a self-signed certificate, but browsers will show warnings.

```bash
# Generate self-signed certificate
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
  -keyout private.key -out certificate.crt

# Upload to ACM
aws acm import-certificate \
  --certificate fileb://certificate.crt \
  --private-key fileb://private.key \
  --region us-east-1
```

## Security Best Practices

1. **Use TLS 1.2 or higher** - Older versions have vulnerabilities
2. **Enable HTTP to HTTPS redirect** - Force all traffic to use encryption
3. **Use strong cipher suites** - AWS provides secure default policies
4. **Rotate certificates** - ACM handles this automatically for AWS-issued certificates

## Current HTTP Configuration

The project uses HTTP for simplicity and to avoid certificate requirements. This is acceptable for:
- Development environments
- Internal applications behind VPN
- Testing and learning purposes

For production, always use HTTPS to protect data in transit.

## Additional Resources

- [AWS Certificate Manager Documentation](https://docs.aws.amazon.com/acm/)
- [ALB HTTPS Listeners](https://docs.aws.amazon.com/elasticloadbalancing/latest/application/create-https-listener.html)
- [SSL/TLS Best Practices](https://docs.aws.amazon.com/elasticloadbalancing/latest/application/create-https-listener.html#describe-ssl-policies)
