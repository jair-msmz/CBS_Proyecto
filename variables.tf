variable "aws_access_key" {
  description = "AWS Access Key for authentication"
  type        = string
  sensitive   = true
}

variable "region" {
  description = "AWS Region for resource deployment"
  type        = string
  default     = "us-east-1"
}

variable "bucket_name" {
  description = "Name of the S3 bucket for secure data storage"
  type        = string
  default     = "clinicasecurebucket1"
}

variable "acl" {
  description = "Access control list for the S3 bucket"
  type        = string
  default     = "private"
}

variable "versioning" {
  description = "Enable versioning for the S3 bucket"
  type        = bool
  default     = true
}

variable "kms_key_id" {
  description = "KMS Key ID for server-side encryption"
  type        = string
  default     = "alias/aws/s3"
}

variable "public_access_block" {
  description = "Block public access settings for the S3 bucket"
  type        = bool
  default     = true
}

variable "tags" {
  description = "Tags to apply to the S3 bucket"
  type        = map(string)
  default = {
    Name        = "Clinica Secure Data"
    Environment = "prod"
    Project     = "Clinica-Segura"
  }
}

variable "log_bucket_name" {
  description = "Name of the S3 bucket for access logging"
  type        = string
  default     = "clinicasecurebucket1-logs"
}

variable "account" {
  description = "AWS Account ID"
  type        = string
  default     = "498823212740"
}