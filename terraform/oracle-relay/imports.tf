# The console-built resources this stack adopted. No-ops once they are in
# state; kept as the record of what was adopted. The default route table and
# security list need no import (manage_default_resource_id in main.tf).
import {
  to = oci_core_vcn.relay
  id = "ocid1.vcn.oc1.us-chicago-1.amaaaaaazjfsi5aatot2i4vwczpiilt6g7rhufwduvmzddevyi4kx7pkrsra"
}

import {
  to = oci_core_internet_gateway.relay
  id = "ocid1.internetgateway.oc1.us-chicago-1.aaaaaaaa5hlqyh5zqcqyshwrwwev3vxp4xv7dy6yallzj32kehyyvjkrztaq"
}

import {
  to = oci_core_subnet.relay
  id = "ocid1.subnet.oc1.us-chicago-1.aaaaaaaawrch3tasud77qoiweiyukyieqmngefmqc6dss6fumq6sn4xpuaia"
}
