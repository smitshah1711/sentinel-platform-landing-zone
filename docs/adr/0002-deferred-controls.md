# ADR 0002: Controls deferred from week 1

- Status: Accepted
- Date: 2026-11-09

Week 1 focuses on the account structure and the audit trail. These controls are deliberately left for later weeks and are skipped in `.checkov.yaml` with a reason:

| Control | Why deferred | Planned week |
| --- | --- | --- |
| S3 server access logging on state and trail buckets | Needs a dedicated access-log bucket; CloudTrail already records management events | 4 |
| Cross-region replication of log and state buckets | Belongs with the DR design | 12 |
| CloudTrail to CloudWatch Logs + metric alarms | Belongs with the observability stack | 11 |
| Org-wide AWS Config, GuardDuty, Security Hub with delegated admin to `security-tooling` | Separate stack once accounts exist | 4 |
| Shield Advanced | About US$3,000/month on a 1-year commitment; documented, not deployed | n/a |
