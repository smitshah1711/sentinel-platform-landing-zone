variable "home_region" {
  type    = string
  default = "ca-central-1"
}

variable "state_bucket" {
  description = "Remote-state bucket from 00-bootstrap. Leave null to derive it."
  type        = string
  default     = null
}

variable "admin_user" {
  description = "Your own Identity Center user. Added to the platform-admins group."
  type = object({
    user_name   = string
    given_name  = string
    family_name = string
    email       = string
  })
}

variable "session_duration" {
  description = "ISO-8601 session length for permission sets."
  type        = string
  default     = "PT4H"
}
