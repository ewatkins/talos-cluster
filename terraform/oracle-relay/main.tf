# The network the Minecraft relay VM (minecraft-relay) sits in, in the
# minecraft-relay compartment: one VCN with
# one public subnet, an internet gateway, and the VCN's default route table,
# security list and DHCP options. It was built by hand in the console on
# 2026-10-17 and adopted here (imports.tf). The VM and its reserved public IP
# are not managed here; see kubernetes/apps/network/playit/README.md.

resource "oci_core_vcn" "relay" {
  compartment_id = var.compartment_ocid
  display_name   = "relay-vcn"
  cidr_blocks    = ["10.0.0.0/16"]
  dns_label      = "relay"
}

resource "oci_core_internet_gateway" "relay" {
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_vcn.relay.id
  display_name   = "relay-igw"
  enabled        = true
}

# Default resources are adopted, not imported: tofu takes them over by ID and
# makes them match what is declared here.
resource "oci_core_default_route_table" "relay" {
  manage_default_resource_id = oci_core_vcn.relay.default_route_table_id
  display_name               = "Default Route Table for relay-vcn"

  route_rules {
    destination       = "0.0.0.0/0"
    destination_type  = "CIDR_BLOCK"
    network_entity_id = oci_core_internet_gateway.relay.id
  }
}

# The relay's firewall. The VM's own iptables (cloud-init) opens the same two
# game ports; both must allow a port for it to work.
resource "oci_core_default_security_list" "relay" {
  manage_default_resource_id = oci_core_vcn.relay.default_security_list_id
  display_name               = "Default Security List for relay-vcn"

  egress_security_rules {
    destination      = "0.0.0.0/0"
    destination_type = "CIDR_BLOCK"
    protocol         = "all"
    stateless        = false
  }

  ingress_security_rules {
    description = "SSH from home"
    source      = var.ssh_source_cidr
    source_type = "CIDR_BLOCK"
    protocol    = "6"
    stateless   = false
    tcp_options {
      min = 22
      max = 22
    }
  }

  # Extra SSH sources (work, ...), managed in Bitwarden without a Git change.
  dynamic "ingress_security_rules" {
    for_each = toset(compact([for c in split(",", var.ssh_extra_cidrs) : trimspace(c)]))
    content {
      description = "SSH"
      source      = ingress_security_rules.value
      source_type = "CIDR_BLOCK"
      protocol    = "6"
      stateless   = false
      tcp_options {
        min = 22
        max = 22
      }
    }
  }

  ingress_security_rules {
    description = "Minecraft Bedrock relay"
    source      = "0.0.0.0/0"
    source_type = "CIDR_BLOCK"
    protocol    = "17"
    stateless   = false
    udp_options {
      min = 19132
      max = 19132
    }
  }

  ingress_security_rules {
    description = "Minecraft Java Relay"
    source      = "0.0.0.0/0"
    source_type = "CIDR_BLOCK"
    protocol    = "6"
    stateless   = false
    tcp_options {
      min = 25565
      max = 25565
    }
  }

  # Path MTU discovery: "fragmentation needed" from anywhere.
  ingress_security_rules {
    source      = "0.0.0.0/0"
    source_type = "CIDR_BLOCK"
    protocol    = "1"
    stateless   = false
    icmp_options {
      type = 3
      code = 4
    }
  }
}

resource "oci_core_subnet" "relay" {
  compartment_id             = var.compartment_ocid
  vcn_id                     = oci_core_vcn.relay.id
  display_name               = "relay-subnet"
  cidr_block                 = "10.0.0.0/24"
  dns_label                  = "pub"
  route_table_id             = oci_core_default_route_table.relay.id
  security_list_ids          = [oci_core_default_security_list.relay.id]
  dhcp_options_id            = oci_core_vcn.relay.default_dhcp_options_id
  prohibit_public_ip_on_vnic = false
  prohibit_internet_ingress  = false
}
