"""
Sincronización de detalles de cuentas bancarias desde GoCardless.
Actualiza bank_name, iban y otros detalles de las cuentas existentes.
"""

import os

import httpx
from supabase import create_client

GOCARDLESS_BASE_URL = "https://bankaccountdata.gocardless.com/api/v2"
HTTP_CLIENT = httpx.Client(timeout=60.0)


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


def get_accounts_to_sync(client) -> list:
    """Obtiene cuentas activas que necesitan sincronizar detalles."""
    result = client.table("accounts").select("*").eq("is_active", True).execute()
    return result.data


def fetch_account_details(token: str, gocardless_account_id: str) -> dict | None:
    """Obtiene detalles de una cuenta desde GoCardless."""
    try:
        response = HTTP_CLIENT.get(
            f"{GOCARDLESS_BASE_URL}/accounts/{gocardless_account_id}/details/",
            headers={"Authorization": f"Bearer {token}"},
        )
        response.raise_for_status()
        return response.json().get("account", {})
    except httpx.HTTPStatusError as e:
        if e.response.status_code == 404:
            return None
        raise


def update_account_details(client, account_id: str, details: dict):
    """Actualiza los detalles de la cuenta en Supabase."""
    update_data = {}

    if details.get("iban"):
        update_data["iban"] = details["iban"]

    if details.get("name"):
        update_data["bank_name"] = details["name"]

    if update_data:
        client.table("accounts").update(update_data).eq("id", account_id).execute()

    return update_data


def sync_account_details(client, token: str, account: dict):
    """Sincroniza los detalles de una cuenta individual."""
    account_id = account["id"]
    gc_account_id = account["gocardless_account_id"]
    current_name = account.get("account_name") or account.get("bank_name") or gc_account_id

    print(f"[{current_name}] Obteniendo detalles...")

    details = fetch_account_details(token, gc_account_id)

    if details is None:
        print(f"[{current_name}] Cuenta no encontrada en GoCardless (404)")
        return

    updated = update_account_details(client, account_id, details)

    if updated:
        print(f"[{current_name}] Actualizado: {updated}")
    else:
        print(f"[{current_name}] Sin cambios")


def main():
    """Sincroniza detalles de todas las cuentas activas desde GoCardless."""
    print("Iniciando sincronización de cuentas...")

    client = get_supabase_client()
    accounts = get_accounts_to_sync(client)

    if not accounts:
        print("No hay cuentas activas para sincronizar")
        return

    print(f"Sincronizando detalles de {len(accounts)} cuenta(s)")

    token = get_access_token()

    for account in accounts:
        sync_account_details(client, token, account)

    print("Sincronización de cuentas completada")


if __name__ == "__main__":
    main()
