-- Supplier Approval & Evaluation extension for Cloudflare D1 (SQLite).
-- This migration is additive: it does not rename or delete existing tables.
-- Apply once, after the existing `suppliers` table has been created.

ALTER TABLE suppliers ADD COLUMN supplier_type TEXT;
ALTER TABLE suppliers ADD COLUMN tax_id TEXT;
ALTER TABLE suppliers ADD COLUMN approval_status TEXT NOT NULL DEFAULT 'DRAFT';
ALTER TABLE suppliers ADD COLUMN risk_level TEXT;
ALTER TABLE suppliers ADD COLUMN approved_scope TEXT;
ALTER TABLE suppliers ADD COLUMN last_evaluation_date TEXT;
ALTER TABLE suppliers ADD COLUMN next_evaluation_date TEXT;
ALTER TABLE suppliers ADD COLUMN approved_by TEXT;
ALTER TABLE suppliers ADD COLUMN approved_at TEXT;
ALTER TABLE suppliers ADD COLUMN suspended_by TEXT;
ALTER TABLE suppliers ADD COLUMN suspended_at TEXT;
ALTER TABLE suppliers ADD COLUMN disqualified_by TEXT;
ALTER TABLE suppliers ADD COLUMN disqualified_at TEXT;
ALTER TABLE suppliers ADD COLUMN is_deleted INTEGER NOT NULL DEFAULT 0 CHECK (is_deleted IN (0, 1));

