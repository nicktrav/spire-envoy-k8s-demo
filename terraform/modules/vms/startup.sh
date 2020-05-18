#!/usr/bin/env bash

set -exuo pipefail

# There is some flakiness when the VM first wakes up that can prevent it from completing network
# calls. This fails the fetching of the SPIRE binaries, and borks the VM, requring manual
# intervention. Instead, just wait a monemnt before issueing the first call.
sleep 30

curl -s -N -L https://github.com/spiffe/spire/releases/download/v0.10.0/spire-0.10.0-linux-x86_64-glibc.tar.gz \
  | tar -xz --strip-components=3 -C /usr/local/bin/ ./spire-0.10.0/bin/spire-agent

mkdir -p /etc/spire /run/spire/sockets
cat <<-HERE > /etc/spire/agent.config
agent {
  data_dir = "/run/spire"
  log_level = "DEBUG"
  server_address = "spire-server.example.com"
  server_port = "8081"
  socket_path = "/run/spire/sockets/agent.sock"
  trust_domain = "example.com"

  # This is obviously insecure! Ideally, we'd leverage web PKI here and call a TLS protected
  # endpoint responsible for serving up the bootstrp bundle. For the purposes of demonstration, we
  # do an insecure bootstrap. DON'T DO THIS IN PROUDCTION!
  insecure_bootstrap = true
}
plugins {
  NodeAttestor "gcp_iit" {
    plugin_data {
    }
  }
  KeyManager "disk" {
    plugin_data {
      directory = "/run/spire/keys"
    }
  }
  WorkloadAttestor "unix" {
    plugin_data {
    }
  }
}
HERE

cat <<-HERE > /etc/systemd/system/spire-agent.service
[Unit]
Description=Spire Agent
Requires=network-online.target
After=network-online.target

[Service]
Type=simple
User=root
ExecStart=/usr/local/bin/spire-agent run -config /etc/spire/agent.config
ExecReload=/bin/kill -HUP \$MAINPID
ExecStop=/bin/kill -TERM \$MAINPID
Restart=always
RestartSec=1

[Install]
WantedBy=multi-user.target
HERE

systemctl enable spire-agent.service
systemctl daemon-reload
systemctl restart spire-agent.service