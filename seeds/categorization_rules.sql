-- Reglas de categorización automática (globales)
-- Ejecutar DESPUÉS de categories.sql
-- Se puede ejecutar múltiples veces (borra y recrea)

-- Borrar reglas globales existentes
DELETE FROM categorization_rules WHERE user_id IS NULL;

-- Helper: obtener ID de categoría por nombre
-- Uso: (SELECT id FROM categories WHERE name = 'Supermercado' AND user_id IS NULL)

-- Supermercados
INSERT INTO categorization_rules (pattern, match_type, field, category_id, priority) VALUES
('mercadona', 'contains', 'description', (SELECT id FROM categories WHERE name = 'Supermercado' AND user_id IS NULL), 10),
('carrefour', 'contains', 'description', (SELECT id FROM categories WHERE name = 'Supermercado' AND user_id IS NULL), 10),
('lidl', 'contains', 'description', (SELECT id FROM categories WHERE name = 'Supermercado' AND user_id IS NULL), 10),
('aldi', 'contains', 'description', (SELECT id FROM categories WHERE name = 'Supermercado' AND user_id IS NULL), 10),
('dia ', 'contains', 'description', (SELECT id FROM categories WHERE name = 'Supermercado' AND user_id IS NULL), 10),
('eroski', 'contains', 'description', (SELECT id FROM categories WHERE name = 'Supermercado' AND user_id IS NULL), 10),
('condor', 'contains', 'description', (SELECT id FROM categories WHERE name = 'Supermercado' AND user_id IS NULL), 10),
('supermercados mas', 'contains', 'description', (SELECT id FROM categories WHERE name = 'Supermercado' AND user_id IS NULL), 10),
('el corte ingles', 'contains', 'description', (SELECT id FROM categories WHERE name = 'Supermercado' AND user_id IS NULL), 5);

-- Restaurantes y cafeterías
INSERT INTO categorization_rules (pattern, match_type, field, category_id, priority) VALUES
('mc donald', 'contains', 'description', (SELECT id FROM categories WHERE name = 'Restaurantes' AND user_id IS NULL), 10),
('burger king', 'contains', 'description', (SELECT id FROM categories WHERE name = 'Restaurantes' AND user_id IS NULL), 10),
('telepizza', 'contains', 'description', (SELECT id FROM categories WHERE name = 'Restaurantes' AND user_id IS NULL), 10),
('pizzeria', 'contains', 'description', (SELECT id FROM categories WHERE name = 'Restaurantes' AND user_id IS NULL), 10),
('restaurante', 'contains', 'description', (SELECT id FROM categories WHERE name = 'Restaurantes' AND user_id IS NULL), 10),
('braseri', 'contains', 'description', (SELECT id FROM categories WHERE name = 'Restaurantes' AND user_id IS NULL), 10),
('starbucks', 'contains', 'description', (SELECT id FROM categories WHERE name = 'Cafeterías' AND user_id IS NULL), 10),
('cafeteria', 'contains', 'description', (SELECT id FROM categories WHERE name = 'Cafeterías' AND user_id IS NULL), 10);

-- Transporte
INSERT INTO categorization_rules (pattern, match_type, field, category_id, priority) VALUES
('gasolina', 'contains', 'description', (SELECT id FROM categories WHERE name = 'Gasolina' AND user_id IS NULL), 10),
('cedipsa', 'contains', 'description', (SELECT id FROM categories WHERE name = 'Gasolina' AND user_id IS NULL), 10),
('repsol', 'contains', 'description', (SELECT id FROM categories WHERE name = 'Gasolina' AND user_id IS NULL), 10),
('cepsa', 'contains', 'description', (SELECT id FROM categories WHERE name = 'Gasolina' AND user_id IS NULL), 10),
('bp ', 'contains', 'description', (SELECT id FROM categories WHERE name = 'Gasolina' AND user_id IS NULL), 10),
('taxi', 'contains', 'description', (SELECT id FROM categories WHERE name = 'Taxi y VTC' AND user_id IS NULL), 10),
('uber', 'contains', 'description', (SELECT id FROM categories WHERE name = 'Taxi y VTC' AND user_id IS NULL), 10),
('cabify', 'contains', 'description', (SELECT id FROM categories WHERE name = 'Taxi y VTC' AND user_id IS NULL), 10),
('movilidad', 'contains', 'description', (SELECT id FROM categories WHERE name = 'Transporte público' AND user_id IS NULL), 10),
('tussam', 'contains', 'description', (SELECT id FROM categories WHERE name = 'Transporte público' AND user_id IS NULL), 10),
('renfe', 'contains', 'description', (SELECT id FROM categories WHERE name = 'Transporte público' AND user_id IS NULL), 10),
('metro', 'contains', 'description', (SELECT id FROM categories WHERE name = 'Transporte público' AND user_id IS NULL), 10);

