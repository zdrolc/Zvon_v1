-- =============================================================================
-- FINTOP - Schema de base de datos
-- =============================================================================

-- Tabla de cuentas bancarias
CREATE TABLE accounts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    gocardless_account_id TEXT UNIQUE NOT NULL,
    bank_name TEXT,
    account_name TEXT,          -- Alias que pone el usuario
    iban TEXT,
    last_sync_at TIMESTAMPTZ,
    balance DECIMAL(12,2),
    balance_available DECIMAL(12,2),
    balance_currency TEXT DEFAULT 'EUR',
    balance_updated_at TIMESTAMPTZ,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Tabla raw: solo la toca la ETL (datos inmutables del banco)
CREATE TABLE transactions_raw (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    account_id UUID NOT NULL REFERENCES accounts(id) ON DELETE CASCADE,
    transaction_id TEXT NOT NULL,
    internal_transaction_id TEXT,
    entry_reference TEXT,

    -- Fechas
    booking_date DATE NOT NULL,
    value_date DATE,

    -- Importe
    amount DECIMAL(12,2) NOT NULL,
    currency TEXT NOT NULL DEFAULT 'EUR',

    -- Partes involucradas
    creditor_name TEXT,
    creditor_id TEXT,
    debtor_name TEXT,
    ultimate_debtor TEXT,

    -- Descripcion
    description TEXT,

    -- Referencias de pago
    end_to_end_id TEXT,
    mandate_id TEXT,

    -- Codigos de clasificacion
    bank_transaction_code TEXT,
    proprietary_code TEXT,
    purpose_code TEXT,

    -- Datos originales
    raw_data JSONB,

    -- Timestamps
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),

    -- Unique por cuenta + transaction_id
    UNIQUE(account_id, transaction_id)
);

