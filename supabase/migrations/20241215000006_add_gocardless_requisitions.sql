-- Requisitions de GoCardless (una por banco/usuario)
CREATE TABLE gocardless_requisitions (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  requisition_id text NOT NULL UNIQUE,    -- ID de GoCardless
  agreement_id text NOT NULL,             -- End User Agreement ID
  institution_id text NOT NULL,           -- ej: CAIXABANK_CAIXESBB
  institution_name text,                  -- ej: CaixaBank
  status text DEFAULT 'pending',          -- pending, linked, expired, revoked
  link text,                              -- URL de autorización
  access_expires_at timestamptz NOT NULL, -- Cuándo expira
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now(),

  UNIQUE(user_id, institution_id)
);

-- Vincular accounts a requisitions
ALTER TABLE accounts ADD COLUMN requisition_id uuid REFERENCES gocardless_requisitions(id) ON DELETE SET NULL;

-- Índices
CREATE INDEX idx_requisitions_user_id ON gocardless_requisitions(user_id);
CREATE INDEX idx_requisitions_expires ON gocardless_requisitions(access_expires_at);
CREATE INDEX idx_accounts_requisition ON accounts(requisition_id);

-- RLS
ALTER TABLE gocardless_requisitions ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own requisitions"
  ON gocardless_requisitions FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own requisitions"
  ON gocardless_requisitions FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own requisitions"
  ON gocardless_requisitions FOR UPDATE
  USING (auth.uid() = user_id);

-- Trigger para updated_at
CREATE TRIGGER update_requisitions_updated_at
  BEFORE UPDATE ON gocardless_requisitions
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();