-- Préstamo coche
INSERT INTO categorization_rules (pattern, match_type, field, category_id, priority) VALUES
('santander consumer', 'contains', 'creditor_name', (SELECT id FROM categories WHERE name = 'Préstamo coche' AND user_id IS NULL), 10),
('volkswagen financial', 'contains', 'creditor_name', (SELECT id FROM categories WHERE name = 'Préstamo coche' AND user_id IS NULL), 10),
('psa finance', 'contains', 'creditor_name', (SELECT id FROM categories WHERE name = 'Préstamo coche' AND user_id IS NULL), 10),
('rci banque', 'contains', 'creditor_name', (SELECT id FROM categories WHERE name = 'Préstamo coche' AND user_id IS NULL), 10),
('toyota financial', 'contains', 'creditor_name', (SELECT id FROM categories WHERE name = 'Préstamo coche' AND user_id IS NULL), 10),
('bmw financial', 'contains', 'creditor_name', (SELECT id FROM categories WHERE name = 'Préstamo coche' AND user_id IS NULL), 10);

-- Suscripciones
INSERT INTO categorization_rules (pattern, match_type, field, category_id, priority) VALUES
('netflix', 'contains', 'description', (SELECT id FROM categories WHERE name = 'Suscripciones' AND user_id IS NULL), 10),
('spotify', 'contains', 'description', (SELECT id FROM categories WHERE name = 'Suscripciones' AND user_id IS NULL), 10),
('hbo', 'contains', 'description', (SELECT id FROM categories WHERE name = 'Suscripciones' AND user_id IS NULL), 10),
('disney', 'contains', 'description', (SELECT id FROM categories WHERE name = 'Suscripciones' AND user_id IS NULL), 10),
('amazon prime', 'contains', 'description', (SELECT id FROM categories WHERE name = 'Suscripciones' AND user_id IS NULL), 10),
('openai', 'contains', 'description', (SELECT id FROM categories WHERE name = 'Suscripciones' AND user_id IS NULL), 10),
('apple.com/bill', 'contains', 'description', (SELECT id FROM categories WHERE name = 'Suscripciones' AND user_id IS NULL), 10),
('google storage', 'contains', 'description', (SELECT id FROM categories WHERE name = 'Suscripciones' AND user_id IS NULL), 10),
('hp instant ink', 'contains', 'description', (SELECT id FROM categories WHERE name = 'Suscripciones' AND user_id IS NULL), 10);

-- Salud
INSERT INTO categorization_rules (pattern, match_type, field, category_id, priority) VALUES
('farmacia', 'contains', 'description', (SELECT id FROM categories WHERE name = 'Farmacia' AND user_id IS NULL), 10);

-- Hogar
INSERT INTO categorization_rules (pattern, match_type, field, category_id, priority) VALUES
('octopus energy', 'contains', 'creditor_name', (SELECT id FROM categories WHERE name = 'Luz' AND user_id IS NULL), 10),
('iberdrola', 'contains', 'creditor_name', (SELECT id FROM categories WHERE name = 'Luz' AND user_id IS NULL), 10),
('endesa', 'contains', 'creditor_name', (SELECT id FROM categories WHERE name = 'Luz' AND user_id IS NULL), 10),
('naturgy', 'contains', 'creditor_name', (SELECT id FROM categories WHERE name = 'Gas' AND user_id IS NULL), 10),
('ptv telecom', 'contains', 'description', (SELECT id FROM categories WHERE name = 'Internet y teléfono' AND user_id IS NULL), 10),
('movistar', 'contains', 'description', (SELECT id FROM categories WHERE name = 'Internet y teléfono' AND user_id IS NULL), 10),
('vodafone', 'contains', 'description', (SELECT id FROM categories WHERE name = 'Internet y teléfono' AND user_id IS NULL), 10),
('orange', 'contains', 'description', (SELECT id FROM categories WHERE name = 'Internet y teléfono' AND user_id IS NULL), 10);

