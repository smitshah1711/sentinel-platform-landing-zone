data "aws_caller_identity" "management" {}

data "terraform_remote_state" "org" {
  backend = "s3"

  config = {
    bucket = coalesce(var.state_bucket, "sentinel-tfstate-${data.aws_caller_identity.management.account_id}-${var.home_region}")
    key    = "platform-landing-zone/10-organization.tfstate"
    region = var.home_region
  }
}

data "aws_ssoadmin_instances" "this" {}

locals {
  instance_arn      = tolist(data.aws_ssoadmin_instances.this.arns)[0]
  identity_store_id = tolist(data.aws_ssoadmin_instances.this.identity_store_ids)[0]
  account_ids       = data.terraform_remote_state.org.outputs.account_ids

  # ------------------------------------------------------------ Permission sets
  permission_sets = {
    PlatformAdmin = {
      description      = "Full administrator. Platform team only."
      managed_policies = ["arn:aws:iam::aws:policy/AdministratorAccess"]
    }
    Engineer = {
      description      = "Build and operate workloads; no IAM user or Organizations changes."
      managed_policies = ["arn:aws:iam::aws:policy/PowerUserAccess"]
    }
    ReadOnly = {
      description      = "Read-only access for troubleshooting."
      managed_policies = ["arn:aws:iam::aws:policy/ReadOnlyAccess"]
    }
    SecurityAudit = {
      description = "Auditors: security configuration and logs, read-only."
      managed_policies = [
        "arn:aws:iam::aws:policy/SecurityAudit",
        "arn:aws:iam::aws:policy/job-function/ViewOnlyAccess",
      ]
    }
  }

  # ------------------------------------------------------------ Who gets what, where
  # Engineers can change dev and staging, but only read prod. Prod changes go through the pipeline.
  access_matrix = {
    "platform-admins" = { for name in keys(local.account_ids) : name => "PlatformAdmin" }
    "engineers" = {
      "dev"             = "Engineer"
      "staging"         = "Engineer"
      "prod"            = "ReadOnly"
      "shared-services" = "ReadOnly"
    }
    "auditors" = { for name in keys(local.account_ids) : name => "SecurityAudit" }
  }

  assignments = merge([
    for group, accounts in local.access_matrix : {
      for account, permission_set in accounts :
      "${group}/${account}/${permission_set}" => {
        group          = group
        account_id     = local.account_ids[account]
        permission_set = permission_set
      }
    }
  ]...)

  policy_attachments = merge([
    for ps, cfg in local.permission_sets : {
      for arn in cfg.managed_policies : "${ps}/${arn}" => { permission_set = ps, policy_arn = arn }
    }
  ]...)
}

resource "aws_ssoadmin_permission_set" "this" {
  for_each = local.permission_sets

  name             = each.key
  description      = each.value.description
  instance_arn     = local.instance_arn
  session_duration = var.session_duration
}

resource "aws_ssoadmin_managed_policy_attachment" "this" {
  for_each = local.policy_attachments

  instance_arn       = local.instance_arn
  permission_set_arn = aws_ssoadmin_permission_set.this[each.value.permission_set].arn
  managed_policy_arn = each.value.policy_arn
}

# ---------------------------------------------------------------- Groups and users

resource "aws_identitystore_group" "this" {
  for_each = local.access_matrix

  identity_store_id = local.identity_store_id
  display_name      = "sentinel-${each.key}"
  description       = "Sentinel ${each.key}"
}

resource "aws_identitystore_user" "admin" {
  identity_store_id = local.identity_store_id

  user_name    = var.admin_user.user_name
  display_name = "${var.admin_user.given_name} ${var.admin_user.family_name}"

  name {
    given_name  = var.admin_user.given_name
    family_name = var.admin_user.family_name
  }

  emails {
    value   = var.admin_user.email
    primary = true
  }
}

resource "aws_identitystore_group_membership" "admin" {
  identity_store_id = local.identity_store_id
  group_id          = aws_identitystore_group.this["platform-admins"].group_id
  member_id         = aws_identitystore_user.admin.user_id
}

# ---------------------------------------------------------------- Assignments

resource "aws_ssoadmin_account_assignment" "this" {
  for_each = local.assignments

  instance_arn       = local.instance_arn
  permission_set_arn = aws_ssoadmin_permission_set.this[each.value.permission_set].arn

  principal_type = "GROUP"
  principal_id   = aws_identitystore_group.this[each.value.group].group_id

  target_type = "AWS_ACCOUNT"
  target_id   = each.value.account_id

  depends_on = [aws_ssoadmin_managed_policy_attachment.this]
}

# The management account is assigned separately: only admins, never engineers.
resource "aws_ssoadmin_account_assignment" "management_admin" {
  instance_arn       = local.instance_arn
  permission_set_arn = aws_ssoadmin_permission_set.this["PlatformAdmin"].arn

  principal_type = "GROUP"
  principal_id   = aws_identitystore_group.this["platform-admins"].group_id

  target_type = "AWS_ACCOUNT"
  target_id   = data.aws_caller_identity.management.account_id

  depends_on = [aws_ssoadmin_managed_policy_attachment.this]
}
