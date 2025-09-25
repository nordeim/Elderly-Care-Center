# Data Map — Elderly Daycare Platform

**Purpose:** Inventory all personal and operational data elements processed by the platform, their storage locations, access paths, and associated safeguards. Maintained by the Product Owner and Security Lead (Phase A deliverable).

## Data Categories and Stores

| Domain | Key Tables / Stores | Data Elements | Sensitivity | Storage Notes | Access Roles |
| --- | --- | --- | --- | --- | --- |
| Authentication & RBAC | `users`, `personal_access_tokens`, `user_sessions` | Emails, password hashes, roles, session metadata | Medium | Stored in MariaDB (`database_schema_mysql_complete.sql`). Passwords hashed with Argon2id; sessions linked to Redis (planned). | Admin, Staff, Security Lead |
| Client Profiles | `clients`, `client_documents` | Names, contact details, addresses (JSON), consent status, uploaded documents | Medium–High | Client documents stored in encrypted S3 bucket with immutability for audit logs. | Admin (limited), Staff (view only), Compliance Officer |
| Health Information | `client_health_info` | Encrypted health summaries, care instructions | High / Potential PHI | AES-256 encrypted blobs; encryption keys sourced from KMS. Access requires break-glass logging. | Nursing Staff (approved), Compliance Officer |
| Booking & Scheduling | `booking_slots`, `slot_reservations`, `bookings`, `booking_status_history` | Service selections, attendees, status history, metadata (JSON) | Medium | MariaDB transactional tables with stored procedures controlling concurrency. | Admin, Staff |
| Payments | `payments` | Provider IDs, amounts, status metadata (no card data) | Medium | Stripe hosted checkout retains cardholder data. Only payment status stored. | Finance Role, Admin (view only) |
| Media Assets | `media_items` | File metadata, storage URLs, processing status | Medium | Stored in object storage with signed URLs, lifecycle policies (hot → warm → cold). | Media Engineer, Admin (read), Staff (limited) |
| Communications | `email_logs`, `sms_logs` | Recipient contact, message templates, delivery status | Medium | Stored with retention policy (12 months). Sensitive content minimized. | Admin, Support Lead |
| Auditing & Analytics | `audit_logs`, `page_views`, dashboards | Action payloads, user IDs, timestamps | Medium | Immutable logs retained 12 months; analytics aggregated for 365 days. | Security Lead, DevOps, Product Owner |

## Data Flows and Integrations

1. **Public Booking Flow:** Web forms capture prospective visitor data → API persists to `bookings` and triggers confirmation email (SES/SendGrid). Sensitive fields minimized; consent checkbox recorded.
2. **Media Upload:** Admin uploads via signed URL → object storage → virus scan → ffmpeg workers (Phase D) generate renditions → metadata updates `media_items`.
3. **Notifications:** Scheduled jobs enqueue reminders → email provider (SES/SendGrid) and SMS provider (Twilio). Delivery status backfilled into `email_logs`/`sms_logs`.
4. **Stripe Payments:** Hosted checkout session initiated from backend → Stripe handles card data → webhook updates `payments` table. Webhook secret stored in Vault.
5. **Analytics:** Prometheus and application logs stream to observability stack; aggregated metrics exported to dashboards for conversion monitoring.

## Access Controls & Safeguards

- **RBAC:** Roles defined in `roles-and-responsibilities.md`. Least-privilege enforced via Laravel policies and middleware.
- **Audit Logging:** Administrative actions (booking status changes, media publication, staff updates) recorded in `audit_logs`. Break-glass access to health info triggers mandatory audit entries.
- **Encryption:**
  - In-transit via TLS 1.2+ with HSTS and CSP headers (Phase G validation).
  - At-rest via storage provider encryption; additional envelope encryption for `client_health_info` blobs and `client_documents`.
- **Secrets Management:** Managed through Vault/KMS per `config/secrets/README.md` (Phase B deliverable).

## Retention and Deletion Commitments

- **Booking Data:** Retain 12 months after activity; anonymize on request (`Project Requirements Document v2.md` §17).
- **Health Info:** Retain 6 months after client exit unless legal requirements differ.
- **Communications Logs:** Retain 12 months; purge thereafter.
- **Backups:** Snapshot retention 90 days with quarterly restore tests.

## Action Items

- Confirm whether stored health notes qualify as PHI under HIPAA; if so, execute HIPAA workstream (BAA, training).
- Catalog third-party subprocessors and ensure DPAs/BAAs executed.
- Revisit this map at the end of each phase to incorporate new data elements (e.g., payments, analytics).