-- Seguros
INSERT INTO categorization_rules (pattern, match_type, field, category_id, priority) VALUES
('mapfre', 'contains', 'creditor_name', (SELECT id FROM categories WHERE name = 'Seguros' AND user_id IS NULL), 10),
('axa', 'contains', 'creditor_name', (SELECT id FROM categories WHERE name = 'Seguros' AND user_id IS NULL), 10),
('allianz', 'contains', 'creditor_name', (SELECT id FROM categories WHERE name = 'Seguros' AND user_id IS NULL), 10),
('generali', 'contains', 'creditor_name', (SELECT id FROM categories WHERE name = 'Seguros' AND user_id IS NULL), 10),
('mutua madrilena', 'contains', 'creditor_name', (SELECT id FROM categories WHERE name = 'Seguros' AND user_id IS NULL), 10),
('zurich', 'contains', 'creditor_name', (SELECT id FROM categories WHERE name = 'Seguros' AND user_id IS NULL), 10),
('santalucia', 'contains', 'creditor_name', (SELECT id FROM categories WHERE name = 'Seguros' AND user_id IS NULL), 10),
('ocaso', 'contains', 'creditor_name', (SELECT id FROM categories WHERE name = 'Seguros' AND user_id IS NULL), 10),
('linea directa', 'contains', 'creditor_name', (SELECT id FROM categories WHERE name = 'Seguros' AND user_id IS NULL), 10);

-- Ropa
INSERT INTO categorization_rules (pattern, match_type, field, category_id, priority) VALUES
('zara', 'contains', 'description', (SELECT id FROM categories WHERE name = 'Ropa y calzado' AND user_id IS NULL), 10),
('mango', 'contains', 'description', (SELECT id FROM categories WHERE name = 'Ropa y calzado' AND user_id IS NULL), 10),
('h&m', 'contains', 'description', (SELECT id FROM categories WHERE name = 'Ropa y calzado' AND user_id IS NULL), 10),
('primark', 'contains', 'description', (SELECT id FROM categories WHERE name = 'Ropa y calzado' AND user_id IS NULL), 10),
('silbon', 'contains', 'description', (SELECT id FROM categories WHERE name = 'Ropa y calzado' AND user_id IS NULL), 10),
('calzedonia', 'contains', 'description', (SELECT id FROM categories WHERE name = 'Ropa y calzado' AND user_id IS NULL), 10),
('women.?s secret', 'regex', 'description', (SELECT id FROM categories WHERE name = 'Ropa y calzado' AND user_id IS NULL), 10);

-- Finanzas
INSERT INTO categorization_rules (pattern, match_type, field, category_id, priority) VALUES
('cetelem', 'contains', 'creditor_name', (SELECT id FROM categories WHERE name = 'Préstamos' AND user_id IS NULL), 10),
('cofidis', 'contains', 'creditor_name', (SELECT id FROM categories WHERE name = 'Préstamos' AND user_id IS NULL), 10),
('caritas', 'contains', 'creditor_name', (SELECT id FROM categories WHERE name = 'Donaciones' AND user_id IS NULL), 10),
('ayuda a la iglesia', 'contains', 'creditor_name', (SELECT id FROM categories WHERE name = 'Donaciones' AND user_id IS NULL), 10),
('tgss', 'contains', 'creditor_name', (SELECT id FROM categories WHERE name = 'Impuestos' AND user_id IS NULL), 10),
('agencia tributaria', 'contains', 'creditor_name', (SELECT id FROM categories WHERE name = 'Impuestos' AND user_id IS NULL), 10);

-- Deportes
INSERT INTO categorization_rules (pattern, match_type, field, category_id, priority) VALUES
('crossfit', 'contains', 'description', (SELECT id FROM categories WHERE name = 'Deportes y gimnasio' AND user_id IS NULL), 10),
('gimnasio', 'contains', 'description', (SELECT id FROM categories WHERE name = 'Deportes y gimnasio' AND user_id IS NULL), 10);

-- Educación / Familia
INSERT INTO categorization_rules (pattern, match_type, field, category_id, priority) VALUES
('colegio', 'contains', 'creditor_name', (SELECT id FROM categories WHERE name = 'Educación' AND user_id IS NULL), 10),
('guarderia', 'contains', 'description', (SELECT id FROM categories WHERE name = 'Guardería' AND user_id IS NULL), 10),
('peques', 'contains', 'description', (SELECT id FROM categories WHERE name = 'Guardería' AND user_id IS NULL), 10);

