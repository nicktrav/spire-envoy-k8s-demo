#!/usr/bin/env bash

# Delete the SPIFFE IDs for all workloads.
#
# Usage: 4-delete-certs.sh

set -euo pipefail

# Fetch all SPIFFE entries.
function fetch_entries() {
  kubectl exec -n spire spire-server-0 -- \
    /opt/spire/bin/spire-server entry show
}

# Delete the given SPIFFE entry.
function delete_entry() {
  kubectl exec -n spire spire-server-0 -- \
    /opt/spire/bin/spire-server entry delete \
    -entryID "$1"
}

echo "Fetching existing SPIRE entries"
_entries=$(fetch_entries | grep 'Entry ID' | perl -n -e'/^Entry ID.*:\s([a-z0-9-]*?)$/ && print "$1\n"')
echo "$_entries"

for _entry in $_entries; do
  echo "Deleting $_entry"
  delete_entry "$_entry"
done

echo "Done!"
