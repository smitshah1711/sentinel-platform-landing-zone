variable "region" {
  description = "Home region for the state bucket."
  type        = string
  default     = "ca-central-1"
}

variable "state_bucket_prefix" {
  description = "Prefix for the state bucket name. The account ID and region are appended to keep it globally unique."
  type        = string
  default     = "sentinel-tfstate"
}
