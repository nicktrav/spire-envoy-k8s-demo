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

resource google_compute_subnetwork vms {
  name = "spire-envoy-vms"

  network = google_compute_network.network.self_link
  region  = var.region

  ip_cidr_range = "10.4.8.0/22"
}

resource google_compute_address spire-server {
  name = "spire-server"

  address_type = "INTERNAL"
  region = google_compute_subnetwork.k8s.region
  subnetwork = google_compute_subnetwork.k8s.self_link
  address = "10.4.1.1"
}

resource google_compute_firewall allow-ssh-vms {
  name = "allow-ssh"

  network = google_compute_network.network.self_link

  allow {
    protocol = "tcp"
    ports = ["22"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags = ["vms"]
}

resource google_compute_firewall allow-all-internal {
  name = "allow-all-internal"

  network = google_compute_network.network.self_link

  allow {
    protocol = "all"
  }

  source_ranges = ["10.0.0.0/8"]
}
