#!/usr/bin/env bash

# Generate and fetch certificates from the cert generator and store them
# locally.
#
# NOTE: you wouldn't really do this "in production", but for the purposes of
# demonstration, we fetch generate the cert within the confines of the cluster
# and copy it locally.
#
# Usage: 2-generate-certs.sh

set -euo pipefail

echo "Selecting a pod ..."
_pod=$(kubectl -n cert-gen get pods \
  -l app=generator -o jsonpath='{.items[*].metadata.name}' \
  | awk '{print $1}')

echo "Generating certificate ..."
kubectl -n cert-gen exec -it "$_pod" -- \
  ./bin/spire-agent api fetch x509 \
    -socketPath /run/spire/sockets/agent.sock \
    -write /tmp/certs

echo "Fetching certificate ..."
rm -rf ./certs && mkdir ./certs
kubectl cp "cert-gen/${_pod}:/tmp/certs/" ./certs
