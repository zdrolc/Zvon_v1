# Arquitectura de transacciones

## Resumen

El sistema separa los datos bancarios inmutables de la categorización del usuario, permitiendo:

1. **Categorización automática** por la ETL usando reglas
2. **Override manual** por el usuario
3. **División de transacciones** (splits) para casos especiales

## Diagrama de tablas

```
┌─────────────────────┐
│      accounts       │
│─────────────────────│
│ id                  │
│ user_id ────────────┼──► auth.users
│ gocardless_id       │
│ bank_name           │
└─────────┬───────────┘
          │
          │ 1:N
          ▼
┌─────────────────────┐
│  transactions_raw   │  ◄── ETL escribe aquí (inmutable)
│─────────────────────│
│ id                  │
│ account_id          │
│ amount              │
│ description         │
│ booking_date        │
│ raw_data (JSONB)    │
└─────────┬───────────┘
          │
          │ 1:1
          ▼
┌─────────────────────┐
│  transactions_user  │  ◄── ETL + Usuario
│─────────────────────│
│ transaction_raw_id  │
│ auto_category_id ───┼──► ETL escribe aquí
│ category_id ────────┼──► Usuario sobrescribe aquí
│ notes               │
└─────────┬───────────┘
          │
          │ 1:N (opcional)
          ▼
┌─────────────────────┐
│ transaction_splits  │  ◄── Usuario (división manual)
│─────────────────────│
│ transaction_raw_id  │
│ amount              │
│ category_id         │
│ notes               │
└─────────────────────┘
```

## Flujo de datos

### 1. ETL sincroniza transacciones

```
GoCardless API
     │
     ▼
transactions_raw (INSERT/UPDATE datos del banco)
     │
     ▼
transactions_user (UPSERT auto_category_id según reglas)
```

La ETL:
1. Inserta/actualiza datos crudos en `transactions_raw`
2. Aplica reglas de `categorization_rules`
3. Escribe la categoría en `transactions_user.auto_category_id`

### 2. Usuario categoriza manualmente

```
Frontend
     │
     ▼
transactions_user.category_id = nueva_categoria
```

El campo `category_id` tiene prioridad sobre `auto_category_id`.

### 3. Usuario divide una transacción

```
Frontend
     │
     ▼
transaction_splits (INSERT múltiples filas)
```

Ejemplo: Compra en hipermercado de 100€
- Split 1: 30€ → Supermercado
- Split 2: 70€ → Ropa

## Vista `transactions`

La vista unifica todo con esta lógica:

| Situación | Categoría mostrada | Importe |
|-----------|-------------------|---------|
| Sin splits, sin override | `auto_category_id` | `raw.amount` |
| Sin splits, con override | `category_id` | `raw.amount` |
| Con splits | `split.category_id` | `split.amount` |

### Campos de la vista

| Campo | Descripción |
|-------|-------------|
| `id` | ID de la transacción raw |
| `source_id` | ID de la transacción original (= id) |
| `split_id` | ID del split (NULL si no es split) |
| `is_split` | TRUE si es una fila de split |
| `amount` | Importe (de raw o de split) |
| `category_id` | Categoría efectiva |
| `computable` | Si cuenta para totales (viene de categories) |

## Reglas de negocio

### Categorización

```
categoria_efectiva = COALESCE(
    transactions_user.category_id,      -- Override manual
    transactions_user.auto_category_id  -- Automático ETL
)
```

### Splits

- Si existen splits para una transacción, se ignora `transactions_user.category_id`
- Cada split tiene su propia categoría
- La suma de splits debería igualar `transactions_raw.amount` (no validado en BD)

### Computable

El campo `categories.computable` indica si la categoría cuenta para totales y gráficos:
- `TRUE` (default): Cuenta normalmente
- `FALSE`: No se incluye en totales (ej: "Me lo devuelven en efectivo")

## Ejemplos de uso

### Consultar transacciones del mes

```sql
SELECT * FROM transactions
WHERE booking_date >= '2024-12-01'
  AND booking_date < '2025-01-01'
ORDER BY booking_date DESC;
```

### Totales por categoría (solo computables)

```sql
SELECT
    category_name,
    SUM(amount) as total
FROM transactions
WHERE computable = TRUE
  AND booking_date >= '2024-12-01'
GROUP BY category_name
ORDER BY total;
```

### Ver transacciones sin categorizar

```sql
SELECT * FROM transactions
WHERE category_id IS NULL;
```

### Crear un split

```sql
-- Primero insertar los splits
INSERT INTO transaction_splits (transaction_raw_id, amount, category_id, notes)
VALUES
    ('uuid-transaccion', -30.00, 'uuid-supermercado', NULL),
    ('uuid-transaccion', -70.00, 'uuid-ropa', NULL);

-- La vista automáticamente mostrará los splits en lugar de la transacción original
```

## Seguridad (RLS)

Todas las tablas tienen Row Level Security habilitado:

- **accounts**: Usuario solo ve sus cuentas
- **transactions_raw**: Usuario solo ve transacciones de sus cuentas
- **transactions_user**: Usuario solo ve/edita las de sus transacciones
- **transaction_splits**: Usuario solo ve/edita los de sus transacciones
- **categories**: Usuario ve globales (`user_id IS NULL`) + propias
- **categorization_rules**: Usuario ve globales + propias

## Migraciones

Las migraciones están en `supabase/migrations/`:

1. `20241215000001_add_auto_category_to_transactions_user.sql` - Añade `auto_category_id`
2. `20241215000002_create_transaction_splits.sql` - Crea tabla de splits
3. `20241215000003_update_transactions_view.sql` - Actualiza la vista

Para aplicar:
```bash
supabase db push
```
