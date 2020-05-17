#!/usr/bin/env bash

# Issue requests against the proxy over an mTLS secured channel, which will be
# proxied to the backend. The response seen by the backend will be echoed in
# the response body.
#
# Usage: 3-curl.sh

set -euo pipefail

echo "Fetching external IP address ..."
_ip=$(kubectl -n proxy get svc proxy \
  -o jsonpath='{.status.loadBalancer.ingress[0].ip}')

echo "Issuing curl ..."
curl --resolve "example.com:443:$_ip" \
  --cert ./certs/svid.0.pem \
  --key ./certs/svid.0.key \
  --cacert ./certs/bundle.0.pem \
  https://example.com/tada
