#!/usr/bin/env bash

# Generate the SPIFFE IDs for the workloads:
# - spire-agent
# - Envoy proxy
# - certificate generator
#
# Usage: 1-issue-spire-entries.sh

set -euo pipefail

_cluster_name=${cluster_name:-"spire-envoy-k8s"}

echo "Creating SPIRE agent entry"
kubectl exec -n spire spire-server-0 -- \
    /opt/spire/bin/spire-server entry create \
    -spiffeID spiffe://example.com/ns/spire/sa/spire-agent \
    -selector "k8s_sat:cluster:$_cluster_name" \
    -selector k8s_sat:agent_ns:spire \
    -selector k8s_sat:agent_sa:spire-agent \
    -node

echo "Creating proxy entry"
kubectl exec -n spire spire-server-0 -- \
    /opt/spire/bin/spire-server entry create \
    -spiffeID spiffe://example.com/ns/proxy/sa/default \
    -parentID spiffe://example.com/ns/spire/sa/spire-agent \
    -selector k8s:ns:proxy \
    -selector k8s:sa:default \
    -dns example.com

echo "Creating backend entry"
kubectl exec -n spire spire-server-0 -- \
    /opt/spire/bin/spire-server entry create \
    -spiffeID spiffe://example.com/ns/backend/sa/default \
    -parentID spiffe://example.com/ns/spire/sa/spire-agent \
    -selector k8s:ns:backend \
    -selector k8s:sa:default

echo "Creating generator entry"
kubectl exec -n spire spire-server-0 -- \
    /opt/spire/bin/spire-server entry create \
    -spiffeID spiffe://example.com/ns/cert-gen/sa/generator \
    -parentID spiffe://example.com/ns/spire/sa/spire-agent \
    -selector k8s:ns:cert-gen \
    -selector k8s:sa:generator