CREATE TABLE IF NOT EXISTS supplier_sites (
  id TEXT PRIMARY KEY, supplier_id TEXT NOT NULL, site_name TEXT, address TEXT,
  country TEXT, province TEXT, is_main_site INTEGER NOT NULL DEFAULT 0,
  created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP, updated_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (supplier_id) REFERENCES suppliers(id)
);
CREATE TABLE IF NOT EXISTS supplier_contacts (
  id TEXT PRIMARY KEY, supplier_id TEXT NOT NULL, contact_name TEXT NOT NULL, position TEXT,
  phone TEXT, email TEXT, primary_contact INTEGER NOT NULL DEFAULT 0,
  FOREIGN KEY (supplier_id) REFERENCES suppliers(id)
);
CREATE TABLE IF NOT EXISTS supplier_categories (
  id TEXT PRIMARY KEY, code TEXT NOT NULL UNIQUE, name TEXT NOT NULL, risk_weight INTEGER NOT NULL DEFAULT 0
);
CREATE TABLE IF NOT EXISTS supplier_material_links (
  id TEXT PRIMARY KEY, supplier_id TEXT NOT NULL, material_type TEXT NOT NULL,
  material_id TEXT NOT NULL, approved INTEGER NOT NULL DEFAULT 0, approved_scope TEXT,
  created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (supplier_id) REFERENCES suppliers(id)
);
CREATE TABLE IF NOT EXISTS supplier_document_requirements (
  id TEXT PRIMARY KEY, category_code TEXT NOT NULL, document_type TEXT NOT NULL,
  required_flag INTEGER NOT NULL DEFAULT 1, critical_flag INTEGER NOT NULL DEFAULT 0,
  review_frequency_days INTEGER, UNIQUE(category_code, document_type)
);
CREATE TABLE IF NOT EXISTS supplier_documents (
  id TEXT PRIMARY KEY, supplier_id TEXT NOT NULL, document_type TEXT NOT NULL,
  required_flag INTEGER NOT NULL DEFAULT 0, critical_flag INTEGER NOT NULL DEFAULT 0, file_id TEXT,
  issue_date TEXT, expiry_date TEXT, review_date TEXT, status TEXT NOT NULL DEFAULT 'MISSING',
  approved_by TEXT, approved_at TEXT, remarks TEXT,
  FOREIGN KEY (supplier_id) REFERENCES suppliers(id)
);
CREATE TABLE IF NOT EXISTS supplier_approval_records (
  id TEXT PRIMARY KEY, supplier_id TEXT NOT NULL, approval_decision TEXT NOT NULL,
  approval_scope TEXT, conditions TEXT, approved_by TEXT NOT NULL, approved_at TEXT NOT NULL,
  next_review_date TEXT, evidence_file_id TEXT, management_reviewed_by TEXT, management_reviewed_at TEXT,
  FOREIGN KEY (supplier_id) REFERENCES suppliers(id)
);
CREATE TABLE IF NOT EXISTS supplier_risk_assessments (
  id TEXT PRIMARY KEY, supplier_id TEXT NOT NULL, criticality_score INTEGER NOT NULL DEFAULT 0,
  food_safety_score INTEGER NOT NULL DEFAULT 0, certification_score INTEGER NOT NULL DEFAULT 0,
  supplier_history_score INTEGER NOT NULL DEFAULT 0, location_score INTEGER NOT NULL DEFAULT 0,
  inspection_score INTEGER NOT NULL DEFAULT 0, complaint_score INTEGER NOT NULL DEFAULT 0,
  audit_score INTEGER NOT NULL DEFAULT 0, traceability_score INTEGER NOT NULL DEFAULT 0,
  total_score INTEGER NOT NULL, risk_level TEXT NOT NULL, assessor_id TEXT NOT NULL,
  assessment_date TEXT NOT NULL, review_due_date TEXT NOT NULL,
  FOREIGN KEY (supplier_id) REFERENCES suppliers(id)
);
CREATE TABLE IF NOT EXISTS supplier_audit_plans (
  id TEXT PRIMARY KEY, supplier_id TEXT NOT NULL, audit_type TEXT NOT NULL, planned_date TEXT,
  auditor_id TEXT, scope TEXT, standard_name TEXT, status TEXT NOT NULL DEFAULT 'PLANNED',
  FOREIGN KEY (supplier_id) REFERENCES suppliers(id)
);
CREATE TABLE IF NOT EXISTS supplier_audit_results (
  id TEXT PRIMARY KEY, plan_id TEXT, supplier_id TEXT NOT NULL, audit_date TEXT NOT NULL,
  audit_score REAL, findings_count INTEGER NOT NULL DEFAULT 0, major_nc INTEGER NOT NULL DEFAULT 0,
  minor_nc INTEGER NOT NULL DEFAULT 0, result TEXT NOT NULL, next_audit_date TEXT, evidence_file_id TEXT,
  FOREIGN KEY (plan_id) REFERENCES supplier_audit_plans(id), FOREIGN KEY (supplier_id) REFERENCES suppliers(id)
);
CREATE TABLE IF NOT EXISTS supplier_evaluations (
  id TEXT PRIMARY KEY, supplier_id TEXT NOT NULL, quality_score REAL, food_safety_score REAL,
  delivery_score REAL, documentation_score REAL, responsiveness_score REAL, audit_score REAL,
  overall_score REAL NOT NULL, result TEXT NOT NULL, evaluator_id TEXT NOT NULL,
  evaluation_date TEXT NOT NULL, next_evaluation_date TEXT NOT NULL,
  FOREIGN KEY (supplier_id) REFERENCES suppliers(id)
);
CREATE TABLE IF NOT EXISTS supplier_scorecards (
  id TEXT PRIMARY KEY, supplier_id TEXT NOT NULL, period_month TEXT NOT NULL, receiving_lots INTEGER NOT NULL DEFAULT 0,
  pass_rate REAL, fail_count INTEGER NOT NULL DEFAULT 0, hold_count INTEGER NOT NULL DEFAULT 0,
  coa_missing_count INTEGER NOT NULL DEFAULT 0, temperature_failure_count INTEGER NOT NULL DEFAULT 0,
  foreign_matter_count INTEGER NOT NULL DEFAULT 0, complaint_count INTEGER NOT NULL DEFAULT 0,
  capa_count INTEGER NOT NULL DEFAULT 0, audit_score REAL, document_compliance_rate REAL,
  on_time_closure_rate REAL, overall_score REAL, generated_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
  UNIQUE(supplier_id, period_month), FOREIGN KEY (supplier_id) REFERENCES suppliers(id)
);
CREATE TABLE IF NOT EXISTS supplier_nonconformities (
  id TEXT PRIMARY KEY, supplier_id TEXT NOT NULL, material_id TEXT, source_record_id TEXT,
  source_type TEXT NOT NULL, lot_number TEXT, severity TEXT NOT NULL, description TEXT NOT NULL,
  containment_action TEXT, supplier_response TEXT, verification_result TEXT, status TEXT NOT NULL DEFAULT 'OPEN',
  created_by TEXT NOT NULL, created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (supplier_id) REFERENCES suppliers(id)
);
CREATE TABLE IF NOT EXISTS supplier_capa_links (
  id TEXT PRIMARY KEY, supplier_nc_id TEXT NOT NULL, capa_case_id TEXT, scar_number TEXT NOT NULL UNIQUE,
  FOREIGN KEY (supplier_nc_id) REFERENCES supplier_nonconformities(id)
);
CREATE TABLE IF NOT EXISTS supplier_reapproval_history (
  id TEXT PRIMARY KEY, supplier_id TEXT NOT NULL, reason TEXT NOT NULL, decision TEXT NOT NULL,
  reviewed_by TEXT NOT NULL, reviewed_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (supplier_id) REFERENCES suppliers(id)
);
CREATE TABLE IF NOT EXISTS supplier_status_history (
  id TEXT PRIMARY KEY, supplier_id TEXT NOT NULL, old_status TEXT, new_status TEXT NOT NULL,
  reason TEXT NOT NULL, changed_by TEXT NOT NULL, changed_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (supplier_id) REFERENCES suppliers(id)
);
CREATE TABLE IF NOT EXISTS supplier_risk_criteria (
  id TEXT PRIMARY KEY, criterion_code TEXT NOT NULL UNIQUE, name TEXT NOT NULL, weight INTEGER NOT NULL,
  active INTEGER NOT NULL DEFAULT 1 CHECK(active IN (0,1))
);
CREATE TABLE IF NOT EXISTS supplier_audit_logs (
  id TEXT PRIMARY KEY, event_type TEXT NOT NULL, entity_type TEXT NOT NULL, entity_id TEXT NOT NULL,
  before_value TEXT, after_value TEXT, reason TEXT, performed_by TEXT NOT NULL,
  performed_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP
);
CREATE TRIGGER IF NOT EXISTS supplier_audit_logs_immutable_update
BEFORE UPDATE ON supplier_audit_logs BEGIN SELECT RAISE(ABORT, 'supplier audit logs are immutable'); END;
CREATE TRIGGER IF NOT EXISTS supplier_audit_logs_immutable_delete
BEFORE DELETE ON supplier_audit_logs BEGIN SELECT RAISE(ABORT, 'supplier audit logs are immutable'); END;

