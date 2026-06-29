import os
import re
import time
import traceback
from datetime import date, datetime, timedelta

import httpx
from supabase import create_client

from telegram import notify_etl_error, notify_reauth_required

# Cliente HTTP con timeout más largo
HTTP_CLIENT = httpx.Client(timeout=120.0)

GOCARDLESS_BASE_URL = "https://bankaccountdata.gocardless.com/api/v2"
SYNC_OVERLAP_DAYS = 7

# Mapeo purpose_code → nombre de categoría
PURPOSE_CODE_MAP = {
    "SALA": "Nómina",
    "GOVT": "Ayudas y subvenciones",
}


def get_supabase_client():
    """Crea cliente de Supabase con service key (bypasses RLS)."""
    url = os.environ["SUPABASE_URL"]
    key = os.environ["SUPABASE_SERVICE_KEY"]
    return create_client(url, key)


def get_access_token() -> str:
    """Obtiene token de acceso de GoCardless."""
    secret_id = os.environ["GC_SECRET_ID"]
    secret_key = os.environ["GC_SECRET_KEY"]

    response = HTTP_CLIENT.post(
        f"{GOCARDLESS_BASE_URL}/token/new/",
        json={"secret_id": secret_id, "secret_key": secret_key},
    )
    response.raise_for_status()
    return response.json()["access"]


def get_account_metadata(token: str, gocardless_account_id: str) -> dict:
    """Obtiene metadata de la cuenta desde GoCardless (institution_id, status, etc.)."""
    response = HTTP_CLIENT.get(
        f"{GOCARDLESS_BASE_URL}/accounts/{gocardless_account_id}/",
        headers={"Authorization": f"Bearer {token}"},
    )
    response.raise_for_status()
    return response.json()


def create_end_user_agreement(token: str, institution_id: str) -> str:
    """Crea un End User Agreement en GoCardless. Retorna el agreement_id."""
    response = HTTP_CLIENT.post(
        f"{GOCARDLESS_BASE_URL}/agreements/enduser/",
        headers={"Authorization": f"Bearer {token}"},
        json={
            "max_historical_days": 90,
            "access_valid_for_days": 90,
            "institution_id": institution_id,
        },
    )
    response.raise_for_status()
    return response.json()["id"]


def create_requisition(token: str, institution_id: str, agreement_id: str, gc_account_id: str) -> dict:
    """Crea una Requisition en GoCardless. Retorna los datos incluyendo el link."""
    redirect = os.environ.get("GC_REDIRECT_URL", "https://example.com/callback")
    reference = f"fintop-{datetime.now().strftime('%Y%m%d%H%M%S')}-{gc_account_id[:8]}"

    response = HTTP_CLIENT.post(
        f"{GOCARDLESS_BASE_URL}/requisitions/",
        headers={"Authorization": f"Bearer {token}"},
        json={
            "redirect": redirect,
            "institution_id": institution_id,
            "agreement": agreement_id,
            "reference": reference,
        },
    )
    response.raise_for_status()
    return response.json()


def handle_expired_agreements(token: str, expired_accounts: list):
    """
    Maneja cuentas con acuerdo expirado, agrupando por institution_id
    para crear un solo agreement + requisition por banco.
    """
    # Agrupar cuentas por institution_id
    by_institution: dict[str, list[str]] = {}
    for account in expired_accounts:
        gc_account_id = account["gocardless_account_id"]
        account_name = account.get("account_name") or account.get("bank_name") or gc_account_id
        metadata = get_account_metadata(token, gc_account_id)
        institution_id = metadata["institution_id"]
        if institution_id not in by_institution:
            by_institution[institution_id] = []
        by_institution[institution_id].append(account_name)

    for institution_id, account_names in by_institution.items():
        print(f"[{institution_id}] Re-autorizando para: {', '.join(account_names)}")

        agreement_id = create_end_user_agreement(token, institution_id)
        print(f"[{institution_id}] Agreement creado: {agreement_id}")

        gc_id = expired_accounts[0]["gocardless_account_id"]
        requisition = create_requisition(token, institution_id, agreement_id, gc_id)
        link = requisition["link"]
        print(f"[{institution_id}] Requisition creada: {requisition['id']}")
        print(f"[{institution_id}] Link: {link}")

        names = ", ".join(account_names)
        notify_reauth_required(names, link)


