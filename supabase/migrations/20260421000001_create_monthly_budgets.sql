-- =============================================================================
-- FINTOP - Presupuestos mensuales
-- =============================================================================

CREATE TABLE monthly_budgets (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    year INT NOT NULL,
    month INT NOT NULL CHECK (month BETWEEN 1 AND 12),
    amount DECIMAL(12,2) NOT NULL CHECK (amount > 0),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(user_id, year, month)
);

CREATE INDEX idx_monthly_budgets_user ON monthly_budgets(user_id);
CREATE INDEX idx_monthly_budgets_period ON monthly_budgets(user_id, year, month);

CREATE TRIGGER monthly_budgets_updated_at
    BEFORE UPDATE ON monthly_budgets
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();

ALTER TABLE monthly_budgets ENABLE ROW LEVEL SECURITY;

CREATE POLICY monthly_budgets_select ON monthly_budgets
    FOR SELECT USING (user_id = auth.uid());

CREATE POLICY monthly_budgets_insert ON monthly_budgets
    FOR INSERT WITH CHECK (user_id = auth.uid());

CREATE POLICY monthly_budgets_update ON monthly_budgets
    FOR UPDATE USING (user_id = auth.uid());

CREATE POLICY monthly_budgets_delete ON monthly_budgets
    FOR DELETE USING (user_id = auth.uid());
