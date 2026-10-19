# Both come from oracle-relay-secret, so neither the tenancy nor the home IP is
# in this public repo.
variable "tenancy_ocid" {
  description = "Tenancy OCID; everything lives in the root compartment."
  type        = string
}

variable "ssh_source_cidr" {
  description = "The only source allowed to SSH to the relay VM (home, /32)."
  type        = string
}
