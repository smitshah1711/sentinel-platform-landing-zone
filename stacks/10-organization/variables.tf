variable "home_region" {
  description = "Primary region (Canadian data residency)."
  type        = string
  default     = "ca-central-1"
}

variable "allowed_regions" {
  description = "Regions workloads may use. us-east-1 is the DR region and hosts global services (CloudFront, ACM for CloudFront, WAF for CloudFront)."
  type        = list(string)
  default     = ["ca-central-1", "us-east-1"]
}

variable "accounts" {
  description = "Member accounts to create. Keys are account names; ou must be one of: security, infrastructure, nonprod, prod."
  type = map(object({
    email = string
    ou    = string
  }))

  validation {
    condition     = alltrue([for a in values(var.accounts) : contains(["security", "infrastructure", "nonprod", "prod"], a.ou)])
    error_message = "Each account's ou must be one of: security, infrastructure, nonprod, prod."
  }

  validation {
    condition     = length(distinct([for a in values(var.accounts) : lower(a.email)])) == length(var.accounts)
    error_message = "Every account needs a unique email address."
  }
}

variable "break_glass_role_name" {
  description = "Role exempted from the region guardrail so an admin can always recover an account."
  type        = string
  default     = "OrganizationAccountAccessRole"
}
