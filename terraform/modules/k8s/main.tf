locals {
  version = "1.15.11-gke.12"
}

resource "google_container_cluster" cluster {
  name = "spire-envoy-k8s"

  network            = var.network
  subnetwork         = var.subnet
  location           = var.region
  node_locations     = var.zones
  min_master_version = local.version

  ip_allocation_policy {
    cluster_secondary_range_name  = "pods"
    services_secondary_range_name = "services"
  }

  network_policy {
    provider = "CALICO"
    enabled  = true
  }

  master_auth {
    client_certificate_config {
      issue_client_certificate = false
    }
  }

  remove_default_node_pool = true
  initial_node_count       = 1
}

resource "google_container_node_pool" pool {
  name    = "pool-1"
  cluster = google_container_cluster.cluster.name

  location   = var.region
  version    = local.version
  node_count = var.nodes

  node_config {
    preemptible  = var.preemptible
    machine_type = var.machine-type
    metadata = {
      disable-legacy-endpoints = "true"
    }
    oauth_scopes = [
      "https://www.googleapis.com/auth/devstorage.read_only",
      "https://www.googleapis.com/auth/logging.write",
      "https://www.googleapis.com/auth/monitoring",
    ]
    disk_size_gb = 10
  }

  management {
    auto_upgrade = false
    auto_repair  = true
  }
}
