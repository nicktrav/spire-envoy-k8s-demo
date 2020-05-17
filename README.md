SPIRE / Envoy / K8s
===================

Example of running SPIRE with Envoy as a front proxy in K8s.

Envoy is configured as an mTLS proxy handling the transport between the "local"
K8s cluster and a client running as a "remote" workload.
