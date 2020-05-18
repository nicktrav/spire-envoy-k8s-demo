data local_file startup-script {
  filename = "${path.module}/startup.sh"
}

resource google_compute_instance vm-1 {
  name = "vm-1"

  zone = "us-central1-a"
  machine_type = "n1-standard-1"
  tags = ["vms"]

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-10"
    }
  }

  network_interface {
    network = var.network
    subnetwork = var.subnet
    access_config {
      network_tier = "STANDARD"
    }
  }

  allow_stopping_for_update = true

  service_account {
    scopes = [
      "https://www.googleapis.com/auth/compute.readonly",
      "https://www.googleapis.com/auth/logging.write",
    ]
  }

  metadata_startup_script = data.local_file.startup-script.content
}
