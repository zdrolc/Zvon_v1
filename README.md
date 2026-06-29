# Fintop Prefect

ETL de finanzas personales que sincroniza transacciones bancarias desde GoCardless (open banking) hacia Supabase.

## Arquitectura

```
GoCardless API ─────> Prefect Flows ─────> Supabase
   (bancos)            (ETL)              (PostgreSQL)
```

## Flujos

### `bank_transactions_etl`
Sincroniza transacciones de todas las cuentas activas:
- Descarga movimientos desde GoCardless
- Normaliza y guarda en `transactions_raw`
- Aplica categorización automática basada en reglas
- Se ejecuta diariamente a las 6:00 AM

### `accounts_sync`
Sincroniza detalles de cuentas (IBAN, nombre del banco) desde GoCardless.

## Esquema de base de datos

| Tabla | Descripción |
|-------|-------------|
| `accounts` | Cuentas bancarias vinculadas |
| `transactions_raw` | Datos inmutables del banco |
| `transactions_user` | Categorización (automática y manual) |
| `transaction_splits` | División manual de transacciones |
| `categories` | Categorías (globales + usuario) |
| `categorization_rules` | Reglas de auto-categorización |
| `transactions` | Vista unificada con categoría efectiva |

## Configuración

### Secrets en Prefect

```bash
prefect block register -m prefect.blocks.system

# GoCardless
prefect secret create gc-secret-id
prefect secret create gc-secret-key

# Supabase
prefect secret create supabase-url
prefect secret create supabase-service-key
```

### Despliegue

```bash
# Crear deployments
prefect deploy --all

# O ejecutar manualmente
python flows/bank_transactions_etl.py
python flows/accounts_sync.py
```

## Estructura

```
.
├── flows/
│   ├── accounts_sync.py          # Sync detalles de cuentas
│   └── bank_transactions_etl.py  # ETL principal
├── seeds/
│   ├── accounts.sql              # Datos de prueba
│   ├── categories.sql            # Categorías globales
│   └── categorization_rules.sql  # Reglas de ejemplo
├── supabase/
│   └── migrations/               # Migraciones incrementales
├── schema.sql                    # Schema completo
└── prefect.yaml                  # Configuración de deployments
```

## Categorización automática

El sistema categoriza transacciones en este orden:
1. **Purpose code**: Códigos estándar bancarios (SALA = Nómina, GOVT = Ayudas)
2. **Reglas**: Patrones configurables por usuario (contains, starts_with, exact, regex)

La categoría manual (`category_id`) siempre tiene prioridad sobre la automática (`auto_category_id`).

## Licencia

MIT
