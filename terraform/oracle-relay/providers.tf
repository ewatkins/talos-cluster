# Credentials come from the oracle-relay-secret Secret, which the runner pod
# gets as environment variables. The provider reads TF_VAR_tenancy_ocid,
# TF_VAR_user_ocid, TF_VAR_fingerprint, TF_VAR_private_key and TF_VAR_region
# itself; tenancy_ocid is also a variable below, as the compartment.
provider "oci" {}
