#!/usr/bin/env bash

# Issue requests against the proxy over an mTLS secured channel, which will be
# proxied to the backend. The response seen by the backend will be echoed in
# the response body.
#
# Usage: 3-curl.sh [HTTP_METHOD]

set -euo pipefail

set +u
_method=${1:-GET}
set -u

if [[ "$_method" == 'HEAD' ]]; then
  _method_string='-I'
else
  _method_string="-X$_method"
fi

echo "Fetching external IP address ..."
_ip=$(kubectl -n proxy get svc proxy \
  -o jsonpath='{.status.loadBalancer.ingress[0].ip}')

echo "Issuing curl ..."
curl --resolve "example.com:443:$_ip" \
  "$_method_string" \
  --cert ./certs/svid.0.pem \
  --key ./certs/svid.0.key \
  --cacert ./certs/bundle.0.pem \
  https://example.com/tada
