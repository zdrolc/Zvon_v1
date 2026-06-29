-- Añadir campos de saldo a la tabla accounts
ALTER TABLE accounts
    ADD COLUMN balance DECIMAL(12,2),
    ADD COLUMN balance_available DECIMAL(12,2),
    ADD COLUMN balance_currency TEXT DEFAULT 'EUR',
    ADD COLUMN balance_updated_at TIMESTAMPTZ;
