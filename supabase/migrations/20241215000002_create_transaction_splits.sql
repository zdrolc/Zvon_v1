-- Migración: Crear tabla transaction_splits
-- Permite dividir una transacción en múltiples categorías/importes

-- =============================================================================
-- TABLA
-- =============================================================================

CREATE TABLE transaction_splits (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    transaction_raw_id UUID NOT NULL REFERENCES transactions_raw(id) ON DELETE CASCADE,
    amount DECIMAL(12,2) NOT NULL,
    category_id UUID REFERENCES categories(id),
    notes TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

COMMENT ON TABLE transaction_splits IS 'División manual de transacciones en múltiples categorías/importes';
COMMENT ON COLUMN transaction_splits.amount IS 'Importe parcial de la transacción';
COMMENT ON COLUMN transaction_splits.category_id IS 'Categoría para este split';

-- =============================================================================
-- ÍNDICES
-- =============================================================================

CREATE INDEX idx_transaction_splits_raw ON transaction_splits(transaction_raw_id);
CREATE INDEX idx_transaction_splits_category ON transaction_splits(category_id);

-- =============================================================================
-- TRIGGER
-- =============================================================================

CREATE TRIGGER transaction_splits_updated_at
    BEFORE UPDATE ON transaction_splits
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- =============================================================================
-- ROW LEVEL SECURITY
-- =============================================================================

ALTER TABLE transaction_splits ENABLE ROW LEVEL SECURITY;

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
