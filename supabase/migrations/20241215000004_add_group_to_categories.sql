-- Migración: Añadir group_name a categories
-- Permite agrupar categorías por tipo (Ingresos, Gastos - Hogar, etc.)

ALTER TABLE categories
ADD COLUMN group_name TEXT;

-- Índice para filtrar por grupo
CREATE INDEX idx_categories_group_name ON categories(group_name);

COMMENT ON COLUMN categories.group_name IS 'Grupo al que pertenece la categoría (Ingresos, Gastos - Hogar, etc.)';