-- Ahorro e inversiones (no computable)
INSERT INTO categorization_rules (pattern, match_type, field, category_id, priority) VALUES
('myinvestor', 'contains', 'creditor_name', (SELECT id FROM categories WHERE name = 'Ahorro e inversiones' AND user_id IS NULL), 15),
('indexa capital', 'contains', 'creditor_name', (SELECT id FROM categories WHERE name = 'Ahorro e inversiones' AND user_id IS NULL), 15),
('trade republic', 'contains', 'creditor_name', (SELECT id FROM categories WHERE name = 'Ahorro e inversiones' AND user_id IS NULL), 15),
('revolut', 'contains', 'creditor_name', (SELECT id FROM categories WHERE name = 'Ahorro e inversiones' AND user_id IS NULL), 15),
('degiro', 'contains', 'creditor_name', (SELECT id FROM categories WHERE name = 'Ahorro e inversiones' AND user_id IS NULL), 15),
('interactive brokers', 'contains', 'creditor_name', (SELECT id FROM categories WHERE name = 'Ahorro e inversiones' AND user_id IS NULL), 15);

-- Nóminas (fallback si no tiene purpose_code)
INSERT INTO categorization_rules (pattern, match_type, field, category_id, priority) VALUES
('nomina', 'contains', 'description', (SELECT id FROM categories WHERE name = 'Nómina' AND user_id IS NULL), 5),
('pag nominas', 'contains', 'description', (SELECT id FROM categories WHERE name = 'Nómina' AND user_id IS NULL), 5);

-- Supermercados (nuevos)
INSERT INTO categorization_rules (pattern, match_type, field, category_id, priority) VALUES
('coviran', 'contains', 'description', (SELECT id FROM categories WHERE name = 'Supermercado' AND user_id IS NULL), 10),
('mas ahorro', 'contains', 'description', (SELECT id FROM categories WHERE name = 'Supermercado' AND user_id IS NULL), 10);

-- Restaurantes (nuevos)
INSERT INTO categorization_rules (pattern, match_type, field, category_id, priority) VALUES
('piquito de oro', 'contains', 'description', (SELECT id FROM categories WHERE name = 'Restaurantes' AND user_id IS NULL), 10),
('caracoles noreña', 'contains', 'description', (SELECT id FROM categories WHERE name = 'Restaurantes' AND user_id IS NULL), 10),
('medano bar', 'contains', 'description', (SELECT id FROM categories WHERE name = 'Restaurantes' AND user_id IS NULL), 10),
('sana locura', 'contains', 'description', (SELECT id FROM categories WHERE name = 'Restaurantes' AND user_id IS NULL), 10);

-- Cafeterías (nuevas)
INSERT INTO categorization_rules (pattern, match_type, field, category_id, priority) VALUES
('yogurberry', 'contains', 'description', (SELECT id FROM categories WHERE name = 'Cafeterías' AND user_id IS NULL), 10),
('llaollao', 'contains', 'description', (SELECT id FROM categories WHERE name = 'Cafeterías' AND user_id IS NULL), 10),
('heladeria', 'contains', 'description', (SELECT id FROM categories WHERE name = 'Cafeterías' AND user_id IS NULL), 10),
('pasteleria roldan', 'contains', 'description', (SELECT id FROM categories WHERE name = 'Cafeterías' AND user_id IS NULL), 10);

-- Comida a domicilio
INSERT INTO categorization_rules (pattern, match_type, field, category_id, priority) VALUES
('glovo', 'contains', 'description', (SELECT id FROM categories WHERE name = 'Comida a domicilio' AND user_id IS NULL), 10),
('just eat', 'contains', 'description', (SELECT id FROM categories WHERE name = 'Comida a domicilio' AND user_id IS NULL), 10),
('uber eats', 'contains', 'description', (SELECT id FROM categories WHERE name = 'Comida a domicilio' AND user_id IS NULL), 10),
('deliveroo', 'contains', 'description', (SELECT id FROM categories WHERE name = 'Comida a domicilio' AND user_id IS NULL), 10);

-- Gasolina (nueva)
INSERT INTO categorization_rules (pattern, match_type, field, category_id, priority) VALUES
('estacion san rafa', 'contains', 'description', (SELECT id FROM categories WHERE name = 'Gasolina' AND user_id IS NULL), 10);

