resource google_dns_managed_zone zone {
  name = "example-com"
  dns_name = "example.com."

  visibility = "private"
  private_visibility_config {
    networks {
      network_url = var.network
    }
  }
}
resource google_dns_record_set spire-server {
  managed_zone = google_dns_managed_zone.zone.name
  name = "spire-server.${google_dns_managed_zone.zone.dns_name}"
  type = "A"
  rrdatas = [
    var.spire-server-address
  ]
  ttl = 0
}