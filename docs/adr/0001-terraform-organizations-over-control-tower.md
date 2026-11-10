# ADR 0001: Build the landing zone with Terraform instead of Control Tower

- Status: Accepted
- Date: 2026-11-09

## Context

Sentinel needs a multi-account AWS foundation with guardrails, central logging and single sign-on. AWS offers Control Tower (with Account Factory for Terraform) as a managed option. The alternative is to build the same pieces directly with Terraform on AWS Organizations.

## Decision

Build the landing zone directly in Terraform: Organizations, OUs, accounts, SCPs, an organization CloudTrail and IAM Identity Center, split into four stacks with separate state.

## Reasons

- Every guardrail is visible and reviewable as code in a pull request.
- It teaches the underlying services that Control Tower hides, which is the point of this project.
- Fewer moving parts to tear down. Control Tower adds its own StackSets, Config rules and a landing-zone version to manage.

## Consequences

- We own drift detection and upgrades that Control Tower would handle.
- AWS Config, GuardDuty and Security Hub need to be enabled org-wide by us (planned for the security weeks).
- Moving to Control Tower later would mean importing or recreating the OUs.