def get_active_accounts(client) -> list:
    """Obtiene todas las cuentas activas de Supabase."""
    result = client.table("accounts").select("*").eq("is_active", True).execute()
    return result.data


def fetch_transactions(token: str, gocardless_account_id: str, date_from: str | None) -> list:
    """Descarga transacciones de la cuenta bancaria."""
    params = {}
    if date_from:
        from_date = date.fromisoformat(date_from) - timedelta(days=SYNC_OVERLAP_DAYS)
        params["date_from"] = from_date.isoformat()

    url = f"{GOCARDLESS_BASE_URL}/accounts/{gocardless_account_id}/transactions/"
    headers = {"Authorization": f"Bearer {token}"}

    last_exc = None
    for attempt in range(3):
        if attempt > 0:
            time.sleep(2 ** (attempt - 1))  # backoff: 1s, 2s
        try:
            response = HTTP_CLIENT.get(url, headers=headers, params=params)
            response.raise_for_status()
            return response.json()["transactions"]["booked"]
        except httpx.TimeoutException as e:
            last_exc = e
            print(f"  Timeout descargando transacciones (intento {attempt + 1}/3)")

    raise last_exc


def normalize_transactions(transactions: list) -> list:
    """Normaliza transacciones al esquema interno."""
    normalized = []
    for tx in transactions:
        description_array = tx.get("remittanceInformationUnstructuredArray", [])
        description = " | ".join(description_array) if description_array else tx.get(
            "remittanceInformationUnstructured", "")

        normalized.append({
            "transaction_id": tx.get("transactionId") or tx.get("internalTransactionId"),
            "internal_transaction_id": tx.get("internalTransactionId"),
            "entry_reference": tx.get("entryReference"),
            "end_to_end_id": tx.get("endToEndId"),
            "mandate_id": tx.get("mandateId"),
            "creditor_id": tx.get("creditorId"),
            "booking_date": tx.get("bookingDate"),
            "value_date": tx.get("valueDate"),
            "amount": float(tx["transactionAmount"]["amount"]),
            "currency": tx["transactionAmount"]["currency"],
            "description": description,
            "creditor_name": tx.get("creditorName"),
            "debtor_name": tx.get("debtorName"),
            "ultimate_debtor": tx.get("ultimateDebtor"),
            "bank_transaction_code": tx.get("bankTransactionCode"),
            "proprietary_code": tx.get("proprietaryBankTransactionCode"),
            "purpose_code": tx.get("purposeCode"),
            "raw_data": tx,
        })
    return normalized