-- Categorias de transacciones
-- user_id NULL = categoria global (visible para todos)
-- user_id NOT NULL = categoria personalizada del usuario
CREATE TABLE categories (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    icon TEXT,
    color TEXT,
    computable BOOLEAN DEFAULT TRUE,  -- FALSE = no cuenta en totales/graficos
    parent_id UUID REFERENCES categories(id),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Reglas de categorizacion automatica
-- user_id NULL = regla global, NOT NULL = regla del usuario
CREATE TABLE categorization_rules (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    pattern TEXT NOT NULL,
    match_type TEXT NOT NULL DEFAULT 'contains', -- contains, starts_with, exact, regex
    field TEXT NOT NULL DEFAULT 'description',   -- description, creditor_name, debtor_name
    category_id UUID NOT NULL REFERENCES categories(id) ON DELETE CASCADE,
    priority INT DEFAULT 0,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Tabla user: categorizacion (automatica y manual)
-- Relacion 1:1 con transactions_raw
CREATE TABLE transactions_user (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    transaction_raw_id UUID UNIQUE NOT NULL REFERENCES transactions_raw(id) ON DELETE CASCADE,
    auto_category_id UUID REFERENCES categories(id),  -- ETL escribe aqui
    category_id UUID REFERENCES categories(id),        -- Usuario sobrescribe aqui
    custom_date DATE,                                   -- Usuario sobrescribe fecha aqui
    notes TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Splits: division manual de transacciones
-- Relacion 1:N con transactions_raw (opcional)
-- Si existen splits, se ignora la categoria de transactions_user
CREATE TABLE transaction_splits (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    transaction_raw_id UUID NOT NULL REFERENCES transactions_raw(id) ON DELETE CASCADE,
    amount DECIMAL(12,2) NOT NULL,
    category_id UUID REFERENCES categories(id),
    notes TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- =============================================================================
-- VISTA PRINCIPAL
-- =============================================================================
-- Vista expandida: muestra transacciones con su categoria efectiva
-- - Sin splits: una fila por transaccion con COALESCE(manual, auto)
-- - Con splits: una fila por split

CREATE VIEW transactions WITH (security_invoker = true) AS
-- Transacciones SIN splits
SELECT
    r.id,
    r.id AS source_id,           -- ID de la transaccion original
    NULL::uuid AS split_id,      -- No es un split
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
    s.amount,                    -- Amount del split
    r.currency,
    r.description,
    r.creditor_name,
    r.debtor_name,
    s.category_id,               -- Categoria del split
    c.name AS category_name,
    c.icon AS category_icon,
    c.color AS category_color,
    COALESCE(c.computable, TRUE) AS computable,
    s.notes,                     -- Notes del split
    TRUE AS is_split,
    r.created_at,
    GREATEST(r.updated_at, s.updated_at) AS updated_at
FROM transactions_raw r
JOIN accounts a ON a.id = r.account_id
LEFT JOIN transactions_user u ON u.transaction_raw_id = r.id
JOIN transaction_splits s ON s.transaction_raw_id = r.id
LEFT JOIN categories c ON c.id = s.category_id
WHERE a.user_id = auth.uid();

-- =============================================================================
-- INDICES
-- =============================================================================

CREATE INDEX idx_accounts_user ON accounts(user_id);
CREATE INDEX idx_accounts_active ON accounts(is_active) WHERE is_active = TRUE;
CREATE INDEX idx_categories_user ON categories(user_id);
CREATE INDEX idx_categories_parent ON categories(parent_id);
CREATE INDEX idx_categorization_rules_user ON categorization_rules(user_id);
CREATE INDEX idx_categorization_rules_active ON categorization_rules(is_active) WHERE is_active = TRUE;
CREATE INDEX idx_transactions_raw_account ON transactions_raw(account_id);
CREATE INDEX idx_transactions_raw_booking_date ON transactions_raw(booking_date);
CREATE INDEX idx_transactions_raw_creditor ON transactions_raw(creditor_name);
CREATE INDEX idx_transactions_user_raw ON transactions_user(transaction_raw_id);
CREATE INDEX idx_transactions_user_category ON transactions_user(category_id);
CREATE INDEX idx_transactions_user_auto_category ON transactions_user(auto_category_id);
CREATE INDEX idx_transaction_splits_raw ON transaction_splits(transaction_raw_id);
CREATE INDEX idx_transaction_splits_category ON transaction_splits(category_id);

-- =============================================================================
-- TRIGGERS
-- =============================================================================

CREATE OR REPLACE FUNCTION update_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER accounts_updated_at
    BEFORE UPDATE ON accounts
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE TRIGGER categories_updated_at
    BEFORE UPDATE ON categories
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE TRIGGER categorization_rules_updated_at
    BEFORE UPDATE ON categorization_rules
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE TRIGGER transactions_raw_updated_at
    BEFORE UPDATE ON transactions_raw
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE TRIGGER transactions_user_updated_at
    BEFORE UPDATE ON transactions_user
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE TRIGGER transaction_splits_updated_at
    BEFORE UPDATE ON transaction_splits
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- =============================================================================
-- ROW LEVEL SECURITY
-- =============================================================================

ALTER TABLE accounts ENABLE ROW LEVEL SECURITY;
ALTER TABLE categories ENABLE ROW LEVEL SECURITY;
ALTER TABLE categorization_rules ENABLE ROW LEVEL SECURITY;
ALTER TABLE transactions_raw ENABLE ROW LEVEL SECURITY;
ALTER TABLE transactions_user ENABLE ROW LEVEL SECURITY;
ALTER TABLE transaction_splits ENABLE ROW LEVEL SECURITY;

-- Accounts: usuario solo ve las suyas
CREATE POLICY accounts_select ON accounts
    FOR SELECT USING (user_id = auth.uid());

CREATE POLICY accounts_insert ON accounts
    FOR INSERT WITH CHECK (user_id = auth.uid());

CREATE POLICY accounts_update ON accounts
    FOR UPDATE USING (user_id = auth.uid());

CREATE POLICY accounts_delete ON accounts
    FOR DELETE USING (user_id = auth.uid());

-- Categories: globales (user_id IS NULL) + propias del usuario
CREATE POLICY categories_select ON categories
    FOR SELECT USING (user_id IS NULL OR user_id = auth.uid());

CREATE POLICY categories_insert ON categories
    FOR INSERT WITH CHECK (user_id = auth.uid());

CREATE POLICY categories_update ON categories
    FOR UPDATE USING (user_id = auth.uid());

CREATE POLICY categories_delete ON categories
    FOR DELETE USING (user_id = auth.uid());

-- Categorization_rules: globales + propias
CREATE POLICY categorization_rules_select ON categorization_rules
    FOR SELECT USING (user_id IS NULL OR user_id = auth.uid());

CREATE POLICY categorization_rules_insert ON categorization_rules
    FOR INSERT WITH CHECK (user_id = auth.uid());

CREATE POLICY categorization_rules_update ON categorization_rules
    FOR UPDATE USING (user_id = auth.uid());

CREATE POLICY categorization_rules_delete ON categorization_rules
    FOR DELETE USING (user_id = auth.uid());

-- Transactions_raw: usuario solo ve las de sus cuentas
CREATE POLICY transactions_raw_select ON transactions_raw
    FOR SELECT USING (
        account_id IN (SELECT id FROM accounts WHERE user_id = auth.uid())
    );

-- Transactions_user: usuario solo ve/edita las de sus transacciones
CREATE POLICY transactions_user_select ON transactions_user
    FOR SELECT USING (
        transaction_raw_id IN (
            SELECT r.id FROM transactions_raw r
            JOIN accounts a ON a.id = r.account_id
            WHERE a.user_id = auth.uid()
        )
    );

CREATE POLICY transactions_user_insert ON transactions_user
    FOR INSERT WITH CHECK (
        transaction_raw_id IN (
            SELECT r.id FROM transactions_raw r
            JOIN accounts a ON a.id = r.account_id
            WHERE a.user_id = auth.uid()
        )
    );

CREATE POLICY transactions_user_update ON transactions_user
    FOR UPDATE USING (
        transaction_raw_id IN (
            SELECT r.id FROM transactions_raw r
            JOIN accounts a ON a.id = r.account_id
            WHERE a.user_id = auth.uid()
        )
    );

CREATE POLICY transactions_user_delete ON transactions_user
    FOR DELETE USING (
        transaction_raw_id IN (
            SELECT r.id FROM transactions_raw r
            JOIN accounts a ON a.id = r.account_id
            WHERE a.user_id = auth.uid()
        )
    );

-- Transaction_splits: usuario solo ve/edita los de sus transacciones
CREATE POLICY transaction_splits_select ON transaction_splits
    FOR SELECT USING (
        transaction_raw_id IN (
            SELECT r.id FROM transactions_raw r
            JOIN accounts a ON a.id = r.account_id
            WHERE a.user_id = auth.uid()
        )
    );

CREATE POLICY transaction_splits_insert ON transaction_splits
    FOR INSERT WITH CHECK (
        transaction_raw_id IN (
            SELECT r.id FROM transactions_raw r
            JOIN accounts a ON a.id = r.account_id
            WHERE a.user_id = auth.uid()
        )
    );

CREATE POLICY transaction_splits_update ON transaction_splits
    FOR UPDATE USING (
        transaction_raw_id IN (
            SELECT r.id FROM transactions_raw r
            JOIN accounts a ON a.id = r.account_id
            WHERE a.user_id = auth.uid()
        )
    );

CREATE POLICY transaction_splits_delete ON transaction_splits
    FOR DELETE USING (
        transaction_raw_id IN (
            SELECT r.id FROM transactions_raw r
            JOIN accounts a ON a.id = r.account_id
            WHERE a.user_id = auth.uid()
        )
    );
