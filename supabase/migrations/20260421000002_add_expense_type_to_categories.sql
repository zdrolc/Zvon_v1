-- =============================================================================
-- FINTOP - Tipo de gasto en categorías
-- =============================================================================
-- Taxonomía: fijo_obligatorio / variable_necesario / variable_prescindible

ALTER TABLE categories
ADD COLUMN expense_type TEXT CHECK (expense_type IN ('fixed', 'variable_necessary', 'variable_discretionary'));

COMMENT ON COLUMN categories.expense_type IS
  'Clasificación del tipo de gasto: fixed=fijo obligatorio, variable_necessary=variable necesario, variable_discretionary=variable prescindible';