def load_to_database(client, transactions: list, account_id: str) -> tuple[list, int]:
    """
    Inserta transacciones en transactions_raw.
    Retorna (transacciones insertadas/actualizadas, número de transacciones realmente nuevas).
    """
    if not transactions:
        return [], 0

    # Consultar qué transaction_ids ya existen para descontar el overlap
    tx_ids = [tx["transaction_id"] for tx in transactions]
    existing_ids = set()
    batch_size = 200
    for i in range(0, len(tx_ids), batch_size):
        batch = tx_ids[i:i + batch_size]
        existing = client.table("transactions_raw").select("transaction_id").eq(
            "account_id", account_id
        ).in_("transaction_id", batch).execute()
        existing_ids.update(row["transaction_id"] for row in existing.data)

    rows = [
        {
            "account_id": account_id,
            "transaction_id": tx["transaction_id"],
            "internal_transaction_id": tx["internal_transaction_id"],
            "entry_reference": tx["entry_reference"],
            "end_to_end_id": tx["end_to_end_id"],
            "mandate_id": tx["mandate_id"],
            "creditor_id": tx["creditor_id"],
            "booking_date": tx["booking_date"],
            "value_date": tx["value_date"],
            "amount": tx["amount"],
            "currency": tx["currency"],
            "description": tx["description"],
            "creditor_name": tx["creditor_name"],
            "debtor_name": tx["debtor_name"],
            "ultimate_debtor": tx["ultimate_debtor"],
            "bank_transaction_code": tx["bank_transaction_code"],
            "proprietary_code": tx["proprietary_code"],
            "purpose_code": tx["purpose_code"],
            "raw_data": tx["raw_data"],
        }
        for tx in transactions
    ]

    # Usar returning=minimal para evitar que PostgREST falle con raw_data grande
    client.table("transactions_raw").upsert(
        rows,
        on_conflict="account_id,transaction_id",
        returning="minimal",
    ).execute()

    # Consultar las transacciones upsertadas sin raw_data
    non_raw_columns = (
        "id, account_id, transaction_id, booking_date, value_date, "
        "amount, currency, description, creditor_name, debtor_name, "
        "ultimate_debtor, bank_transaction_code, proprietary_code, purpose_code"
    )
    upserted = []
    for i in range(0, len(tx_ids), batch_size):
        batch = tx_ids[i:i + batch_size]
        resp = client.table("transactions_raw").select(non_raw_columns).eq(
            "account_id", account_id
        ).in_("transaction_id", batch).execute()
        upserted.extend(resp.data)

    new_count = len(upserted) - len(existing_ids)
    return upserted, new_count


def get_categorization_rules(client, user_id: str | None) -> list:
    """Obtiene reglas de categorización (globales + usuario)."""
    query = client.table("categorization_rules").select(
        "*, categories(id, name)"
    ).eq("is_active", True).order("priority", desc=True)

    # Globales + del usuario
    if user_id:
        query = query.or_(f"user_id.is.null,user_id.eq.{user_id}")
    else:
        query = query.is_("user_id", "null")

    result = query.execute()
    return result.data


def get_categories_by_name(client) -> dict:
    """Obtiene mapeo nombre → id de categorías globales."""
    result = client.table("categories").select("id, name").is_("user_id", "null").execute()
    return {cat["name"]: cat["id"] for cat in result.data}


def match_text(rule: dict, transaction: dict) -> bool | None:
    """
    Comprueba si una transacción coincide con el patrón de texto de una regla.
    Retorna None si no hay patrón definido.
    """
    pattern = rule.get("pattern")
    if not pattern:
        return None

    field = rule["field"]
    match_type = rule["match_type"]
    pattern = pattern.lower()

    value = transaction.get(field) or ""
    value = value.lower()

    if match_type == "contains":
        return pattern in value
    elif match_type == "starts_with":
        return value.startswith(pattern)
    elif match_type == "exact":
        return value == pattern
    elif match_type == "regex":
        try:
            return bool(re.search(pattern, value, re.IGNORECASE))
        except re.error:
            return False
    return False


def match_amount(rule: dict, transaction: dict) -> bool | None:
    """
    Comprueba si el importe de una transacción cumple la condición de la regla.
    Retorna None si no hay condición de importe definida.
    """
    operator = rule.get("amount_operator")
    if not operator:
        return None

    amount_value = rule.get("amount_value")
    if amount_value is None:
        return None

    tx_amount = transaction.get("amount")
    if tx_amount is None:
        return False

    tx_amount = float(tx_amount)
    amount_value = float(amount_value)

    if operator == "gt":
        return tx_amount > amount_value
    elif operator == "lt":
        return tx_amount < amount_value
    elif operator == "gte":
        return tx_amount >= amount_value
    elif operator == "lte":
        return tx_amount <= amount_value
    elif operator == "eq":
        return tx_amount == amount_value
    elif operator == "between":
        amount_max = rule.get("amount_value_max")
        if amount_max is None:
            return False
        return amount_value <= tx_amount <= float(amount_max)

    return False


