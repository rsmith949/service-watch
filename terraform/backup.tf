# Offsite copy of the home server backups (see home-stack roadmap, track 2).
# kopia/   : Kopia repository for configs + DB dumps (S3 Standard, small, rewritten nightly)
# archive/ : rclone-encrypted photos/files, write-once, Glacier Deep Archive only
# Credentials: IAM Roles Anywhere with a self-managed CA - no long-lived IAM keys in this account.

locals {
  backup_bucket = "home-backup-${data.aws_caller_identity.current.account_id}"
}

data "aws_caller_identity" "current" {}

resource "aws_s3_bucket" "backup" {
  bucket = local.backup_bucket
}

resource "aws_s3_bucket_public_access_block" "backup" {
  bucket                  = aws_s3_bucket.backup.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_ownership_controls" "backup" {
  bucket = aws_s3_bucket.backup.id
  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

# AWS-0132 (no CMK) accepted for this bucket only: every object is encrypted
# client-side before upload (Kopia AES-256-GCM, rclone crypt), so S3-side
# encryption is defence in depth over ciphertext. A CMK would cost $1/month,
# half this project's $2 budget, for rotation control that protects nothing.
#trivy:ignore:AWS-0132
resource "aws_s3_bucket_server_side_encryption_configuration" "backup" {
  bucket = aws_s3_bucket.backup.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "backup" {
  bucket = aws_s3_bucket.backup.id
  rule {
    id     = "abort-incomplete-uploads"
    status = "Enabled"
    filter {}
    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }
  }
}

resource "aws_rolesanywhere_trust_anchor" "home" {
  name    = "home-backup-ca"
  enabled = true
  source {
    source_type = "CERTIFICATE_BUNDLE"
    source_data {
      x509_certificate_data = file("${path.module}/files/home-backup-ca.pem")
    }
  }
}

data "aws_iam_policy_document" "backup_trust" {
  statement {
    actions = ["sts:AssumeRole", "sts:TagSession", "sts:SetSourceIdentity"]
    principals {
      type        = "Service"
      identifiers = ["rolesanywhere.amazonaws.com"]
    }
    condition {
      test     = "ArnEquals"
      variable = "aws:SourceArn"
      values   = [aws_rolesanywhere_trust_anchor.home.arn]
    }
    condition {
      test     = "StringEquals"
      variable = "aws:PrincipalTag/x509Subject/CN"
      values   = ["arr-backup"]
    }
  }
}

resource "aws_iam_role" "home_backup" {
  name                 = "home-backup"
  assume_role_policy   = data.aws_iam_policy_document.backup_trust.json
  max_session_duration = 3600
}

data "aws_iam_policy_document" "backup_access" {
  statement {
    sid       = "ListBucket"
    actions   = ["s3:ListBucket", "s3:GetBucketLocation"]
    resources = [aws_s3_bucket.backup.arn]
  }
  statement {
    sid       = "KopiaReadWrite"
    actions   = ["s3:GetObject", "s3:PutObject", "s3:DeleteObject"]
    resources = ["${aws_s3_bucket.backup.arn}/kopia/*"]
  }
  statement {
    sid       = "ArchiveRead"
    actions   = ["s3:GetObject"]
    resources = ["${aws_s3_bucket.backup.arn}/archive/*"]
  }
  statement {
    sid       = "ArchiveAddDeepArchiveOnly"
    actions   = ["s3:PutObject"]
    resources = ["${aws_s3_bucket.backup.arn}/archive/*"]
    condition {
      test     = "StringEquals"
      variable = "s3:x-amz-storage-class"
      values   = ["DEEP_ARCHIVE"]
    }
  }
}

resource "aws_iam_role_policy" "home_backup" {
  name   = "home-backup-s3"
  role   = aws_iam_role.home_backup.id
  policy = data.aws_iam_policy_document.backup_access.json
}

resource "aws_rolesanywhere_profile" "home_backup" {
  name             = "home-backup"
  enabled          = true
  role_arns        = [aws_iam_role.home_backup.arn]
  duration_seconds = 3600
}

resource "aws_budgets_budget" "monthly" {
  name         = "monthly-2-usd"
  budget_type  = "COST"
  limit_amount = "2"
  limit_unit   = "USD"
  time_unit    = "MONTHLY"

  notification {
    comparison_operator        = "GREATER_THAN"
    threshold                  = 80
    threshold_type             = "PERCENTAGE"
    notification_type          = "ACTUAL"
    subscriber_email_addresses = [var.alert_email]
  }

  notification {
    comparison_operator        = "GREATER_THAN"
    threshold                  = 100
    threshold_type             = "PERCENTAGE"
    notification_type          = "FORECASTED"
    subscriber_email_addresses = [var.alert_email]
  }
}

output "backup_bucket" { value = aws_s3_bucket.backup.id }
output "rolesanywhere_trust_anchor_arn" { value = aws_rolesanywhere_trust_anchor.home.arn }
output "rolesanywhere_profile_arn" { value = aws_rolesanywhere_profile.home_backup.arn }
output "home_backup_role_arn" { value = aws_iam_role.home_backup.arn }
