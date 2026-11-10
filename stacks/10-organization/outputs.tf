output "organization_id" {
  value = aws_organizations_organization.this.id
}

output "management_account_id" {
  value = aws_organizations_organization.this.master_account_id
}

output "root_id" {
  value = local.root_id
}

output "ou_ids" {
  value = merge(local.ou_ids, {
    workloads = aws_organizations_organizational_unit.workloads.id
    suspended = aws_organizations_organizational_unit.suspended.id
  })
}

output "account_ids" {
  description = "Member account IDs keyed by account name (log-archive, dev, ...)."
  value       = { for k, a in aws_organizations_account.this : k => a.id }
}

output "allowed_regions" {
  value = var.allowed_regions
}