def match_rule(rule: dict, transaction: dict) -> bool:
    """
    Comprueba si una transacción coincide con una regla.
    Si hay patrón de texto Y condición de importe, ambos deben cumplirse (AND).
    """
    text_match = match_text(rule, transaction)
    amount_match = match_amount(rule, transaction)

    if text_match is not None and amount_match is not None:
        return text_match and amount_match

    if text_match is not None:
        return text_match

    if amount_match is not None:
        return amount_match

    return False


def auto_categorize(client, transactions: list, user_id: str | None, categories_map: dict) -> dict:
    """
    Categoriza automáticamente las transacciones.
    Siempre actualiza auto_category_id, respetando category_id (override manual).
    """
    if not transactions:
        return {"total": 0, "categorized": 0, "percentage": 0}

    rules = get_categorization_rules(client, user_id)
    to_categorize = []

    for tx in transactions:
        category_id = None

        # 1. Intentar con purpose_code
        purpose = tx.get("purpose_code")
        if purpose and purpose in PURPOSE_CODE_MAP:
            category_name = PURPOSE_CODE_MAP[purpose]
            category_id = categories_map.get(category_name)

        # 2. Si no, buscar por reglas
        if not category_id:
            for rule in rules:
                if match_rule(rule, tx):
                    category_id = rule["category_id"]
                    break

        if category_id:
            to_categorize.append({
                "transaction_raw_id": tx["id"],
                "auto_category_id": category_id,
            })

    if to_categorize:
        client.table("transactions_user").upsert(
            to_categorize,
            on_conflict="transaction_raw_id",
        ).execute()

    total = len(transactions)
    categorized = len(to_categorize)

    return {
        "total": total,
        "categorized": categorized,
        "percentage": round(categorized / total * 100, 1) if total > 0 else 0,
    }


def fetch_balances(token: str, gocardless_account_id: str) -> list:
    """Obtiene los saldos de la cuenta desde GoCardless."""
    url = f"{GOCARDLESS_BASE_URL}/accounts/{gocardless_account_id}/balances/"
    headers = {"Authorization": f"Bearer {token}"}

    last_exc = None
    for attempt in range(3):
        if attempt > 0:
            time.sleep(2 ** (attempt - 1))  # backoff: 1s, 2s
        try:
            response = HTTP_CLIENT.get(url, headers=headers, timeout=20.0)
            response.raise_for_status()
            return response.json().get("balances", [])
        except httpx.HTTPStatusError as e:
            print(f"  Error obteniendo saldos: {e.response.status_code}")
            return []
        except httpx.TimeoutException as e:
            last_exc = e
            print(f"  Timeout obteniendo saldos (intento {attempt + 1}/3)")

    print(f"  No se pudo obtener el saldo tras 3 intentos: {last_exc}")
    return []


def update_account_balance(client, account_id: str, balances: list):
    """Actualiza el saldo de la cuenta en Supabase."""
    if not balances:
        return

    update_data = {"balance_updated_at": datetime.now().isoformat()}

    for bal in balances:
        balance_type = bal.get("balanceType", "")
        amount = bal.get("balanceAmount", {})

        if balance_type in ("closingBooked", "interimBooked"):
            update_data["balance"] = float(amount.get("amount", 0))
            update_data["balance_currency"] = amount.get("currency", "EUR")
        elif balance_type in ("interimAvailable", "closingAvailable"):
            update_data["balance_available"] = float(amount.get("amount", 0))
            update_data["balance_currency"] = amount.get("currency", "EUR")

    # Si no encontró tipos específicos, usar el primer saldo disponible
    if "balance" not in update_data and balances:
        first = balances[0].get("balanceAmount", {})
        update_data["balance"] = float(first.get("amount", 0))
        update_data["balance_currency"] = first.get("currency", "EUR")

    client.table("accounts").update(update_data).eq("id", account_id).execute()


