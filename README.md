SPIRE / Envoy / K8s
===================

Example of running [SPIRE](ihttps://spiffe.io/spire/) with
[Envoy](https://www.envoyproxy.io/) as a front proxy in a
[Kubernetes](https://kubernetes.io/) cluster.

Envoy is configured as a proxy handling the transport between the K8s cluster
and a client running locally. Envoy is also configured to use mTLS to mutually
authenticate both the client and server.

For the most part, the SPIRE config has been shamelessly cribbed from the
[official tutorial](https://github.com/spiffe/spire-tutorials). The demo fills
in some gaps on configuring Envoy to consume the SPIFFE / SPIRE identities, as
well as performing an end-to-end test.

⚠️ **NOTE**: this is a very much a demo, and the configuration contained herein
is by no means indicative of a hardened production setup. Buyer beware. Best to
[RTFM](https://spiffe.io/spire/docs/).

## Architecture

The demo runs in a GKE cluster. Preemptible VMs are used to save some $$$. The
topology is defined under `terraform/`.

The K8s cluster has the following components, each running in their own
namespace:

- `spire`: the SPIRE server `StatefulSet` and agent `Daemonset`, along with
  the `ServiceAccount`s and K8s RBAC, configured with the K8s attestors

- `proxy`: Envoy configured as a front-proxy / reverse-proxy `Deployment`,
  performing the mTLS handshake with any clients outside the cluster. The proxy
  uses the SDS API exposed by the SPIRE agent exposed on a local Unix Domain
  Socket to fetch the x509 certificates and bundles it requires.

- `backend`: a simple backend `Deployment` that the proxy will call within the
  cluster. The backend will echo the request is received in the response body
  it returns to the caller

- `generator`: a `Depoloyment` containing the binaries and UDS mount that can
  be used to generate certificates with a SPIFFE ID different to that of the
  proxy. NOTE: this workload is purely for demonstration purposes, and you
  wouldn't run something like this in production.

## Setup

Infrastructure provisioning is managed with
[Terraform](https://www.terraform.io/).

You'll first need to configure `terraform/backend.tf` with the appropriate
storage and / or authentication mechanism. The simplest version stores the
Terraform state file locally. Update the name of your project in this file.

Provision the infrastructure:

```bash
$ cd terraform
$ terraform init
$ terraform apply
...
Do you want to perform these actions?
  Terraform will perform the actions described above.
  Only 'yes' will be accepted to approve.

  Enter a value: yes
```

Terraform will provision the infrastructure. This takes ~5 mins.

[Helm](https://helm.sh/) is used to managed the K8s YAML. This demo uses
version 2, which requires a small component to run in the cluster, with
permission to perform the necessary cluster operations.

```bash
$ ./helm/install_tiller.sh
```

Install the Helm chart for the demo:

```bash
$ helm upgrade spire-envoy-k8s helm/spire-envoy-k8s \
  --namespace spire \
  --install
```

Wait for all components to start. You can monitor them with:

```bash
$ watch kubectl -n spire get pods
$ watch kubectl -n proxy get pods
$ watch kubectl -n backend get pods
$ watch kubectl -n cert-gen get pods
```

## Running the demo

Generate the SPIFFE entries for the workloads:

```bash
$ ./scripts/1-issue-spire-entries.sh
Creating SPIRE agent entry
Entry ID      : 5ff19def-7959-4e39-b949-94645924081f
SPIFFE ID     : spiffe://example.com/ns/spire/sa/spire-agent
Parent ID     : spiffe://example.com/spire/server
...

Creating proxy entry
Entry ID      : 98d7e0b3-e9b4-47f8-aa36-39ca5b33d049
SPIFFE ID     : spiffe://example.com/ns/proxy/sa/default
Parent ID     : spiffe://example.com/ns/spire/sa/spire-agent
...

Creating generator entry
Entry ID      : 1d5d4ea7-d455-419b-9f70-23b17c4be39a
SPIFFE ID     : spiffe://example.com/ns/cert-gen/sa/generator
Parent ID     : spiffe://example.com/ns/spire/sa/spire-agent
...
```

Generate a client certificate to use locally (i.e. on your device) to
communicate with the proxy:

```bash
$ ./scripts/2-generate-certs.sh
Selecting a pod ...
Generating certificate ...
Received 1 svid after 13.219597ms

SPIFFE ID:              spiffe://example.com/ns/cert-gen/sa/generator
SVID Valid After:       2020-05-17 16:25:34 +0000 UTC
SVID Valid Until:       2020-05-17 17:25:44 +0000 UTC
CA #1 Valid After:      2020-05-16 23:45:25 +0000 UTC
CA #1 Valid Until:      2020-05-17 23:45:35 +0000 UTC

Writing SVID #0 to file /tmp/certs/svid.0.pem.
Writing key #0 to file /tmp/certs/svid.0.key.
Writing bundle #0 to file /tmp/certs/bundle.0.pem.
Fetching certificate ...
```

Issue a request against the proxy. This will use the client certificate your
generated in the previous step:

```bash
$ ./scripts/3-curl.sh
Fetching external IP address ...
Issuing curl ...
Request served by backend-68c6c7cbb8-c6lcg

HTTP/1.1 GET /tada

Host: example.com
X-Request-Id: 9fa00731-1b6f-4619-89ac-d3a50c0e5a77
X-Envoy-Expected-Rq-Timeout-Ms: 15000
Content-Length: 0
User-Agent: curl/7.69.1
Accept: */*
X-Forwarded-Proto: https
```

Modify `./scripts/3-curl.sh` to remove the use of the client keypair:

```diff
diff --git a/scripts/3-curl.sh b/scripts/3-curl.sh
index f3b1aae..2028c1b 100755
--- a/scripts/3-curl.sh
+++ b/scripts/3-curl.sh
@@ -14,7 +14,5 @@ _ip=$(kubectl -n proxy get svc proxy \

 echo "Issuing curl ..."
 curl --resolve "example.com:443:$_ip" \
-  --cert ./certs/svid.0.pem \
-  --key ./certs/svid.0.key \
   --cacert ./certs/bundle.0.pem \
   https://example.com
```

Issue the request again:

```bash
$ ./scripts/3-curl.sh
Fetching external IP address ...
Issuing curl ...
curl: (56) BoringSSL SSL_read: error:1000045c:SSL routines:OPENSSL_internal:TLSV1_CERTIFICATE_REQUIRED, errno 0
```

As the requests were not sent with the workload identity, the requests will
fail at the proxy - i.e. we couldn't even complete a TLS handshake with the
proxy! Yaaaas. 💪

At this point, we're done! We used SPIFFE and SPIRE to set up a PKI running in
the cluster, attesting that our workloads were legit. We configured Envoy to
tap into this by consuming the identities with SDS. We then issued a
certificate for ourselves to use locally and mutually authenticated with this
identity with Envoy, who proxied our request to a backend!

## Tear-down

In principle, let's clean up the workload entries before we destroy everything:

```bash
Fetching existing SPIRE entries
f6c3f2f1-1276-406b-b96b-dd478c4eb152
09bb61e2-fcfa-4f62-b7bb-a8d93f752653
629b30a6-0918-46ca-955b-e9811b8cec90
...
Done!
```

Remember to run `cd terraform && terraform destroy` when you're done! Or scale
down the node pool to size zero.

## TODOs

Some things I'd like to prove out:

- Envoy for the backend
- Backend's Envoy checking proxied x509 certificate of the client
- Client workload running outside of K8s, on a Cloud provider using the
  appropriate attestors for that platform