-- Transporte público (nuevo)
INSERT INTO categorization_rules (pattern, match_type, field, category_id, priority) VALUES
('autotransportes', 'contains', 'description', (SELECT id FROM categories WHERE name = 'Transporte público' AND user_id IS NULL), 10),
('aucorsa', 'contains', 'description', (SELECT id FROM categories WHERE name = 'Transporte público' AND user_id IS NULL), 10);

-- Parking
INSERT INTO categorization_rules (pattern, match_type, field, category_id, priority) VALUES
('cordoba iv-colon', 'contains', 'description', (SELECT id FROM categories WHERE name = 'Parking' AND user_id IS NULL), 10),
('aparcamiento', 'contains', 'description', (SELECT id FROM categories WHERE name = 'Parking' AND user_id IS NULL), 10);

-- Ropa y calzado (nuevos)
INSERT INTO categorization_rules (pattern, match_type, field, category_id, priority) VALUES
('vinted', 'contains', 'description', (SELECT id FROM categories WHERE name = 'Ropa y calzado' AND user_id IS NULL), 10),
('temu', 'contains', 'description', (SELECT id FROM categories WHERE name = 'Ropa y calzado' AND user_id IS NULL), 10);

-- Compras online
INSERT INTO categorization_rules (pattern, match_type, field, category_id, priority) VALUES
('aliexpress', 'contains', 'description', (SELECT id FROM categories WHERE name = 'Electrónica' AND user_id IS NULL), 10);

-- Hogar y decoración
INSERT INTO categorization_rules (pattern, match_type, field, category_id, priority) VALUES
('tiger', 'contains', 'description', (SELECT id FROM categories WHERE name = 'Hogar y decoración' AND user_id IS NULL), 10);

-- Mantenimiento hogar (nuevo)
INSERT INTO categorization_rules (pattern, match_type, field, category_id, priority) VALUES
('leroy merlin', 'contains', 'description', (SELECT id FROM categories WHERE name = 'Mantenimiento hogar' AND user_id IS NULL), 10);

-- Dentista
INSERT INTO categorization_rules (pattern, match_type, field, category_id, priority) VALUES
('dentista', 'contains', 'description', (SELECT id FROM categories WHERE name = 'Dentista' AND user_id IS NULL), 10);

-- Suscripciones tech
INSERT INTO categorization_rules (pattern, match_type, field, category_id, priority) VALUES
('cloudflare', 'contains', 'description', (SELECT id FROM categories WHERE name = 'Suscripciones' AND user_id IS NULL), 10),
('anthropic', 'contains', 'description', (SELECT id FROM categories WHERE name = 'Suscripciones' AND user_id IS NULL), 10),
('google*workspace', 'contains', 'description', (SELECT id FROM categories WHERE name = 'Suscripciones' AND user_id IS NULL), 10),
('vercel', 'contains', 'description', (SELECT id FROM categories WHERE name = 'Suscripciones' AND user_id IS NULL), 10);

-- Ahorro e inversiones (nuevo)
INSERT INTO categorization_rules (pattern, match_type, field, category_id, priority) VALUES
('inversis', 'contains', 'description', (SELECT id FROM categories WHERE name = 'Ahorro e inversiones' AND user_id IS NULL), 15);

-- Comisiones bancarias
INSERT INTO categorization_rules (pattern, match_type, field, category_id, priority) VALUES
('pago transferencias', 'contains', 'description', (SELECT id FROM categories WHERE name = 'Comisiones bancarias' AND user_id IS NULL), 10);

-- Transferencia entre cuentas (nuevo)
INSERT INTO categorization_rules (pattern, match_type, field, category_id, priority) VALUES
('propio', 'contains', 'description', (SELECT id FROM categories WHERE name = 'Transferencia entre cuentas' AND user_id IS NULL), 5);

-- Donaciones (nuevas)
INSERT INTO categorization_rules (pattern, match_type, field, category_id, priority) VALUES
('hermandad santo sepulcro', 'contains', 'creditor_name', (SELECT id FROM categories WHERE name = 'Donaciones' AND user_id IS NULL), 10),
('amigos de las ermitas', 'contains', 'creditor_name', (SELECT id FROM categories WHERE name = 'Donaciones' AND user_id IS NULL), 10);