def update_account_last_sync(client, account_id: str):
    """Actualiza la fecha de última sincronización de la cuenta."""
    client.table("accounts").update({
        "last_sync_at": datetime.now().isoformat()
    }).eq("id", account_id).execute()


def detect_internal_transfers(client, user_id: str, categories_map: dict) -> dict:
    """
    Detecta transferencias internas emparejando transacciones opuestas.
    Busca pares de transacciones donde:
    - Mismo usuario, diferentes cuentas
    - Mismo importe pero signo opuesto
    - Misma fecha (booking_date)
    - Sin categoría asignada aún
    Solo analiza transacciones de los últimos 30 días para evitar queries excesivas.
    """
    transfer_category_id = categories_map.get("Transferencia entre cuentas")
    if not transfer_category_id:
        return {"detected": 0}

    accounts_result = client.table("accounts").select("id").eq("user_id", user_id).execute()
    account_ids = [a["id"] for a in accounts_result.data]

    if len(account_ids) < 2:
        return {"detected": 0}

    # Solo buscar en transacciones recientes (últimos 30 días)
    cutoff_date = (date.today() - timedelta(days=30)).isoformat()

    # Obtener transacciones recientes del usuario
    transactions_result = client.table("transactions_raw").select(
        "id, account_id, booking_date, amount"
    ).in_("account_id", account_ids).gte("booking_date", cutoff_date).execute()

    # Obtener categorías existentes en lotes para evitar URLs demasiado largas
    tx_ids = [t["id"] for t in transactions_result.data]
    if not tx_ids:
        return {"detected": 0}

    user_data_rows = []
    batch_size = 200
    for i in range(0, len(tx_ids), batch_size):
        batch = tx_ids[i:i + batch_size]
        result = client.table("transactions_user").select(
            "transaction_raw_id, auto_category_id, category_id"
        ).in_("transaction_raw_id", batch).execute()
        user_data_rows.extend(result.data)
    user_data_result_data = user_data_rows

    categorized = {
        row["transaction_raw_id"]: row
        for row in user_data_result_data
    }

    # Indexar transacciones por (fecha, monto) para búsqueda eficiente
    # Convertir amount a float para comparaciones consistentes
    by_date_amount = {}
    for tx in transactions_result.data:
        amount = float(tx["amount"])
        key = (tx["booking_date"], amount)
        if key not in by_date_amount:
            by_date_amount[key] = []
        by_date_amount[key].append({**tx, "amount": amount})

    # Buscar pares opuestos
    to_update = []
    processed_ids = set()

    for tx in transactions_result.data:
        if tx["id"] in processed_ids:
            continue

        amount = float(tx["amount"])
        # Buscar transacción opuesta (mismo día, monto negado, diferente cuenta)
        opposite_key = (tx["booking_date"], -amount)
        candidates = by_date_amount.get(opposite_key, [])

        for candidate in candidates:
            if candidate["account_id"] == tx["account_id"]:
                continue
            if candidate["id"] in processed_ids:
                continue

            # Verificar que al menos una no tenga categoría
            tx_cat = categorized.get(tx["id"])
            cand_cat = categorized.get(candidate["id"])

            tx_has_category = tx_cat and (tx_cat.get("category_id") or tx_cat.get("auto_category_id"))
            cand_has_category = cand_cat and (cand_cat.get("category_id") or cand_cat.get("auto_category_id"))

            # Categorizar ambas como transferencia interna
            if not tx_has_category:
                to_update.append({
                    "transaction_raw_id": tx["id"],
                    "auto_category_id": transfer_category_id,
                })
            if not cand_has_category:
                to_update.append({
                    "transaction_raw_id": candidate["id"],
                    "auto_category_id": transfer_category_id,
                })

            processed_ids.add(tx["id"])
            processed_ids.add(candidate["id"])
            break

    if to_update:
        client.table("transactions_user").upsert(
            to_update,
            on_conflict="transaction_raw_id",
        ).execute()

    return {"detected": len(to_update)}


