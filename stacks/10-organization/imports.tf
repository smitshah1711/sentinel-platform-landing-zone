# Adopt resources that existed before this repo (created by hand in the console).
# Import blocks run during `terraform plan/apply` (Terraform >= 1.5) and are a no-op once
# the resources are in state. They can be deleted after the first successful apply.

import {
  to = aws_organizations_organization.this
  id = "o-vswb9g6eug"
}

import {
  to = aws_organizations_organizational_unit.security
  id = "ou-e40k-d5nwq9b2"
}

import {
  to = aws_organizations_organizational_unit.workloads
  id = "ou-e40k-nzinvzrh"
}

import {
  to = aws_organizations_organizational_unit.infrastructure
  id = "ou-e40k-qd72jl4g"
}

# Existing "staging" account. Terraform moves it from Workloads into Workloads/NonProd.
import {
  to = aws_organizations_account.this["staging"]
  id = "649183940529"
}
