variable "gcp_project" {
  description = "GCP Project ID"
  type        = string
}

variable "gcp_region" {
  description = "GCP Region"
  type        = string
  default     = "europe-west1"
}

# Supabase
variable "supabase_url" {
  description = "Supabase project URL"
  type        = string
  sensitive   = true
}

variable "supabase_service_key" {
  description = "Supabase service role key (bypasses RLS)"
  type        = string
  sensitive   = true
}

# Enable Banking
variable "eb_app_id" {
  description = "Enable Banking Application ID"
  type        = string
  sensitive   = true
}

variable "eb_private_key" {
  description = "Enable Banking RSA Private Key"
  type        = string
  sensitive   = true
}

# GitHub
variable "github_repo" {
  description = "GitHub repository (owner/repo)"
  type        = string
  default     = "pabloreina97/fintop-prefect"
}

# Telegram
variable "telegram_bot_token" {
  description = "Telegram bot token for notifications"
  type        = string
  sensitive   = true
  default     = ""
}

variable "telegram_chat_id" {
  description = "Telegram chat ID for notifications"
  type        = string
  sensitive   = true
  default     = ""
}
