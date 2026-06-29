-- Añadir campo custom_date a transactions_user
ALTER TABLE transactions_user ADD COLUMN custom_date DATE;

-- Recrear la vista transactions con COALESCE para custom_date
DROP VIEW IF EXISTS transactions;

CREATE VIEW transactions WITH (security_invoker = true) AS
-- Transacciones SIN splits
SELECT
    r.id,
    r.id AS source_id,
    NULL::uuid AS split_id,
    r.account_id,
    a.user_id,
    r.transaction_id,
    COALESCE(u.custom_date, r.booking_date) AS booking_date,
    r.value_date,
    r.amount,
    r.currency,
    r.description,
    r.creditor_name,
    r.debtor_name,
    COALESCE(u.category_id, u.auto_category_id) AS category_id,
    c.name AS category_name,
    c.icon AS category_icon,
    c.color AS category_color,
    COALESCE(c.computable, TRUE) AS computable,
    u.notes,
    FALSE AS is_split,
    r.created_at,
    GREATEST(r.updated_at, u.updated_at) AS updated_at
FROM transactions_raw r
JOIN accounts a ON a.id = r.account_id
LEFT JOIN transactions_user u ON u.transaction_raw_id = r.id
LEFT JOIN categories c ON c.id = COALESCE(u.category_id, u.auto_category_id)
WHERE a.user_id = auth.uid()
  AND NOT EXISTS (SELECT 1 FROM transaction_splits s WHERE s.transaction_raw_id = r.id)

UNION ALL

-- Transacciones CON splits (una fila por split)
SELECT
    r.id,
    r.id AS source_id,
    s.id AS split_id,
    r.account_id,
    a.user_id,
    r.transaction_id,
    COALESCE(u.custom_date, r.booking_date) AS booking_date,
    r.value_date,
    s.amount,
    r.currency,
    r.description,
    r.creditor_name,
    r.debtor_name,
    s.category_id,
    c.name AS category_name,
    c.icon AS category_icon,
    c.color AS category_color,
    COALESCE(c.computable, TRUE) AS computable,
    s.notes,
    TRUE AS is_split,
    r.created_at,
    GREATEST(r.updated_at, s.updated_at) AS updated_at
FROM transactions_raw r
JOIN accounts a ON a.id = r.account_id
LEFT JOIN transactions_user u ON u.transaction_raw_id = r.id
JOIN transaction_splits s ON s.transaction_raw_id = r.id
LEFT JOIN categories c ON c.id = s.category_id
WHERE a.user_id = auth.uid();
