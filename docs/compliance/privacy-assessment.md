# Privacy Assessment (Phase A)

**Objective:** Execute the compliance decision flow outlined in `Project Requirements Document v2.md` §7 by documenting data processing context, regulatory scope, and immediate next steps.

## 1. Data Processing Context

- **Controllers / Owners:** Elderly Daycare Platform (internal), partner daycare centers.
- **Processors:** Cloud hosting provider, object storage/CDN, email provider (SES/SendGrid), SMS provider (Twilio), Stripe (payments), monitoring vendors.
- **Data Subjects:** Family caregivers, elderly clients, daycare staff, referral partners.
- **Purposes:** Service discovery, booking management, media sharing (testimonials/tours), communication, analytics, payments.

## 2. Regulatory Scope Assessment

| Regulation | Applicability | Basis |
| --- | --- | --- |
| HIPAA | Pending — depends on whether health info constitutes PHI transmitted electronically. | Health notes captured in `client_health_info` may include medical details. If platform hosts PHI, HIPAA safeguards and BAA required. |
| GDPR | Likely if EU residents data is processed. | Data capture forms allow international submission; need to clarify target regions. |
| CCPA/CPRA | Potential if processing California resident data and revenue/user thresholds met. | Assess business thresholds with legal counsel. |
| Local Privacy Laws | TBD | Evaluate jurisdictions where daycare centers operate. |

## 3. Data Inventory & Classification

Refer to `docs/compliance/data-map.md` for data elements, storage locations, and sensitivity levels. High-sensitivity domains include health notes, consent records, and booking metadata.

## 4. Risk Analysis (Initial)

- **Unauthorized Access:** Mitigate via RBAC, least-privilege, audit logging, MFA for admin roles.
- **Data Leakage (Media/Docs):** Enforce signed URLs, encryption, virus scanning, content moderation.
- **Regulatory Non-Compliance:** Execute DPIA (if GDPR), HIPAA risk assessment, and maintain evidence of safeguard implementation.
- **User Rights:** Implement deletion/anonymization workflows; document data retention timelines (`Project Requirements Document v2.md` §17).

## 5. Immediate Actions (Phase A → Phase B)

1. Determine PHI scope by interviewing daycare partners and reviewing captured health data.
2. If PHI confirmed, initiate BAA with hosting provider and training for staff with PHI access.
3. Validate geographical scope to decide on GDPR and other international obligations.
4. Draft privacy notice for public site; map consent language to booking forms.
5. Plan for Data Protection Impact Assessment (DPIA) if GDPR in scope (owner: Legal/Compliance Officer).

## 6. Documentation & Review

- This document to be reviewed quarterly and at each phase boundary.
- Sign-off required from Product Owner and Legal/Compliance Officer before moving into Phase B.
