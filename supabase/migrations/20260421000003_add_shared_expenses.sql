-- =============================================================================
-- FINTOP - Gastos compartidos
-- =============================================================================

-- Añadir campos de gasto compartido a transaction_splits
ALTER TABLE transaction_splits
ADD COLUMN shared_with TEXT,           -- Nombre de la persona con quien se comparte
ADD COLUMN shared_amount DECIMAL(12,2), -- Importe que te deben devolver
ADD COLUMN shared_status TEXT DEFAULT 'pending'
    CHECK (shared_status IN ('pending', 'recovered'));  -- pending=adelantado, recovered=recuperado

-- Tabla de gastos compartidos directos (sin split, si el gasto completo es compartido)
CREATE TABLE shared_expenses (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    transaction_raw_id UUID REFERENCES transactions_raw(id) ON DELETE SET NULL,
    description TEXT NOT NULL,
    total_amount DECIMAL(12,2) NOT NULL,
    your_amount DECIMAL(12,2) NOT NULL,   -- Tu parte (computable)
    shared_amount DECIMAL(12,2) NOT NULL, -- Lo que te deben devolver
    shared_with TEXT,                     -- Con quién lo compartiste
    status TEXT NOT NULL DEFAULT 'pending'
        CHECK (status IN ('pending', 'recovered')),
    recovered_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_shared_expenses_user ON shared_expenses(user_id);
CREATE INDEX idx_shared_expenses_status ON shared_expenses(user_id, status);

CREATE TRIGGER shared_expenses_updated_at
    BEFORE UPDATE ON shared_expenses
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();

ALTER TABLE shared_expenses ENABLE ROW LEVEL SECURITY;

CREATE POLICY shared_expenses_select ON shared_expenses
    FOR SELECT USING (user_id = auth.uid());

CREATE POLICY shared_expenses_insert ON shared_expenses
    FOR INSERT WITH CHECK (user_id = auth.uid());

CREATE POLICY shared_expenses_update ON shared_expenses
    FOR UPDATE USING (user_id = auth.uid());

CREATE POLICY shared_expenses_delete ON shared_expenses
    FOR DELETE USING (user_id = auth.uid());
