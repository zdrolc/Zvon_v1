-- Actualizar colores de categorías globales para usar un color único por grupo
-- Paleta: tonos suaves (Tailwind 400) elegantes y consistentes

-- Ingresos: Verde esmeralda (#34d399)
UPDATE categories SET color = '#34d399' WHERE user_id IS NULL AND group_name = 'Ingresos';

-- Hogar: Índigo (#818cf8)
UPDATE categories SET color = '#818cf8' WHERE user_id IS NULL AND group_name = 'Hogar';

-- Alimentación: Ámbar (#fbbf24)
UPDATE categories SET color = '#fbbf24' WHERE user_id IS NULL AND group_name = 'Alimentación';

-- Transporte: Celeste (#38bdf8)
UPDATE categories SET color = '#38bdf8' WHERE user_id IS NULL AND group_name = 'Transporte';

-- Salud: Rosa (#f472b6)
UPDATE categories SET color = '#f472b6' WHERE user_id IS NULL AND group_name = 'Salud';

-- Ocio: Violeta (#a78bfa)
UPDATE categories SET color = '#a78bfa' WHERE user_id IS NULL AND group_name = 'Ocio';

-- Compras: Cyan (#22d3ee)
UPDATE categories SET color = '#22d3ee' WHERE user_id IS NULL AND group_name = 'Compras';

-- Familia: Teal (#2dd4bf)
UPDATE categories SET color = '#2dd4bf' WHERE user_id IS NULL AND group_name = 'Familia';

-- Finanzas: Rose (#fb7185)
UPDATE categories SET color = '#fb7185' WHERE user_id IS NULL AND group_name = 'Finanzas';

-- Otros: Piedra (#a8a29e)
UPDATE categories SET color = '#a8a29e' WHERE user_id IS NULL AND group_name = 'Otros';

-- No computable: Gris (#9ca3af)
UPDATE categories SET color = '#9ca3af' WHERE user_id IS NULL AND group_name = 'No computable';