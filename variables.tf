variable "region" {
  description = "AWS Region for resource deployment"
  type        = string
  default     = "us-east-1"
}

variable "account_id" {
  description = "AWS Account ID"
  type        = string
  default     = "498823212740"
}

variable "bucket_name" {
  description = "Name of the S3 bucket for secure data storage"
  type        = string
}

variable "bucket_tags" {
  description = "Tags to apply to the S3 bucket"
  type        = map(string)
  default = {
    Name        = "Clinica Secure Data"
    Environment = "prod"
    Project     = "Clinica-Segura"
  }
}

variable "acl" {
  description = "Access control list for the main S3 bucket"
  type        = string
  default     = "private"
}

variable "kms_key_id" {
  description = "KMS Key ID for server-side encryption"
  type        = string
  default     = "alias/aws/s3"
}

variable "enable_versioning" {
  description = "Enable versioning for the S3 bucket"
  type        = bool
  default     = true
}

variable "block_public_access" {
  description = "Boolean to enable/disable S3 public access block configuration"
  type        = bool
  default     = true
}

variable "log_bucket_name" {
  description = "Name of the S3 bucket for access logging"
  type        = string
}

variable "log_bucket_tags" {
  description = "Tags for the logging bucket"
  type        = map(string)
  default = {
    Name        = "Clinica Secure Logs"
    Environment = "prod"
    Project     = "Clinica-Segura"
  }
}

variable "role_clinica_secure_name" {
  description = "IAM role name for clinic employees"
  type        = string
  default     = "Clinica-Secure"
}

variable "role_clinica_iot_name" {
  description = "IAM role name for IoT devices"
  type        = string
  default     = "Clinica-IoT"
}

variable "role_clinica_admin_name" {
  description = "IAM role name for administrators"
  type        = string
  default     = "Clinica-Admin"
}

variable "iot_policy_name" {
  description = "Name of IoT PutObject-only policy"
  type        = string
  default     = "Clinica-IoT-PutObject-Only"
}

variable "rw_policy_name" {
  description = "Name of RW employee policy"
  type        = string
  default     = "Clinica-Secure-RW"
}

variable "admin_policy_name" {
  description = "Name of Admin full S3 access policy"
  type        = string
  default     = "Clinica-Admin-FullAccess"
}

variable "backup_role_name" {
  description = "IAM Role for AWS Backup"
  type        = string
  default     = "Clinica-Backup-Role"
}

variable "backup_policy_name" {
  description = "Name of backup S3 access inline policy"
  type        = string
  default     = "Clinica-Backup-S3-Access"
}

variable "backup_vault_name" {
  description = "Name of backup vault"
  type        = string
  default     = "clinic-secure-vault"
}

variable "backup_plan_name" {
  description = "Name of AWS Backup plan"
  type        = string
  default     = "clinic-secure-backup-plan"
}

variable "backup_schedule" {
  description = "Cron schedule for AWS Backup"
  type        = string
  default     = "cron(0 5 * * ? *)"
}

variable "backup_retention_days" {
  description = "Retention time for backups"
  type        = number
  default     = 90
}

variable "backup_tags" {
  description = "Tags for backup vault and plan"
  type        = map(string)
  default = {
    Name        = "Clinica Secure Backup"
    Environment = "prod"
    Project     = "Clinica-Segura"
  }
}