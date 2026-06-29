-- =============================================================================
-- FINTOP - Provisiones y amortizaciones de imprevistos
-- =============================================================================

-- Provisiones: fondo mensual fijo para gastos previsibles (coche, hogar, etc.)
CREATE TABLE provisions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    monthly_amount DECIMAL(12,2) NOT NULL CHECK (monthly_amount > 0),
    icon TEXT,
    color TEXT,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Amortizaciones: gasto grande repartido en N cuotas mensuales
CREATE TABLE amortizations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    description TEXT NOT NULL,
    total_amount DECIMAL(12,2) NOT NULL CHECK (total_amount > 0),
    monthly_installment DECIMAL(12,2) NOT NULL CHECK (monthly_installment > 0),
    total_months INT NOT NULL CHECK (total_months > 0),
    paid_months INT NOT NULL DEFAULT 0 CHECK (paid_months >= 0),
    start_year INT NOT NULL,
    start_month INT NOT NULL CHECK (start_month BETWEEN 1 AND 12),
    amortization_type TEXT NOT NULL DEFAULT 'unexpected'
        CHECK (amortization_type IN ('unexpected', 'estimation_error')),
    transaction_raw_id UUID REFERENCES transactions_raw(id) ON DELETE SET NULL,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_provisions_user ON provisions(user_id);
CREATE INDEX idx_provisions_active ON provisions(user_id, is_active);
CREATE INDEX idx_amortizations_user ON amortizations(user_id);
CREATE INDEX idx_amortizations_active ON amortizations(user_id, is_active);

CREATE TRIGGER provisions_updated_at
    BEFORE UPDATE ON provisions
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE TRIGGER amortizations_updated_at
    BEFORE UPDATE ON amortizations
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();

ALTER TABLE provisions ENABLE ROW LEVEL SECURITY;
ALTER TABLE amortizations ENABLE ROW LEVEL SECURITY;

CREATE POLICY provisions_select ON provisions FOR SELECT USING (user_id = auth.uid());
CREATE POLICY provisions_insert ON provisions FOR INSERT WITH CHECK (user_id = auth.uid());
CREATE POLICY provisions_update ON provisions FOR UPDATE USING (user_id = auth.uid());
CREATE POLICY provisions_delete ON provisions FOR DELETE USING (user_id = auth.uid());

CREATE POLICY amortizations_select ON amortizations FOR SELECT USING (user_id = auth.uid());
CREATE POLICY amortizations_insert ON amortizations FOR INSERT WITH CHECK (user_id = auth.uid());
CREATE POLICY amortizations_update ON amortizations FOR UPDATE USING (user_id = auth.uid());
CREATE POLICY amortizations_delete ON amortizations FOR DELETE USING (user_id = auth.uid());
