resource "aws_ecr_repository" "service_watch" {
  name                 = "service-watch"
  image_tag_mutability = "IMMUTABLE"

  encryption_configuration {
    encryption_type = "AES256"
  }

  image_scanning_configuration {
    scan_on_push = true
  }
}

resource "aws_sns_topic" "alerts" {
  name = "service-watch-alerts"
}

resource "aws_ssm_parameter" "image_tag" {
  name = "/service-watch/image-tag"
  type = "String"

  value = "bootstrap"

  lifecycle {
    ignore_changes = [value]
  }
}

resource "aws_security_group" "service_watch" {
  name        = "service-watch-sg"
  description = "Define inbound outbound security rules"
  vpc_id      = "vpc-03ff74456aa758be7"

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_iam_openid_connect_provider" "github" {
  url             = "https://token.actions.githubusercontent.com"
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = ["ab9d0263244dd0326eb67015705a667e79cfe998"]
}

resource "aws_instance" "service_watch" {
  ami                    = "ami-0bea529386a62a2ad"
  instance_type          = "t3.micro"
  subnet_id              = "subnet-0bfecba0c9170dc9e"
  vpc_security_group_ids = [aws_security_group.service_watch.id]
  iam_instance_profile   = aws_iam_instance_profile.instance.name

  tags = {
    Name = "service-watch"
  }
}

resource "aws_sns_topic_subscription" "alerts_email" {
  topic_arn = aws_sns_topic.alerts.arn
  protocol  = "email"
  endpoint  = var.alert_email
}
