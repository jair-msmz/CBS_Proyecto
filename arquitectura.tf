terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  required_version = ">= 1.4.0"
}

provider "aws" {
  region = var.region
}

resource "aws_s3_bucket" "secure_bucket" {
  bucket = var.bucket_name
  acl    = var.acl
  tags   = var.bucket_tags
}

resource "aws_s3_bucket_server_side_encryption_configuration" "secure_bucket_sse" {
  bucket = aws_s3_bucket.secure_bucket.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = var.kms_key_id
    }
  }
}

resource "aws_s3_bucket_versioning" "secure_bucket_versioning" {
  bucket = aws_s3_bucket.secure_bucket.id

  versioning_configuration {
    status = var.enable_versioning ? "Enabled" : "Suspended"
  }
}

resource "aws_s3_bucket_public_access_block" "secure_bucket_public_block" {
  bucket                  = aws_s3_bucket.secure_bucket.id
  block_public_acls       = var.block_public_access
  block_public_policy     = var.block_public_access
  ignore_public_acls      = var.block_public_access
  restrict_public_buckets = var.block_public_access
}

resource "aws_s3_bucket" "secure_bucket_logs" {
  bucket = var.log_bucket_name
  tags   = var.log_bucket_tags
}

resource "aws_s3_bucket_public_access_block" "secure_bucket_logs_public_block" {
  bucket                  = aws_s3_bucket.secure_bucket_logs.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_logging" "secure_bucket_logging" {
  bucket        = aws_s3_bucket.secure_bucket.id
  target_bucket = aws_s3_bucket.secure_bucket_logs.id
  target_prefix = "access-logs/"
}

resource "aws_iam_role" "clinica_secure_role" {
  name = var.role_clinica_secure_name

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = { AWS = "arn:aws:iam::${var.account_id}:root" }
      Action   = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role" "clinica_iot_role" {
  name               = var.role_clinica_iot_name
  assume_role_policy = aws_iam_role.clinica_secure_role.assume_role_policy
}

resource "aws_iam_role" "clinica_admin_role" {
  name               = var.role_clinica_admin_name
  assume_role_policy = aws_iam_role.clinica_secure_role.assume_role_policy
}

resource "aws_iam_policy" "iot_put_policy" {
  name        = var.iot_policy_name
  description = "Permite solo PutObject en el bucket"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = ["s3:PutObject"]
      Resource = "${aws_s3_bucket.secure_bucket.arn}/*"
    }]
  })
}

resource "aws_iam_policy" "secure_rw_policy" {
  name        = var.rw_policy_name
  description = "Lectura y escritura de historiales clínicos"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["s3:ListBucket"]
        Resource = aws_s3_bucket.secure_bucket.arn
      },
      {
        Effect   = "Allow"
        Action   = ["s3:GetObject", "s3:PutObject"]
        Resource = "${aws_s3_bucket.secure_bucket.arn}/*"
      }
    ]
  })
}

resource "aws_iam_policy" "admin_full_policy" {
  name        = var.admin_policy_name
  description = "Acceso completo al bucket"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = [
          "s3:ListBucket",
          "s3:GetBucketLocation",
          "s3:GetBucketLogging",
          "s3:PutBucketLogging",
          "s3:GetBucketVersioning",
          "s3:PutBucketVersioning"
        ]
        Resource = aws_s3_bucket.secure_bucket.arn
      },
      {
        Effect   = "Allow"
        Action   = ["s3:*Object"]
        Resource = "${aws_s3_bucket.secure_bucket.arn}/*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "iot_attach" {
  role       = aws_iam_role.clinica_iot_role.name
  policy_arn = aws_iam_policy.iot_put_policy.arn
}

resource "aws_iam_role_policy_attachment" "secure_attach" {
  role       = aws_iam_role.clinica_secure_role.name
  policy_arn = aws_iam_policy.secure_rw_policy.arn
}

resource "aws_iam_role_policy_attachment" "admin_attach" {
  role       = aws_iam_role.clinica_admin_role.name
  policy_arn = aws_iam_policy.admin_full_policy.arn
}

resource "aws_iam_role" "backup_role" {
  name = var.backup_role_name

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = { Service = "backup.amazonaws.com" }
      Action   = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy" "backup_role_s3_policy" {
  name = var.backup_policy_name
  role = aws_iam_role.backup_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["s3:ListBucket", "s3:GetBucketLocation"]
        Resource = aws_s3_bucket.secure_bucket.arn
      },
      {
        Effect   = "Allow"
        Action   = ["s3:GetObject", "s3:PutObject", "s3:DeleteObject"]
        Resource = "${aws_s3_bucket.secure_bucket.arn}/*"
      }
    ]
  })
}

resource "aws_backup_vault" "clinic_vault" {
  name = var.backup_vault_name
  tags = var.backup_tags
}

resource "aws_backup_plan" "clinic_backup_plan" {
  name = var.backup_plan_name

  rule {
    rule_name         = "daily-backup"
    target_vault_name = aws_backup_vault.clinic_vault.name
    schedule          = var.backup_schedule

    lifecycle {
      delete_after = var.backup_retention_days
    }
  }

  tags = var.backup_tags
}

resource "aws_backup_selection" "clinic_backup_selection" {
  name           = "clinic-secure-backup-selection"
  backup_plan_id = aws_backup_plan.clinic_backup_plan.id
  iam_role_arn   = aws_iam_role.backup_role.arn

  resources = [aws_s3_bucket.secure_bucket.arn]
}