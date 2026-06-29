-- =============================================================================
-- FINTOP - Presupuestos por categoría (base + overrides mensuales)
-- =============================================================================

-- Presupuesto base por categoría: aplica todos los meses por defecto
CREATE TABLE category_budgets (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    category_id UUID NOT NULL REFERENCES categories(id) ON DELETE CASCADE,
    amount DECIMAL(12,2) NOT NULL CHECK (amount >= 0),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(user_id, category_id)
);

-- Override mensual: sobrescribe el importe base para un mes concreto
CREATE TABLE category_budget_overrides (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    category_id UUID NOT NULL REFERENCES categories(id) ON DELETE CASCADE,
    year INT NOT NULL,
    month INT NOT NULL CHECK (month BETWEEN 1 AND 12),
    amount DECIMAL(12,2) NOT NULL CHECK (amount >= 0),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(user_id, category_id, year, month)
);

CREATE INDEX idx_category_budgets_user ON category_budgets(user_id);
CREATE INDEX idx_category_budget_overrides_user ON category_budget_overrides(user_id);
CREATE INDEX idx_category_budget_overrides_period ON category_budget_overrides(user_id, year, month);

CREATE TRIGGER category_budgets_updated_at
    BEFORE UPDATE ON category_budgets
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE TRIGGER category_budget_overrides_updated_at
    BEFORE UPDATE ON category_budget_overrides
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();

ALTER TABLE category_budgets ENABLE ROW LEVEL SECURITY;
ALTER TABLE category_budget_overrides ENABLE ROW LEVEL SECURITY;

CREATE POLICY category_budgets_select ON category_budgets FOR SELECT USING (user_id = auth.uid());
CREATE POLICY category_budgets_insert ON category_budgets FOR INSERT WITH CHECK (user_id = auth.uid());
CREATE POLICY category_budgets_update ON category_budgets FOR UPDATE USING (user_id = auth.uid());
CREATE POLICY category_budgets_delete ON category_budgets FOR DELETE USING (user_id = auth.uid());

CREATE POLICY category_budget_overrides_select ON category_budget_overrides FOR SELECT USING (user_id = auth.uid());
CREATE POLICY category_budget_overrides_insert ON category_budget_overrides FOR INSERT WITH CHECK (user_id = auth.uid());
CREATE POLICY category_budget_overrides_update ON category_budget_overrides FOR UPDATE USING (user_id = auth.uid());
CREATE POLICY category_budget_overrides_delete ON category_budget_overrides FOR DELETE USING (user_id = auth.uid());

-- =============================================================================
-- RPC: presupuesto efectivo por mes (base + override aplicado)
-- =============================================================================
CREATE OR REPLACE FUNCTION get_effective_category_budgets(p_year INT, p_month INT)
RETURNS TABLE(category_id UUID, amount DECIMAL(12,2), is_override BOOLEAN)
LANGUAGE sql SECURITY INVOKER AS $$
    SELECT
        cb.category_id,
        COALESCE(cbo.amount, cb.amount)::DECIMAL(12,2) AS amount,
        (cbo.id IS NOT NULL) AS is_override
    FROM category_budgets cb
    LEFT JOIN category_budget_overrides cbo
        ON cbo.user_id = cb.user_id
        AND cbo.category_id = cb.category_id
        AND cbo.year = p_year
        AND cbo.month = p_month
    WHERE cb.user_id = auth.uid();
$$;

-- =============================================================================
-- RPC: media mensual de gasto por categoría (últimos N meses completos)
-- =============================================================================
CREATE OR REPLACE FUNCTION get_category_monthly_averages(p_months INT DEFAULT 6)
RETURNS TABLE(category_id UUID, avg_monthly_amount DECIMAL(12,2))
LANGUAGE sql SECURITY INVOKER AS $$
    WITH monthly_totals AS (
        SELECT
            t.category_id,
            DATE_TRUNC('month', t.booking_date) AS month,
            SUM(ABS(t.amount)) AS monthly_total
        FROM transactions t
        WHERE t.amount < 0
            AND t.computable = TRUE
            AND t.category_id IS NOT NULL
            AND t.booking_date >= DATE_TRUNC('month', NOW() - (p_months || ' months')::INTERVAL)
            AND t.booking_date < DATE_TRUNC('month', NOW())
        GROUP BY t.category_id, DATE_TRUNC('month', t.booking_date)
    )
    SELECT category_id, ROUND(AVG(monthly_total), 2)::DECIMAL(12,2) AS avg_monthly_amount
    FROM monthly_totals
    GROUP BY category_id;
$$;
