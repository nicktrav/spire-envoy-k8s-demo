terraform {
  required_version = "0.12.24"

  backend "local" {
    path = "./terraform.state"
  }
}

provider "google" {
  version = "2.20.0"

  // Update your project here.
  project = "UPDATE-ME"
}
