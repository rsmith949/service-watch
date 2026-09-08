# __generated__ by Terraform
# Please review these resources and move them into your main configuration files.

# __generated__ by Terraform from "service-watch-instance/arn:aws:iam::182715287298:policy/ecr-pull-service-watch"
resource "aws_iam_role_policy_attachment" "instance_ecr_pull" {
  policy_arn = "arn:aws:iam::182715287298:policy/ecr-pull-service-watch"
  role       = "service-watch-instance"
}

# __generated__ by Terraform from "github-actions-service-watch/arn:aws:iam::182715287298:policy/ecr-push-service-watch"
resource "aws_iam_role_policy_attachment" "github_actions_ecr_push" {
  policy_arn = "arn:aws:iam::182715287298:policy/ecr-push-service-watch"
  role       = "github-actions-service-watch"
}

# __generated__ by Terraform from "service-watch-instance/arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
resource "aws_iam_role_policy_attachment" "instance_ssm" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  role       = "service-watch-instance"
}

# __generated__ by Terraform from "arn:aws:iam::182715287298:policy/ecr-pull-service-watch"
resource "aws_iam_policy" "ecr_pull" {
  delay_after_policy_creation_in_ms = null
  description                       = null
  name                              = "ecr-pull-service-watch"
  path                              = "/"
  policy = jsonencode({
    Statement = [{
      Action   = "ecr:GetAuthorizationToken"
      Effect   = "Allow"
      Resource = "*"
      Sid      = "GetAuthToken"
      }, {
      Action   = ["ecr:BatchCheckLayerAvailability", "ecr:BatchGetImage", "ecr:GetDownloadUrlForLayer"]
      Effect   = "Allow"
      Resource = "arn:aws:ecr:us-west-2:182715287298:repository/service-watch"
      Sid      = "PullServiceWatch"
      }, {
      Action   = "sns:Publish"
      Effect   = "Allow"
      Resource = "arn:aws:sns:us-west-2:182715287298:service-watch-alerts"
      Sid      = "PublishAlerts"
      }, {
      Action   = ["kms:GenerateDataKey*", "kms:Decrypt"]
      Effect   = "Allow"
      Resource = "*"
      Sid      = "AlertTopicEncryption"
      Condition = {
        StringEquals = {
          "kms:ViaService" = "sns.us-west-2.amazonaws.com"
        }
      }
    }]
    Version = "2012-10-17"
  })
  tags     = {}
  tags_all = {}
}

# __generated__ by Terraform from "service-watch-instance"
resource "aws_iam_instance_profile" "instance" {
  name     = "service-watch-instance"
  path     = "/"
  role     = "service-watch-instance"
  tags     = {}
  tags_all = {}
}

# __generated__ by Terraform from "service-watch-instance"
resource "aws_iam_role" "instance" {
  assume_role_policy = jsonencode({
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
    }]
    Version = "2012-10-17"
  })
  description           = "Allows EC2 instances to call AWS services on your behalf."
  force_detach_policies = false
  max_session_duration  = 3600
  name                  = "service-watch-instance"
  path                  = "/"
  permissions_boundary  = null
  tags                  = {}
  tags_all              = {}
}

# __generated__ by Terraform from "arn:aws:iam::182715287298:policy/ecr-push-service-watch"
resource "aws_iam_policy" "ecr_push" {
  delay_after_policy_creation_in_ms = null
  description                       = null
  name                              = "ecr-push-service-watch"
  path                              = "/"
  policy = jsonencode({
    Statement = [{
      Action   = "ecr:GetAuthorizationToken"
      Effect   = "Allow"
      Resource = "*"
      Sid      = "GetAuthToken"
      }, {
      Action   = ["ecr:BatchCheckLayerAvailability", "ecr:InitiateLayerUpload", "ecr:UploadLayerPart", "ecr:CompleteLayerUpload", "ecr:PutImage", "ecr:DescribeImages"]
      Effect   = "Allow"
      Resource = "arn:aws:ecr:us-west-2:182715287298:repository/service-watch"
      Sid      = "PushToServiceWatchOnly"
      }, {
      Action   = "ssm:PutParameter"
      Effect   = "Allow"
      Resource = "arn:aws:ssm:us-west-2:182715287298:parameter/service-watch/image-tag"
      Sid      = "PublishImageTag"
    }]
    Version = "2012-10-17"
  })
  tags     = {}
  tags_all = {}
}

# __generated__ by Terraform from "github-actions-service-watch"
resource "aws_iam_role" "github_actions" {
  assume_role_policy = jsonencode({
    Statement = [{
      Action = "sts:AssumeRoleWithWebIdentity"
      Condition = {
        StringEquals = {
          "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
        }
        StringLike = {
          "token.actions.githubusercontent.com:sub" = "repo:rsmith949@102631042/service-watch@1357904324:ref:refs/heads/main"
        }
      }
      Effect = "Allow"
      Principal = {
        Federated = "arn:aws:iam::182715287298:oidc-provider/token.actions.githubusercontent.com"
      }
    }]
    Version = "2012-10-17"
  })
  description           = null
  force_detach_policies = false
  max_session_duration  = 3600
  name                  = "github-actions-service-watch"
  path                  = "/"
  permissions_boundary  = null
  tags                  = {}
  tags_all              = {}
}
