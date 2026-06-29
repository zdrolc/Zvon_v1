-- Migración: Añadir auto_category_id a transactions_user
-- Permite separar la categorización automática (ETL) de la manual (usuario)

ALTER TABLE transactions_user
ADD COLUMN auto_category_id UUID REFERENCES categories(id);

-- Índice para búsquedas por categoría automática
CREATE INDEX idx_transactions_user_auto_category ON transactions_user(auto_category_id);

COMMENT ON COLUMN transactions_user.auto_category_id IS 'Categoría asignada automáticamente por la ETL';
COMMENT ON COLUMN transactions_user.category_id IS 'Categoría asignada manualmente por el usuario (override)';
