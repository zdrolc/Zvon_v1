-- Actualizar colores de categorías globales
-- Nueva paleta coherente por grupo, grises solo para No computable

-- Ingresos (Verdes)
UPDATE categories SET color = '#22c55e' WHERE user_id IS NULL AND name = 'Nómina';
UPDATE categories SET color = '#16a34a' WHERE user_id IS NULL AND name = 'Freelance';
UPDATE categories SET color = '#15803d' WHERE user_id IS NULL AND name = 'Inversiones';
UPDATE categories SET color = '#4ade80' WHERE user_id IS NULL AND name = 'Reembolsos';
UPDATE categories SET color = '#34d399' WHERE user_id IS NULL AND name = 'Ayudas y subvenciones';
UPDATE categories SET color = '#a3e635' WHERE user_id IS NULL AND name = 'Otros ingresos';

-- Hogar (Azules/Índigo)
UPDATE categories SET color = '#3b82f6' WHERE user_id IS NULL AND name = 'Alquiler';
UPDATE categories SET color = '#2563eb' WHERE user_id IS NULL AND name = 'Hipoteca';
UPDATE categories SET color = '#60a5fa' WHERE user_id IS NULL AND name = 'Luz';
UPDATE categories SET color = '#1d4ed8' WHERE user_id IS NULL AND name = 'Gas';
UPDATE categories SET color = '#38bdf8' WHERE user_id IS NULL AND name = 'Agua';
UPDATE categories SET color = '#6366f1' WHERE user_id IS NULL AND name = 'Internet y teléfono';
UPDATE categories SET color = '#818cf8' WHERE user_id IS NULL AND name = 'Seguros';
UPDATE categories SET color = '#4f46e5' WHERE user_id IS NULL AND name = 'Mantenimiento hogar';
UPDATE categories SET color = '#a5b4fc' WHERE user_id IS NULL AND name = 'Comunidad de vecinos';
UPDATE categories SET color = '#c7d2fe' WHERE user_id IS NULL AND name = 'Servicio doméstico';

-- Alimentación (Naranjas/Ámbar)
UPDATE categories SET color = '#f59e0b' WHERE user_id IS NULL AND name = 'Supermercado';
UPDATE categories SET color = '#d97706' WHERE user_id IS NULL AND name = 'Restaurantes';
UPDATE categories SET color = '#b45309' WHERE user_id IS NULL AND name = 'Cafeterías';
UPDATE categories SET color = '#92400e' WHERE user_id IS NULL AND name = 'Comida a domicilio';

-- Transporte (Celestes/Sky)
UPDATE categories SET color = '#0ea5e9' WHERE user_id IS NULL AND name = 'Gasolina';
UPDATE categories SET color = '#0284c7' WHERE user_id IS NULL AND name = 'Transporte público';
UPDATE categories SET color = '#0369a1' WHERE user_id IS NULL AND name = 'Taxi y VTC';
UPDATE categories SET color = '#075985' WHERE user_id IS NULL AND name = 'Parking';
UPDATE categories SET color = '#38bdf8' WHERE user_id IS NULL AND name = 'Seguro coche';
UPDATE categories SET color = '#7dd3fc' WHERE user_id IS NULL AND name = 'Mantenimiento coche';
UPDATE categories SET color = '#0c4a6e' WHERE user_id IS NULL AND name = 'Préstamo coche';

-- Salud (Rosas)
UPDATE categories SET color = '#ec4899' WHERE user_id IS NULL AND name = 'Farmacia';
UPDATE categories SET color = '#db2777' WHERE user_id IS NULL AND name = 'Salud';
UPDATE categories SET color = '#be185d' WHERE user_id IS NULL AND name = 'Dentista';
UPDATE categories SET color = '#9d174d' WHERE user_id IS NULL AND name = 'Seguro médico';
UPDATE categories SET color = '#f472b6' WHERE user_id IS NULL AND name = 'Belleza';

-- Ocio (Violetas)
UPDATE categories SET color = '#a78bfa' WHERE user_id IS NULL AND name = 'Suscripciones';
UPDATE categories SET color = '#7c3aed' WHERE user_id IS NULL AND name = 'Cine y espectáculos';
UPDATE categories SET color = '#6d28d9' WHERE user_id IS NULL AND name = 'Deportes y gimnasio';
UPDATE categories SET color = '#8b5cf6' WHERE user_id IS NULL AND name = 'Viajes';
UPDATE categories SET color = '#5b21b6' WHERE user_id IS NULL AND name = 'Hobbies';

-- Compras (Cyans)
UPDATE categories SET color = '#06b6d4' WHERE user_id IS NULL AND name = 'Ropa y calzado';
UPDATE categories SET color = '#0891b2' WHERE user_id IS NULL AND name = 'Electrónica';
UPDATE categories SET color = '#0e7490' WHERE user_id IS NULL AND name = 'Hogar y decoración';
UPDATE categories SET color = '#155e75' WHERE user_id IS NULL AND name = 'Regalos';

-- Familia (Teal)
UPDATE categories SET color = '#14b8a6' WHERE user_id IS NULL AND name = 'Educación';
UPDATE categories SET color = '#0d9488' WHERE user_id IS NULL AND name = 'Guardería';
UPDATE categories SET color = '#0f766e' WHERE user_id IS NULL AND name = 'Hijos';
UPDATE categories SET color = '#115e59' WHERE user_id IS NULL AND name = 'Mascotas';

-- Finanzas (Rose/Rojos)
UPDATE categories SET color = '#e11d48' WHERE user_id IS NULL AND name = 'Impuestos';
UPDATE categories SET color = '#be123c' WHERE user_id IS NULL AND name = 'Comisiones bancarias';
UPDATE categories SET color = '#9f1239' WHERE user_id IS NULL AND name = 'Préstamos';
UPDATE categories SET color = '#f43f5e' WHERE user_id IS NULL AND name = 'Donaciones';

-- Otros (Marrón cálido)
UPDATE categories SET color = '#a1887f' WHERE user_id IS NULL AND name = 'Otros gastos';

-- No computable (Grises - único grupo)
UPDATE categories SET color = '#71717a' WHERE user_id IS NULL AND name = 'Transferencia entre cuentas';
UPDATE categories SET color = '#52525b' WHERE user_id IS NULL AND name = 'Ajuste de saldo';
UPDATE categories SET color = '#3f3f46' WHERE user_id IS NULL AND name = 'Ahorro e inversiones';