CREATE INDEX IF NOT EXISTS idx_suppliers_approval_status ON suppliers(approval_status, is_deleted);
CREATE INDEX IF NOT EXISTS idx_supplier_documents_expiry ON supplier_documents(expiry_date, status);
CREATE INDEX IF NOT EXISTS idx_supplier_material_links_supplier ON supplier_material_links(supplier_id, approved);
CREATE INDEX IF NOT EXISTS idx_supplier_nc_supplier ON supplier_nonconformities(supplier_id, status, severity);
CREATE INDEX IF NOT EXISTS idx_supplier_audit_events_entity ON supplier_audit_logs(entity_type, entity_id, performed_at);

INSERT OR IGNORE INTO supplier_risk_criteria (id, criterion_code, name, weight) VALUES
  ('risk-food-safety', 'FOOD_SAFETY', 'Food Safety', 25), ('risk-audit', 'AUDIT', 'Audit', 15),
  ('risk-complaint', 'COMPLAINT', 'Complaint', 10), ('risk-history', 'SUPPLIER_HISTORY', 'Supplier History', 10),
  ('risk-certification', 'CERTIFICATION', 'Certification', 10), ('risk-inspection', 'INCOMING_INSPECTION', 'Incoming Inspection', 15),
  ('risk-traceability', 'TRACEABILITY', 'Traceability', 10), ('risk-delivery', 'DELIVERY', 'Delivery', 5);
