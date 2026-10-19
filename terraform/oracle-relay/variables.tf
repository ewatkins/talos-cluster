# All of these come from oracle-relay-secret, so neither the tenancy, the API
# key nor the home IP is in this public repo.
variable "tenancy_ocid" {
  description = "Tenancy OCID; everything lives in the root compartment."
  type        = string
}

variable "user_ocid" {
  description = "API user the key belongs to."
  type        = string
}

variable "fingerprint" {
  description = "Fingerprint of the API key."
  type        = string
}

variable "private_key" {
  description = "PEM private key of the API key."
  type        = string
  sensitive   = true
}

variable "region" {
  description = "OCI region (us-chicago-1)."
  type        = string
}

variable "ssh_source_cidr" {
  description = "The only source allowed to SSH to the relay VM (home, /32)."
  type        = string
  sensitive   = true
}

variable "ssh_extra_cidrs" {
  description = "More sources allowed to SSH to the relay VM (e.g. work), comma-separated CIDRs; may be empty."
  type        = string
  sensitive   = true
  default     = ""
}
