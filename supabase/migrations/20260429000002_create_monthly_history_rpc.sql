-- =============================================================================
-- FINTOP - Histórico mensual de gasto vs presupuesto
-- =============================================================================
-- Devuelve, para los últimos N meses incluyendo el actual, el gasto total y el
-- presupuesto efectivo (override si existe, base si no). Filtro opcional por
-- categoría para alimentar la vista de detalle.

CREATE OR REPLACE FUNCTION get_monthly_history(p_months INT, p_category_id UUID DEFAULT NULL)
RETURNS TABLE(year INT, month INT, spent_total DECIMAL(12,2), budget_total DECIMAL(12,2))
LANGUAGE sql SECURITY INVOKER AS $$
    WITH months AS (
        SELECT
            EXTRACT(YEAR FROM m)::INT AS year,
            EXTRACT(MONTH FROM m)::INT AS month,
            m AS month_start
        FROM generate_series(
            DATE_TRUNC('month', NOW()) - ((p_months - 1) || ' months')::INTERVAL,
            DATE_TRUNC('month', NOW()),
            '1 month'::INTERVAL
        ) AS m
    ),
    spent AS (
        SELECT
            EXTRACT(YEAR FROM DATE_TRUNC('month', t.booking_date))::INT AS year,
            EXTRACT(MONTH FROM DATE_TRUNC('month', t.booking_date))::INT AS month,
            SUM(ABS(t.amount))::DECIMAL(12,2) AS total
        FROM transactions t
        WHERE t.amount < 0
            AND t.computable = TRUE
            AND t.category_id IS NOT NULL
            AND (p_category_id IS NULL OR t.category_id = p_category_id)
            AND t.booking_date >= (SELECT MIN(month_start) FROM months)
            AND t.booking_date < DATE_TRUNC('month', NOW()) + INTERVAL '1 month'
        GROUP BY 1, 2
    ),
    budget AS (
        SELECT
            mo.year,
            mo.month,
            COALESCE(SUM(COALESCE(cbo.amount, cb.amount)), 0)::DECIMAL(12,2) AS total
        FROM months mo
        LEFT JOIN category_budgets cb
            ON cb.user_id = auth.uid()
            AND (p_category_id IS NULL OR cb.category_id = p_category_id)
        LEFT JOIN category_budget_overrides cbo
            ON cbo.user_id = cb.user_id
            AND cbo.category_id = cb.category_id
            AND cbo.year = mo.year
            AND cbo.month = mo.month
        GROUP BY mo.year, mo.month
    )
    SELECT
        mo.year,
        mo.month,
        COALESCE(s.total, 0)::DECIMAL(12,2) AS spent_total,
        COALESCE(b.total, 0)::DECIMAL(12,2) AS budget_total
    FROM months mo
    LEFT JOIN spent s ON s.year = mo.year AND s.month = mo.month
    LEFT JOIN budget b ON b.year = mo.year AND b.month = mo.month
    ORDER BY mo.year, mo.month;
$$;
