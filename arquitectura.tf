############################################
# CONFIGURACIÓN DE AWS PARA CLÍNICA SEGURA
############################################

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
  region = "us-east-1"
}

############################################
# S3: BUCKET PRINCIPAL PARA HISTORIALES
############################################

resource "aws_s3_bucket" "secure_bucket" {
  bucket = "clinicasecurebucket1"

  tags = {
    Name        = "Clinica Secure Data"
    Environment = "prod"
    Project     = "Clinica-Segura"
  }
}

# Cifrado KMS por defecto
resource "aws_s3_bucket_server_side_encryption_configuration" "secure_bucket_sse" {
  bucket = aws_s3_bucket.secure_bucket.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = "alias/aws/s3"
    }
  }
}

# Versionado
resource "aws_s3_bucket_versioning" "secure_bucket_versioning" {
  bucket = aws_s3_bucket.secure_bucket.id

  versioning_configuration {
    status = "Enabled"
  }
}

# Bloqueo de acceso público
resource "aws_s3_bucket_public_access_block" "secure_bucket_public_block" {
  bucket = aws_s3_bucket.secure_bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

############################################
# S3: BUCKET PARA LOGGING DE ACCESO
############################################

resource "aws_s3_bucket" "secure_bucket_logs" {
  bucket = "clinicasecurebucket1-logs"

  tags = {
    Name        = "Clinica Secure Logs"
    Environment = "prod"
    Project     = "Clinica-Segura"
  }
}

resource "aws_s3_bucket_public_access_block" "secure_bucket_logs_public_block" {
  bucket = aws_s3_bucket.secure_bucket_logs.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Logging de acceso del bucket principal hacia el bucket de logs
resource "aws_s3_bucket_logging" "secure_bucket_logging" {
  bucket = aws_s3_bucket.secure_bucket.id

  target_bucket = aws_s3_bucket.secure_bucket_logs.id
  target_prefix = "access-logs/"
}

############################################
# IAM: ROLES
############################################

# Rol para empleados (Clinica-Secure)
resource "aws_iam_role" "clinica_secure_role" {
  name = "Clinica-Secure"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          # Cuenta desde la que los usuarios asumirán el rol
          AWS = "arn:aws:iam::498823212740:root"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

# Rol para dispositivos IoT (Clinica-IoT)
resource "aws_iam_role" "clinica_iot_role" {
  name = "Clinica-IoT"

  assume_role_policy = aws_iam_role.clinica_secure_role.assume_role_policy
}

# Rol para administradores (Clinica-Admin)
resource "aws_iam_role" "clinica_admin_role" {
  name = "Clinica-Admin"

  assume_role_policy = aws_iam_role.clinica_secure_role.assume_role_policy
}

############################################
# IAM: POLÍTICAS ESPECÍFICAS
############################################

# Política IoT: sólo PutObject al bucket
resource "aws_iam_policy" "iot_put_policy" {
  name        = "Clinica-IoT-PutObject-Only"
  description = "Permite solo s3:PutObject para subir métricas cardiacas al bucket de la clínica"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:PutObject"
        ]
        Resource = "${aws_s3_bucket.secure_bucket.arn}/*"
      }
    ]
  })
}

# Política para empleados: lectura/escritura de objetos (no administración del bucket)
resource "aws_iam_policy" "secure_rw_policy" {
  name        = "Clinica-Secure-RW"
  description = "Lectura y escritura de historiales clínicos para empleados"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      # Listar objetos del bucket
      {
        Effect = "Allow"
        Action = [
          "s3:ListBucket"
        ]
        Resource = aws_s3_bucket.secure_bucket.arn
      },
      # Get y Put de objetos
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject"
        ]
        Resource = "${aws_s3_bucket.secure_bucket.arn}/*"
      }
    ]
  })
}

# Política para administradores: acceso completo al bucket
resource "aws_iam_policy" "admin_full_policy" {
  name        = "Clinica-Admin-FullAccess"
  description = "Acceso completo al bucket de historiales clínicos para administradores"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      # Operaciones a nivel bucket
      {
        Effect = "Allow"
        Action = [
          "s3:ListBucket",
          "s3:GetBucketLocation",
          "s3:GetBucketLogging",
          "s3:PutBucketLogging",
          "s3:GetBucketVersioning",
          "s3:PutBucketVersioning"
        ]
        Resource = aws_s3_bucket.secure_bucket.arn
      },
      # Operaciones sobre objetos
      {
        Effect = "Allow"
        Action = [
          "s3:*Object"
        ]
        Resource = "${aws_s3_bucket.secure_bucket.arn}/*"
      }
    ]
  })
}

############################################
# IAM: ATTACH DE POLÍTICAS A LOS ROLES
############################################

# IoT -> PutObject solamente
resource "aws_iam_role_policy_attachment" "iot_attach" {
  role       = aws_iam_role.clinica_iot_role.name
  policy_arn = aws_iam_policy.iot_put_policy.arn
}

# Empleados -> Lectura/Escritura de historiales
resource "aws_iam_role_policy_attachment" "secure_attach" {
  role       = aws_iam_role.clinica_secure_role.name
  policy_arn = aws_iam_policy.secure_rw_policy.arn
}

# Admin -> Acceso completo al S3 de historiales
resource "aws_iam_role_policy_attachment" "admin_attach" {
  role       = aws_iam_role.clinica_admin_role.name
  policy_arn = aws_iam_policy.admin_full_policy.arn
}

############################################
# AWS BACKUP: RESPALDOS DIARIOS (90 DÍAS)
############################################

# Rol que utilizará AWS Backup para ejecutar los respaldos sobre el bucket
resource "aws_iam_role" "backup_role" {
  name = "Clinica-Backup-Role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "backup.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

# Política mínima para que AWS Backup pueda leer/escribir del bucket
resource "aws_iam_role_policy" "backup_role_s3_policy" {
  name = "Clinica-Backup-S3-Access"
  role = aws_iam_role.backup_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      # Operaciones sobre el bucket
      {
        Effect = "Allow"
        Action = [
          "s3:ListBucket",
          "s3:GetBucketLocation"
        ]
        Resource = aws_s3_bucket.secure_bucket.arn
      },
      # Operaciones sobre objetos (para respaldar/restaurar)
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject"
        ]
        Resource = "${aws_s3_bucket.secure_bucket.arn}/*"
      }
    ]
  })
}

# Vault de backups
resource "aws_backup_vault" "clinic_vault" {
  name = "clinic-secure-vault"

  tags = {
    Name        = "Clinica Secure Backup Vault"
    Environment = "prod"
    Project     = "Clinica-Segura"
  }
}

# Plan de backups: diario, retención 90 días
resource "aws_backup_plan" "clinic_backup_plan" {
  name = "clinic-secure-backup-plan"

  rule {
    rule_name         = "daily-backup"
    target_vault_name = aws_backup_vault.clinic_vault.name

    # Cron: todos los días a las 05:00 UTC
    schedule = "cron(0 5 * * ? *)"

    lifecycle {
      delete_after = 90
    }
  }

  tags = {
    Name        = "Clinica Secure Backup Plan"
    Environment = "prod"
    Project     = "Clinica-Segura"
  }
}

# Selección de recursos a respaldar: bucket de historiales
resource "aws_backup_selection" "clinic_backup_selection" {
  name          = "clinic-secure-backup-selection"
  backup_plan_id = aws_backup_plan.clinic_backup_plan.id
  iam_role_arn   = aws_iam_role.backup_role.arn

  resources = [
    aws_s3_bucket.secure_bucket.arn
  ]
}