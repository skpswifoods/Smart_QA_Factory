# Smart QA Factory

Smart QA Factory is a browser-based QA workspace for HACCP checklist execution and supplier governance.

## Supplier Approval & Evaluation extension

`suppliers.html` provides the responsive supplier-management dashboard entry point. It includes Thai-first status labels, approval work queues, risk distribution, expiring-control alerts, a touch-friendly draft-supplier flow, and a direct return to the existing checklist. It is intentionally an additive page; the existing checklist and its routes are unchanged.

The D1-compatible schema is in `migrations/001_supplier_approval.sql`. It extends the existing `suppliers` table and adds related sites, contacts, materials, document control, approvals, risk assessments, audits, evaluations, scorecards, supplier NC/SCAR, reapproval/status history, risk configuration, and immutable audit records.

### Apply the schema

Run the migration once after the base `suppliers` table is available:

```sh
npx wrangler d1 execute <DATABASE_NAME> --file=migrations/001_supplier_approval.sql
```

The migration uses SQLite/D1 types and stores document evidence as `file_id` references so the actual objects can reside in Cloudflare R2. It creates only additive tables, columns, indexes, and immutable-log triggers; no existing table is renamed or dropped.
