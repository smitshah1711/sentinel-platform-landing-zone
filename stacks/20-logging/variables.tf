variable "home_region" {
  type    = string
  default = "ca-central-1"
}

variable "state_bucket" {
  description = "Remote-state bucket from 00-bootstrap. Leave null to derive sentinel-tfstate-<management account>-<region>."
  type        = string
  default     = null
}

variable "trail_name" {
  type    = string
  default = "sentinel-org-trail"
}

variable "log_retention_days" {
  description = "How long CloudTrail logs are kept. 2,557 days is about 7 years, a common federal records requirement."
  type        = number
  default     = 2557
}

variable "glacier_transition_days" {
  description = "Move logs to Glacier Flexible Retrieval after this many days."
  type        = number
  default     = 90
}
