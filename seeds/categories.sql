-- Categorías globales (user_id = NULL)
-- Se puede ejecutar múltiples veces (borra y recrea)

-- Borrar categorías globales existentes
DELETE FROM categories WHERE user_id IS NULL;

-- Ingresos (Verde esmeralda)
INSERT INTO categories (name, icon, color, computable, group_name) VALUES
('Nómina', 'briefcase', '#34d399', TRUE, 'Ingresos'),
('Freelance', 'laptop', '#34d399', TRUE, 'Ingresos'),
('Inversiones', 'trending-up', '#34d399', TRUE, 'Ingresos'),
('Reembolsos', 'rotate-ccw', '#34d399', TRUE, 'Ingresos'),
('Ayudas y subvenciones', 'landmark', '#34d399', TRUE, 'Ingresos'),
('Otros ingresos', 'plus-circle', '#34d399', TRUE, 'Ingresos');

-- Gastos - Hogar (Índigo)
INSERT INTO categories (name, icon, color, computable, group_name) VALUES
('Alquiler', 'home', '#818cf8', TRUE, 'Hogar'),
('Hipoteca', 'home', '#818cf8', TRUE, 'Hogar'),
('Luz', 'zap', '#818cf8', TRUE, 'Hogar'),
('Gas', 'flame', '#818cf8', TRUE, 'Hogar'),
('Agua', 'droplet', '#818cf8', TRUE, 'Hogar'),
('Internet y teléfono', 'wifi', '#818cf8', TRUE, 'Hogar'),
('Seguros', 'shield', '#818cf8', TRUE, 'Hogar'),
('Mantenimiento hogar', 'wrench', '#818cf8', TRUE, 'Hogar'),
('Comunidad de vecinos', 'building', '#818cf8', TRUE, 'Hogar'),
('Servicio doméstico', 'brush-cleaning', '#818cf8', TRUE, 'Hogar');

-- Gastos - Alimentación (Ámbar)
INSERT INTO categories (name, icon, color, computable, group_name) VALUES
('Supermercado', 'shopping-cart', '#fbbf24', TRUE, 'Alimentación'),
('Restaurantes', 'utensils', '#fbbf24', TRUE, 'Alimentación'),
('Cafeterías', 'coffee', '#fbbf24', TRUE, 'Alimentación'),
('Comida a domicilio', 'package', '#fbbf24', TRUE, 'Alimentación');

-- Gastos - Transporte (Celeste)
INSERT INTO categories (name, icon, color, computable, group_name) VALUES
('Gasolina', 'fuel', '#38bdf8', TRUE, 'Transporte'),
('Transporte público', 'train', '#38bdf8', TRUE, 'Transporte'),
('Taxi y VTC', 'car', '#38bdf8', TRUE, 'Transporte'),
('Parking', 'square-parking', '#38bdf8', TRUE, 'Transporte'),
('Seguro coche', 'shield', '#38bdf8', TRUE, 'Transporte'),
('Mantenimiento coche', 'wrench', '#38bdf8', TRUE, 'Transporte'),
('Préstamo coche', 'car', '#38bdf8', TRUE, 'Transporte');

-- Gastos - Salud (Rosa)
INSERT INTO categories (name, icon, color, computable, group_name) VALUES
('Farmacia', 'pill', '#f472b6', TRUE, 'Salud'),
('Salud', 'stethoscope', '#f472b6', TRUE, 'Salud'),
('Dentista', 'smile', '#f472b6', TRUE, 'Salud'),
('Seguro médico', 'heart-pulse', '#f472b6', TRUE, 'Salud'),
('Belleza', 'sparkles', '#f472b6', TRUE, 'Salud');

-- Gastos - Ocio y entretenimiento (Violeta)
INSERT INTO categories (name, icon, color, computable, group_name) VALUES
('Suscripciones', 'tv', '#a78bfa', TRUE, 'Ocio'),
('Cine y espectáculos', 'clapperboard', '#a78bfa', TRUE, 'Ocio'),
('Deportes y gimnasio', 'dumbbell', '#a78bfa', TRUE, 'Ocio'),
('Viajes', 'plane', '#a78bfa', TRUE, 'Ocio'),
('Hobbies', 'gamepad-2', '#a78bfa', TRUE, 'Ocio');

-- Gastos - Compras (Cyan)
INSERT INTO categories (name, icon, color, computable, group_name) VALUES
('Ropa y calzado', 'shirt', '#22d3ee', TRUE, 'Compras'),
('Electrónica', 'smartphone', '#22d3ee', TRUE, 'Compras'),
('Hogar y decoración', 'sofa', '#22d3ee', TRUE, 'Compras'),
('Regalos', 'gift', '#22d3ee', TRUE, 'Compras');

-- Gastos - Educación y familia (Teal)
INSERT INTO categories (name, icon, color, computable, group_name) VALUES
('Educación', 'graduation-cap', '#2dd4bf', TRUE, 'Familia'),
('Guardería', 'baby', '#2dd4bf', TRUE, 'Familia'),
('Hijos', 'users', '#2dd4bf', TRUE, 'Familia'),
('Mascotas', 'dog', '#2dd4bf', TRUE, 'Familia');

-- Gastos - Finanzas (Rose)
INSERT INTO categories (name, icon, color, computable, group_name) VALUES
('Impuestos', 'receipt', '#fb7185', TRUE, 'Finanzas'),
('Comisiones bancarias', 'landmark', '#fb7185', TRUE, 'Finanzas'),
('Préstamos', 'banknote', '#fb7185', TRUE, 'Finanzas'),
('Donaciones', 'heart-handshake', '#fb7185', TRUE, 'Finanzas');

-- Gastos - Otros (Piedra)
INSERT INTO categories (name, icon, color, computable, group_name) VALUES
('Otros gastos', 'circle-dot', '#a8a29e', TRUE, 'Otros');

-- No computables (Gris)
INSERT INTO categories (name, icon, color, computable, group_name) VALUES
('Transferencia entre cuentas', 'arrow-left-right', '#9ca3af', FALSE, 'No computable'),
('Ajuste de saldo', 'scale', '#9ca3af', FALSE, 'No computable'),
('Ahorro e inversiones', 'banknote', '#9ca3af', FALSE, 'No computable');
