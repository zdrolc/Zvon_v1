import os
import re
import time
import traceback
from datetime import date, datetime, timedelta

import httpx
import jwt
from supabase import create_client

from telegram import notify_etl_error, notify_reauth_required

# HTTP Client with a longer timeout for banking APIs
HTTP_CLIENT = httpx.Client(timeout=120.0)

ENABLE_BANKING_API_URL = "https://api.enablebanking.com"
SYNC_OVERLAP_DAYS = 7

# =============================================================================
# AUTHENTICATION & SETUP
# =============================================================================

def get_supabase_client():
    """Creates a Supabase client using the service key (bypasses RLS)."""
    url = os.environ["SUPABASE_URL"]
    key = os.environ["SUPABASE_SERVICE_KEY"]
    return create_client(url, key)

def generate_eb_token() -> str:
    """
    Generates a JWT for Enable Banking API authentication.
    Requires EB_APP_ID and EB_PRIVATE_KEY environment variables.
    """
    app_id = os.environ["EB_APP_ID"]
    private_key = os.environ["EB_PRIVATE_KEY"]
    
    # Enable Banking JWT standard payload
    iat = int(time.time())
    payload = {
        "iss": app_id,
        "aud": "api.enablebanking.com",
        "iat": iat,
        "exp": iat + 3600 # Token valid for 1 hour
    }
    
    # The private key should be in standard PEM format
    token = jwt.encode(payload, private_key, algorithm="RS256")
    return token

def get_active_accounts(client) -> list:
    """Fetches all active accounts from Supabase."""
    result = client.table("accounts").select("*").eq("is_active", True).execute()
    return result.data

# =============================================================================
# DATA FETCHING (ENABLE BANKING API)
# =============================================================================

def fetch_transactions(token: str, external_account_id: str, date_from: str | None) -> list:
    """Fetches transactions from Enable Banking, handling continuation keys."""
    all_transactions = []
    
    params = {}
    if date_from:
        from_date = date.fromisoformat(date_from) - timedelta(days=SYNC_OVERLAP_DAYS)
        params["date_from"] = from_date.isoformat()

    url = f"{ENABLE_BANKING_API_URL}/accounts/{external_account_id}/transactions"
    headers = {"Authorization": f"Bearer {token}"}

    continuation_key = None
    
    while True:
        if continuation_key:
            params["continuation_key"] = continuation_key

        last_exc = None
        for attempt in range(3):
            if attempt > 0:
                time.sleep(2 ** (attempt - 1))  # Exponential backoff
            try:
                response = HTTP_CLIENT.get(url, headers=headers, params=params)
                response.raise_for_status()
                data = response.json()
                
                all_transactions.extend(data.get("transactions", []))
                continuation_key = data.get("continuation_key")
                break # Break out of retry loop on success
                
            except httpx.TimeoutException as e:
                last_exc = e
                print(f"  Timeout fetching transactions (attempt {attempt + 1}/3)")
            except httpx.HTTPStatusError as e:
                # 401 or 403 usually means the session expired or user consent was revoked
                if e.response.status_code in [401, 403]:
                    raise e
                last_exc = e
                
        else:
            # If the loop finishes without breaking, all 3 attempts failed
            raise last_exc

        if not continuation_key:
            break

    return all_transactions

def fetch_balances(token: str, external_account_id: str) -> list:
    """Fetches account balances from Enable Banking."""
    url = f"{ENABLE_BANKING_API_URL}/accounts/{external_account_id}/balances"
    headers = {"Authorization": f"Bearer {token}"}

    last_exc = None
    for attempt in range(3):
        if attempt > 0:
            time.sleep(2 ** (attempt - 1))
        try:
            response = HTTP_CLIENT.get(url, headers=headers)
            response.raise_for_status()
            return response.json().get("balances", [])
        except httpx.HTTPStatusError as e:
            print(f"  Error fetching balances: {e.response.status_code}")
            return []
        except httpx.TimeoutException as e:
            last_exc = e
            print(f"  Timeout fetching balances (attempt {attempt + 1}/3)")

    print(f"  Failed to fetch balance after 3 attempts: {last_exc}")
    return []

# =============================================================================
# DATA NORMALIZATION & DB LOADING
# =============================================================================

