# Service control policies. SCPs never apply to the management account.
# Policies are minified (jsonencode(jsondecode(...))) because SCPs are capped at 5,120 characters.

locals {
  break_glass_arn = "arn:aws:iam::*:role/${var.break_glass_role_name}"
}

# ------------------------------------------------- 1. Baseline guardrails (Root)

data "aws_iam_policy_document" "baseline" {
  statement {
    sid       = "DenyLeavingOrganization"
    effect    = "Deny"
    actions   = ["organizations:LeaveOrganization"]
    resources = ["*"]
  }

  statement {
    sid    = "ProtectAuditServices"
    effect = "Deny"
    actions = [
      "cloudtrail:DeleteTrail",
      "cloudtrail:StopLogging",
      "cloudtrail:UpdateTrail",
      "cloudtrail:PutEventSelectors",
      "config:DeleteConfigurationRecorder",
      "config:DeleteDeliveryChannel",
      "config:StopConfigurationRecorder",
      "guardduty:DeleteDetector",
      "guardduty:DisassociateFromAdministratorAccount",
      "guardduty:DisassociateFromMasterAccount",
      "securityhub:DisableSecurityHub",
    ]
    resources = ["*"]

    condition {
      test     = "ArnNotLike"
      variable = "aws:PrincipalARN"
      values   = [local.break_glass_arn]
    }
  }

  statement {
    sid       = "DenyRootUser"
    effect    = "Deny"
    actions   = ["*"]
    resources = ["*"]

    condition {
      test     = "StringLike"
      variable = "aws:PrincipalArn"
      values   = ["arn:aws:iam::*:root"]
    }
  }

  statement {
    sid    = "DenyIamUserAccessKeys"
    effect = "Deny"
    # Humans use Identity Center; pipelines use OIDC roles. No long-lived keys.
    actions   = ["iam:CreateAccessKey"]
    resources = ["*"]

    condition {
      test     = "ArnNotLike"
      variable = "aws:PrincipalARN"
      values   = [local.break_glass_arn]
    }
  }
}

resource "aws_organizations_policy" "baseline" {
  name        = "sentinel-baseline-guardrails"
  description = "Deny leaving the org, tampering with audit services, root-user actions and IAM access keys."
  type        = "SERVICE_CONTROL_POLICY"
  content     = jsonencode(jsondecode(data.aws_iam_policy_document.baseline.json))
}

resource "aws_organizations_policy_attachment" "baseline_root" {
  policy_id = aws_organizations_policy.baseline.id
  target_id = local.root_id
}

# ------------------------------------------------- 2. Region guardrail (Root)

data "aws_iam_policy_document" "region" {
  statement {
    sid       = "DenyOutsideAllowedRegions"
    effect    = "Deny"
    resources = ["*"]

    # Global services are exempt; their API calls resolve to us-east-1 or have no region.
    not_actions = [
      "a4b:*",
      "account:*",
      "acm:*",
      "aws-marketplace-management:*",
      "aws-marketplace:*",
      "aws-portal:*",
      "billing:*",
      "budgets:*",
      "ce:*",
      "cloudfront:*",
      "config:*",
      "cur:*",
      "directconnect:*",
      "ec2:DescribeRegions",
      "ec2:DescribeTransitGateways",
      "ec2:DescribeVpnGateways",
      "fms:*",
      "globalaccelerator:*",
      "health:*",
      "iam:*",
      "identitystore:*",
      "importexport:*",
      "kms:*",
      "networkmanager:*",
      "organizations:*",
      "payments:*",
      "pricing:*",
      "route53-recovery-cluster:*",
      "route53-recovery-control-config:*",
      "route53-recovery-readiness:*",
      "route53:*",
      "route53domains:*",
      "s3:GetAccountPublic*",
      "s3:ListAllMyBuckets",
      "s3:ListMultiRegionAccessPoints",
      "s3:PutAccountPublic*",
      "shield:*",
      "sso:*",
      "sts:*",
      "support:*",
      "tax:*",
      "trustedadvisor:*",
      "waf-regional:*",
      "waf:*",
      "wafv2:*",
      "wellarchitected:*",
    ]

    condition {
      test     = "StringNotEquals"
      variable = "aws:RequestedRegion"
      values   = var.allowed_regions
    }

    condition {
      test     = "ArnNotLike"
      variable = "aws:PrincipalARN"
      values   = [local.break_glass_arn]
    }
  }
}

resource "aws_organizations_policy" "region" {
  name        = "sentinel-region-guardrail"
  description = "Allow only ${join(", ", var.allowed_regions)} for regional services."
  type        = "SERVICE_CONTROL_POLICY"
  content     = jsonencode(jsondecode(data.aws_iam_policy_document.region.json))
}

resource "aws_organizations_policy_attachment" "region_root" {
  policy_id = aws_organizations_policy.region.id
  target_id = local.root_id
}

# ------------------------------------------------- 3. Deny all (Suspended OU)

data "aws_iam_policy_document" "deny_all" {
  statement {
    sid       = "DenyEverything"
    effect    = "Deny"
    actions   = ["*"]
    resources = ["*"]
  }
}

resource "aws_organizations_policy" "deny_all" {
  name        = "sentinel-deny-all"
  description = "Applied to the Suspended OU: accounts there can do nothing."
  type        = "SERVICE_CONTROL_POLICY"
  content     = jsonencode(jsondecode(data.aws_iam_policy_document.deny_all.json))
}

resource "aws_organizations_policy_attachment" "deny_all_suspended" {
  policy_id = aws_organizations_policy.deny_all.id
  target_id = aws_organizations_organizational_unit.suspended.id
}

# ------------------------------------------------- Tag policy (Root)

resource "aws_organizations_policy" "tags" {
  name        = "sentinel-tag-standard"
  description = "Standard casing and allowed values for core tags."
  type        = "TAG_POLICY"

  content = jsonencode({
    tags = {
      project = {
        tag_key = { "@@assign" = "project" }
      }
      environment = {
        tag_key   = { "@@assign" = "environment" }
        tag_value = { "@@assign" = ["security", "infrastructure", "nonprod", "prod", "dev", "staging"] }
      }
      owner = {
        tag_key = { "@@assign" = "owner" }
      }
    }
  })
}

resource "aws_organizations_policy_attachment" "tags_root" {
  policy_id = aws_organizations_policy.tags.id
  target_id = local.root_id
}
