output network {
  value = google_compute_network.network.self_link
}

output subnet {
  value = google_compute_subnetwork.k8s.self_link
}