def normalize_transactions(transactions: list) -> list:
    """Normalizes Enable Banking transaction data into our transactions_raw schema."""
    normalized = []
    for tx in transactions:
        # Extract nested structures safely
        tx_amount = tx.get("transaction_amount", {})
        creditor_acc = tx.get("creditor_account", {})
        debtor_acc = tx.get("debtor_account", {})
        
        normalized.append({
            "external_transaction_id": tx.get("transaction_id"),
            "booking_date": tx.get("booking_date") or tx.get("value_date"), # Fallback to value_date if missing
            "value_date": tx.get("value_date"),
            "amount": float(tx_amount.get("amount", 0)),
            "currency": tx_amount.get("currency", "EUR"),
            "creditor_name": tx.get("creditor_name"),
            "creditor_account": creditor_acc.get("iban") or creditor_acc.get("bban"),
            "debtor_name": tx.get("debtor_name"),
            "debtor_account": debtor_acc.get("iban") or debtor_acc.get("bban"),
            "remittance_information": tx.get("remittance_information_unstructured") or tx.get("remittance_information_structured", ""),
            "status": tx.get("status", "BOOKED"),
            "raw_data": tx,
        })
    return [tx for tx in normalized if tx["external_transaction_id"] is not None]

def load_to_database(client, transactions: list, account_id: str) -> tuple[list, int]:
    """
    Inserts normalized transactions into `transactions_raw`.
    Returns (upserted transactions, number of truly new transactions).
    """
    if not transactions:
        return [], 0

    tx_ids = [tx["external_transaction_id"] for tx in transactions]
    existing_ids = set()
    batch_size = 200
    
    # Check which ones already exist to calculate 'new' counts
    for i in range(0, len(tx_ids), batch_size):
        batch = tx_ids[i:i + batch_size]
        existing = client.table("transactions_raw").select("external_transaction_id").eq(
            "account_id", account_id
        ).in_("external_transaction_id", batch).execute()
        existing_ids.update(row["external_transaction_id"] for row in existing.data)

    rows = [
        {
            "account_id": account_id,
            "external_transaction_id": tx["external_transaction_id"],
            "booking_date": tx["booking_date"],
            "value_date": tx["value_date"],
            "amount": tx["amount"],
            "currency": tx["currency"],
            "creditor_name": tx["creditor_name"],
            "creditor_account": tx["creditor_account"],
            "debtor_name": tx["debtor_name"],
            "debtor_account": tx["debtor_account"],
            "remittance_information": tx["remittance_information"],
            "status": tx["status"],
            "raw_data": tx["raw_data"],
        }
        for tx in transactions
    ]

    # Minimal returning prevents Supabase from choking on huge raw_data arrays
    client.table("transactions_raw").upsert(
        rows,
        on_conflict="account_id,external_transaction_id",
        returning="minimal",
    ).execute()

    # Re-fetch the saved transactions without the heavy raw_data column
    non_raw_columns = (
        "id, account_id, external_transaction_id, booking_date, value_date, "
        "amount, currency, creditor_name, creditor_account, debtor_name, "
        "debtor_account, remittance_information, status"
    )
    upserted = []
    for i in range(0, len(tx_ids), batch_size):
        batch = tx_ids[i:i + batch_size]
        resp = client.table("transactions_raw").select(non_raw_columns).eq(
            "account_id", account_id
        ).in_("external_transaction_id", batch).execute()
        upserted.extend(resp.data)

    new_count = len(upserted) - len(existing_ids)
    return upserted, new_count

# =============================================================================
# CATEGORIZATION & BUSINESS LOGIC
# =============================================================================

def get_categorization_rules(client, user_id: str | None) -> list:
    """Fetches categorization rules. Allows global (user_id is null) and user-specific rules."""
    query = client.table("categorization_rules").select("*")
    if user_id:
        query = query.or_(f"user_id.is.null,user_id.eq.{user_id}")
    else:
        query = query.is_("user_id", "null")

    result = query.execute()
    return result.data

def auto_categorize(client, transactions: list, user_id: str, account_id: str) -> dict:
    """
    Auto-categorizes transactions and populates the `transactions_user` table.
    Matches the `search_term` from rules against remittance_info and creditor_name.
    """
    if not transactions:
        return {"total": 0, "categorized": 0, "percentage": 0}

    rules = get_categorization_rules(client, user_id)
    to_categorize = []

    for tx in transactions:
        assigned_category_id = None
        
        searchable_text = f"{tx.get('remittance_information', '')} {tx.get('creditor_name', '')}".lower()
        
        # Simple sub-string matching based on the new categorization_rules schema
        for rule in rules:
            term = rule.get("search_term", "").lower()
            if term and term in searchable_text:
                assigned_category_id = rule["category_id"]
                break

        # Create or update the mutable user layer
        # NOTE: If the user already manually categorized this, we should be careful not to overwrite
        # the category_id. The upsert logic here assumes we set auto_category = True if a rule matches.
        user_layer_entry = {
            "user_id": user_id,
            "raw_transaction_id": tx["id"],
            "account_id": account_id,
        }
        
        if assigned_category_id:
            user_layer_entry["category_id"] = assigned_category_id
            user_layer_entry["auto_category"] = True
            
        to_categorize.append(user_layer_entry)

    # Upsert all entries into transactions_user
    if to_categorize:
        # NOTE: in production, you might want an RPC or a safe upsert that ignores category_id 
        # if the user has manually changed it (i.e. is_reviewed = True).
        client.table("transactions_user").upsert(
            to_categorize,
            on_conflict="raw_transaction_id",
        ).execute()

    total = len(transactions)
    # Count how many successfully got an assigned category via rules
    categorized = sum(1 for tx in to_categorize if "category_id" in tx)

    return {
        "total": total,
        "categorized": categorized,
        "percentage": round(categorized / total * 100, 1) if total > 0 else 0,
    }