def sync_account(client, token: str, account: dict, categories_map: dict) -> tuple[int, str | None]:
    """Sincroniza una cuenta bancaria individual. Retorna (transacciones añadidas, date_from)."""
    account_id = account["id"]
    user_id = account["user_id"]
    gc_account_id = account["gocardless_account_id"]
    account_name = account.get("account_name") or account.get("bank_name") or gc_account_id
    last_sync = account.get("last_sync_at")

    if last_sync:
        last_sync_date = last_sync[:10] if isinstance(last_sync, str) else last_sync.date().isoformat()
        print(f"[{account_name}] Sincronización incremental desde {last_sync_date}")
    else:
        last_sync_date = None
        print(f"[{account_name}] Primera sincronización (completa)")

    try:
        raw = fetch_transactions(token, gc_account_id, last_sync_date)
    except httpx.HTTPStatusError as e:
        if e.response.status_code == 401:
            print(f"[{account_name}] Acceso expirado (401)")
            return None, last_sync_date
        raise
    print(f"[{account_name}] Descargadas {len(raw)} transacciones")

    transactions_added = 0
    if raw:
        normalized = normalize_transactions(raw)
        upserted, new_count = load_to_database(client, normalized, account_id)
        transactions_added = new_count
        print(f"[{account_name}] Guardadas {len(upserted)} transacciones ({new_count} nuevas)")

        stats = auto_categorize(client, upserted, user_id, categories_map)
        print(f"[{account_name}] Auto-categorizadas: {stats['categorized']}/{stats['total']} ({stats['percentage']}%)")

    # Actualizar saldo desde GoCardless
    balances = fetch_balances(token, gc_account_id)
    if balances:
        update_account_balance(client, account_id, balances)
        bal_info = next(
            (b for b in balances if b.get("balanceType") in ("closingBooked", "interimBooked")),
            balances[0],
        )
        amount = bal_info.get("balanceAmount", {})
        print(f"[{account_name}] Saldo: {amount.get('amount')} {amount.get('currency', 'EUR')}")
    else:
        print(f"[{account_name}] No se pudo obtener el saldo")

    update_account_last_sync(client, account_id)
    return transactions_added, last_sync_date


def main():
    """ETL de movimientos bancarios para todas las cuentas activas."""
    print("Iniciando ETL de transacciones bancarias...")

    try:
        client = get_supabase_client()
        accounts = get_active_accounts(client)

        if not accounts:
            print("No hay cuentas activas para sincronizar")
            return

        print(f"Sincronizando {len(accounts)} cuenta(s)")

        token = get_access_token()
        categories_map = get_categories_by_name(client)

        total_transactions = 0
        earliest_date = None
        expired_accounts = []
        for account in accounts:
            added, date_from = sync_account(client, token, account, categories_map)
            if added is None:
                expired_accounts.append(account)
                continue
            total_transactions += added
            if date_from and (earliest_date is None or date_from < earliest_date):
                earliest_date = date_from

        if expired_accounts:
            handle_expired_agreements(token, expired_accounts)

        synced_accounts = [a for a in accounts if a not in expired_accounts]

        if synced_accounts:
            # Detectar transferencias internas por usuario
            user_ids = set(a["user_id"] for a in synced_accounts)
            print(f"Detectando transferencias internas para {len(user_ids)} usuario(s)...")

            total_detected = 0
            for user_id in user_ids:
                stats = detect_internal_transfers(client, user_id, categories_map)
                total_detected += stats["detected"]

            if total_detected > 0:
                print(f"Transferencias internas detectadas: {total_detected}")

            print("ETL completado")
        else:
            print("ETL completado (todas las cuentas requieren re-autorización)")

    except Exception as e:
        error_msg = f"{type(e).__name__}: {e}\n{traceback.format_exc()}"
        print(f"Error en ETL: {error_msg}")
        notify_etl_error(error_msg)
        raise


if __name__ == "__main__":
    main()
