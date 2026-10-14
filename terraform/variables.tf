variable "alert_email" {
  description = "Email address for Azure Monitor alerts. Leave empty to skip creating alerts."
  type        = string
  default     = ""
}
