-- Migración: Poblar group_name en categorías existentes

-- Ingresos
UPDATE categories SET group_name = 'Ingresos' WHERE name IN (
  'Nómina', 'Freelance', 'Inversiones', 'Reembolsos',
  'Ayudas y subvenciones', 'Otros ingresos'
);

-- Hogar
UPDATE categories SET group_name = 'Hogar' WHERE name IN (
  'Alquiler', 'Hipoteca', 'Luz', 'Gas', 'Agua',
  'Internet y teléfono', 'Seguros', 'Mantenimiento hogar'
);

-- Alimentación
UPDATE categories SET group_name = 'Alimentación' WHERE name IN (
  'Supermercado', 'Restaurantes', 'Cafeterías', 'Comida a domicilio'
);

-- Transporte
UPDATE categories SET group_name = 'Transporte' WHERE name IN (
  'Gasolina', 'Transporte público', 'Taxi y VTC', 'Parking',
  'Seguro coche', 'Mantenimiento coche', 'Préstamo coche'
);

-- Salud
UPDATE categories SET group_name = 'Salud' WHERE name IN (
  'Farmacia', 'Salud', 'Dentista', 'Seguro médico'
);

-- Ocio
UPDATE categories SET group_name = 'Ocio' WHERE name IN (
  'Suscripciones', 'Cine y espectáculos', 'Deportes y gimnasio',
  'Viajes', 'Hobbies', 'Ocio'
);

-- Compras
UPDATE categories SET group_name = 'Compras' WHERE name IN (
  'Ropa y calzado', 'Electrónica', 'Hogar y decoración', 'Regalos'
);

-- Familia
UPDATE categories SET group_name = 'Familia' WHERE name IN (
  'Educación', 'Guardería', 'Hijos', 'Mascotas'
);

-- Finanzas
UPDATE categories SET group_name = 'Finanzas' WHERE name IN (
  'Impuestos', 'Comisiones bancarias', 'Préstamos', 'Donaciones'
);

-- Otros
UPDATE categories SET group_name = 'Otros' WHERE name = 'Otros gastos';

-- No computable
UPDATE categories SET group_name = 'No computable' WHERE name IN (
  'Transferencia entre cuentas', 'Ajuste de saldo', 'Ahorro e inversiones'
);
