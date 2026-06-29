"""
Notificaciones de Telegram para los flujos ETL.
"""

import os
from datetime import datetime

import httpx

TELEGRAM_API_URL = "https://api.telegram.org/bot{token}/sendMessage"


def send_telegram_message(message: str, parse_mode: str = "HTML") -> bool:
    """
    Envía un mensaje a Telegram.

    Requiere variables de entorno:
    - TELEGRAM_BOT_TOKEN: Token del bot
    - TELEGRAM_CHAT_ID: ID del chat destino

    Returns True si el mensaje se envió correctamente.
    """
    token = os.environ.get("TELEGRAM_BOT_TOKEN")
    chat_id = os.environ.get("TELEGRAM_CHAT_ID")

    if not token or not chat_id:
        print("Telegram no configurado (faltan TELEGRAM_BOT_TOKEN o TELEGRAM_CHAT_ID)")
        return False

    try:
        response = httpx.post(
            TELEGRAM_API_URL.format(token=token),
            json={
                "chat_id": chat_id,
                "text": message,
                "parse_mode": parse_mode,
            },
            timeout=10.0,
        )
        response.raise_for_status()
        return True
    except Exception as e:
        print(f"Error enviando mensaje de Telegram: {e}")
        return False


def notify_reauth_required(account_name: str, link: str):
    """Notifica que una cuenta necesita re-autorización bancaria."""
    message = (
        f"<b>🔑 Re-autorización necesaria</b>\n\n"
        f"🏦 Cuenta: {account_name}\n\n"
        f"El acceso ha expirado. Autoriza de nuevo:\n\n"
        f"{link}"
    )
    send_telegram_message(message)


def notify_etl_error(error: str):
    """Notifica que el ETL falló."""
    timestamp = datetime.now().strftime("%d/%m/%Y %H:%M")

    # Truncar error si es muy largo
    if len(error) > 500:
        error = error[:500] + "..."

    message = (
        f"<b>❌ ETL Fallido</b>\n\n"
        f"📅 {timestamp}\n"
        f"<pre>{error}</pre>"
    )

    send_telegram_message(message)