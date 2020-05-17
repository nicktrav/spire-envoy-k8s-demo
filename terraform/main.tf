module network {
  source = "./modules/network"

  region = var.region
}

module cluster {
  source = "./modules/k8s"

  network = module.network.network
  subnet  = module.network.subnet
  region  = var.region
  zones   = var.zones
}
