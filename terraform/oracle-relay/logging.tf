# The relay VM's logs, kept in OCI Logging rather than only on the VM. The
# Oracle Cloud Agent on the VM tails the files rsyslog writes and sends them
# to relay-vm; the dynamic group (all instances in the minecraft-relay
# compartment, made in the console) is what lets the VM write there.

variable "relay_instances_dynamic_group" {
  description = "OCID of the minecraft-relay-instances dynamic group."
  type        = string
  default     = "ocid1.dynamicgroup.oc1..aaaaaaaabjqefnryjv5ih5rtntuwvoqnuu53jtstaznawyxlfqylatovu4oq"
}

resource "oci_logging_log_group" "relay" {
  compartment_id = var.compartment_ocid
  display_name   = "minecraft-relay"
  description    = "Logs from the Minecraft relay VM"

  lifecycle {
    prevent_destroy = true
  }
}

resource "oci_logging_log" "relay_vm" {
  display_name       = "relay-vm"
  log_group_id       = oci_logging_log_group.relay.id
  log_type           = "CUSTOM"
  is_enabled         = true
  retention_duration = 90

  lifecycle {
    prevent_destroy = true
  }
}

resource "oci_logging_unified_agent_configuration" "relay_vm" {
  compartment_id = var.compartment_ocid
  display_name   = "minecraft-relay-vm"
  description    = "Ships the relay VM's syslog files to relay-vm"
  is_enabled     = true

  group_association {
    group_list = [var.relay_instances_dynamic_group]
  }

  service_configuration {
    configuration_type = "LOGGING"

    destination {
      log_object_id = oci_logging_log.relay_vm.id
    }

    sources {
      source_type = "LOG_TAIL"
      name        = "relay_syslog"
      paths = [
        "/var/log/auth.log",
        "/var/log/syslog",
        "/var/log/kern.log",
        "/var/log/haproxy.log",
      ]
      parser {
        parser_type = "NONE"
      }
    }
  }
}
