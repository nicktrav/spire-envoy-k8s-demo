output network {
  value = google_compute_network.network.self_link
}

output gke-subnet {
  value = google_compute_subnetwork.k8s.self_link
}

output vms-subnet {
  value = google_compute_subnetwork.vms.self_link
}

output spire-server-ip {
  value = google_compute_address.spire-server.address
}
