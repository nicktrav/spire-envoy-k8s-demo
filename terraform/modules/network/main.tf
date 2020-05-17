resource "google_compute_network" network {
  name = "spire-envoy-k8s"

  routing_mode            = "GLOBAL"
  auto_create_subnetworks = false
}

resource google_compute_subnetwork k8s {
  name = "spire-envoy-k8s"

  network = google_compute_network.network.self_link
  region  = var.region

  ip_cidr_range = "10.4.0.0/22"

  secondary_ip_range {
    range_name    = "pods"
    ip_cidr_range = "10.0.0.0/14"
  }

  secondary_ip_range {
    range_name    = "services"
    ip_cidr_range = "10.4.4.0/22"
  }

  private_ip_google_access = true
}
