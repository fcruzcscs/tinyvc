# nomad.hcl

datacenter = "vc-tiny"

data_dir  = "/opt/nomad/data"
bind_addr = "0.0.0.0"

server {
  enabled          = true
  bootstrap_expect = 1
}

# Enable the client
client {
  enabled = true
  cpu_total_compute = 1000
}

acl {
  enabled = true
}

# Plugin configuration for the raw_exec driver
plugin "raw_exec" {
  config {
    enabled = true
  }
}

# setting to match prod deployments
tls {
  http = true
  rpc  = true
  verify_https_client = false

  ca_file   = "/etc/nomad.d/certs/nomad-ca.pem"
  cert_file = "/etc/nomad.d/certs/nomad-server.pem"
  key_file  = "/etc/nomad.d/certs/nomad-server.key"
}
