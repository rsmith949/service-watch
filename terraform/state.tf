resource "aws_s3_bucket" "tfstate" {
  bucket = "service-watch-tfstate-182715287298"
}

resource "aws_s3_bucket_versioning" "tfstate" {
  bucket = aws_s3_bucket.tfstate.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "tfstate" {
  bucket = aws_s3_bucket.tfstate.id

  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = aws_kms_key.tfstate.arn
      sse_algorithm     = "aws:kms"
    }
    bucket_key_enabled = true
  }
}

resource "aws_s3_bucket_public_access_block" "tfstate" {
  bucket                  = aws_s3_bucket.tfstate.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_kms_key" "tfstate" {
  description             = "Encrypts service-watch Terraform state"
  enable_key_rotation     = true
  deletion_window_in_days = 7
}

resource "aws_kms_alias" "tfstate" {
  name          = "alias/service-watch-tfstate"
  target_key_id = aws_kms_key.tfstate.key_id
}