def update_account_balance(client, account_id: str, balances: list):
    """Parses Enable Banking balances and updates the accounts table."""
    if not balances:
        return

    update_data = {"updated_at": datetime.now().isoformat()}

    for bal in balances:
        balance_type = bal.get("balance_type", "")
        amount_obj = bal.get("balance_amount", {})

        # We prefer closingBooked or expected balance
        if balance_type in ("expected", "closingBooked", "interimBooked"):
            update_data["balance"] = float(amount_obj.get("amount", 0))
            update_data["currency"] = amount_obj.get("currency", "EUR")
            break

    # Fallback to the first available balance if no specific type matched
    if "balance" not in update_data and balances:
        first = balances[0].get("balance_amount", {})
        update_data["balance"] = float(first.get("amount", 0))
        update_data["currency"] = first.get("currency", "EUR")

    client.table("accounts").update(update_data).eq("id", account_id).execute()

# =============================================================================
# MAIN ORCHESTRATION
# =============================================================================

def sync_account(client, token: str, account: dict) -> tuple[int, str | None]:
    """Syncs a single bank account. Returns (transactions_added, date_from)."""
    account_id = account["id"]
    user_id = account["user_id"]
    external_account_id = account["external_account_id"]
    account_name = account.get("account_name") or account.get("bank_name") or external_account_id
    
    last_sync = account.get("updated_at")

    if last_sync:
        last_sync_date = last_sync[:10] if isinstance(last_sync, str) else last_sync.date().isoformat()
        print(f"[{account_name}] Incremental sync starting from {last_sync_date}")
    else:
        last_sync_date = None
        print(f"[{account_name}] Initial full sync")

    try:
        raw = fetch_transactions(token, external_account_id, last_sync_date)
    except httpx.HTTPStatusError as e:
        if e.response.status_code in [401, 403]:
            print(f"[{account_name}] Access expired or revoked (401/403)")
            return None, last_sync_date
        raise
        
    print(f"[{account_name}] Downloaded {len(raw)} transactions from API")

    transactions_added = 0
    if raw:
        normalized = normalize_transactions(raw)
        upserted, new_count = load_to_database(client, normalized, account_id)
        transactions_added = new_count
        print(f"[{account_name}] Saved {len(upserted)} to database ({new_count} brand new)")

        stats = auto_categorize(client, upserted, user_id, account_id)
        print(f"[{account_name}] Auto-categorized: {stats['categorized']}/{stats['total']} ({stats['percentage']}%)")

    balances = fetch_balances(token, external_account_id)
    if balances:
        update_account_balance(client, account_id, balances)
        print(f"[{account_name}] Balance updated successfully.")
    else:
        print(f"[{account_name}] Could not retrieve balance.")

    return transactions_added, last_sync_date


def bank_transactions_etl():
    """Main ETL Flow for syncing bank transactions (Entrypoint for Prefect)."""
    print("Starting Enable Banking transactions ETL...")

    try:
        client = get_supabase_client()
        accounts = get_active_accounts(client)

        if not accounts:
            print("No active accounts found to sync.")
            return

        print(f"Syncing {len(accounts)} account(s)...")

        # Generate JWT for Enable Banking
        token = generate_eb_token()

        total_transactions = 0
        expired_accounts = []
        
        for account in accounts:
            added, date_from = sync_account(client, token, account)
            
            if added is None:
                expired_accounts.append(account)
                continue
                
            total_transactions += added

        if expired_accounts:
            # Send notification for expired connections
            for acc in expired_accounts:
                acc_name = acc.get("account_name") or acc.get("bank_name") or "Unknown Account"
                msg = (
                    f"<b>🔑 Re-authentication Required</b>\n\n"
                    f"🏦 Account: {acc_name}\n\n"
                    f"Your bank connection has expired. Please open the Fintop app to re-authorize."
                )
                notify_reauth_required(acc_name, msg)

        print(f"ETL completed successfully. Total new transactions added: {total_transactions}")

    except Exception as e:
        error_msg = f"{type(e).__name__}: {e}\n{traceback.format_exc()}"
        print(f"ETL Error: {error_msg}")
        notify_etl_error(error_msg)
        raise

if __name__ == "__main__":
    bank_transactions_etl()
