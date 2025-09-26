# CDN Deployment Guide

**Last Updated:** 2025-09-26 (UTC+08)

---

## Overview
This runbook describes how to provision and maintain the Elderly Daycare CDN (CloudFront) using Terraform modules introduced in Phase F. It covers staging deployment, production rollout, cache management, and incident response.

---

## Prerequisites
- Terraform >= 1.6 installed locally or via CI runner.
- AWS credentials with permissions to manage CloudFront, ACM, Route53, and S3 logging buckets.
- Provisioned S3 bucket for media assets and access logs.
- ACM certificate in the same region as CloudFront (us-east-1) for custom domains.
- Variables populated in `ops/terraform/environments/<env>/terraform.tfvars`:
  - `media_bucket_domain`
  - `log_bucket`
  - `acm_certificate_arn`

---

## Deployment Steps
1. **Initialize Terraform**
   ```bash
   cd ops/terraform/environments/staging
   terraform init
   ```
2. **Review Plan**
   ```bash
   terraform plan -out=plan.tfplan
   ```
   - Verify distribution aliases, origin domain, and TLS details in the plan output.
3. **Apply Changes**
   ```bash
   terraform apply plan.tfplan
   ```
   - Confirm distribution ID and domain in the outputs.
4. **Update DNS**
   - Create/verify CNAME records pointing to the CloudFront domain (e.g., `media-staging.elderlydaycare.test`).
   - Propagate via Route53 or relevant DNS provider.
5. **Validate Deployment**
   - Use `curl -I https://media-staging.elderlydaycare.test/path/to/asset` to confirm 200 responses and `Via: CloudFront` header.
   - Check CloudFront console for “Deployed” status.

---

## Cache Invalidation
- Issue targeted invalidations for modified assets:
  ```bash
  aws cloudfront create-invalidation \
    --distribution-id <DIST_ID> \
    --paths "/path/to/asset.jpg"
  ```
- For full site invalidation, use `/ *` (note space removed) but limit frequency due to cost/performance impact.

---

## Monitoring & Alerts
- Metrics: monitor CloudFront `4xx`, `5xx`, and cache hit rate via CloudWatch; integrate into Grafana dashboards.
- Logs: enable log aggregation from S3 log bucket to analytics pipeline.
- Alerts: configure SNS/Slack alerts for elevated error rates or origin latency.

---

## Rollback Procedure
1. Re-run Terraform with previous configuration/state to revert changes.
2. If emergency rollback required, point DNS back to origin server or disable distribution via AWS console.
3. Document incident in ops log and run a postmortem.

---

## Cost Management
- Start with `PriceClass_100` (US, Canada, Europe). Expand to `PriceClass_All` only when required.
- Review monthly CloudFront spend; adjust caching rules and TTLs for high-volume assets.
- Enable CloudWatch usage reports for visibility.

---

## Incident Response
- Symptoms: increased latency, 5xx errors, invalid SSL certificate, unauthorized content.
- Immediate actions:
  1. Validate origin health and SSL validity.
  2. Check IAM/OAI permissions for S3 origins.
  3. Review recent Terraform changes for misconfigurations.
- Escalation: notify DevOps lead and product owner; involve security if data exposure suspected.

---

## Maintenance Checklist
- Quarterly: review cache behaviors, TLS minimum version, and WAF integration requirements.
- Bi-annual: rotate ACM certificates and verify logging bucket lifecycle policies.
- After each change: update this runbook with lessons learned.
