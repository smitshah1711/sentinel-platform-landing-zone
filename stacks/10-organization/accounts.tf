resource "aws_organizations_account" "this" {
  for_each = var.accounts

  name      = coalesce(each.value.name, "sentinel-${each.key}")
  email     = each.value.email
  parent_id = local.ou_ids[each.value.ou]

  # Creates OrganizationAccountAccessRole in the new account, trusted by the management account.
  role_name = var.break_glass_role_name

  iam_user_access_to_billing = "DENY"

  # Never close an account from Terraform: closing is rate-limited and takes 90 days.
  # To retire one, move it to the Suspended OU instead.
  close_on_deletion = false

  tags = {
    environment = each.value.ou
  }

  lifecycle {
    prevent_destroy = true
    # These can only be set at creation time.
    ignore_changes = [role_name, iam_user_access_to_billing]
  }
}
