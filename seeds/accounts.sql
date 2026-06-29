-- Cuentas bancarias iniciales
-- Se puede ejecutar múltiples veces (upsert por gocardless_account_id)

INSERT INTO accounts (user_id, gocardless_account_id, is_active) VALUES
('8c4651f1-b8d7-4ef7-81dd-50ba90c01946', '9647669f-1289-4d2b-a81b-9230f10b9e38', TRUE),
('8c4651f1-b8d7-4ef7-81dd-50ba90c01946', 'a6f17a57-4b49-42db-8e2a-f6d7e80a4b28', TRUE),
('8c4651f1-b8d7-4ef7-81dd-50ba90c01946', 'ec1a334d-a788-4f12-9f7c-53eb7fa4a715', TRUE)
ON CONFLICT (gocardless_account_id) DO UPDATE SET
    user_id = EXCLUDED.user_id,
    is_active = EXCLUDED.is_active,
    updated_at = NOW();
