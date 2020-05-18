module network {
  source = "./modules/network"

  region = var.region
}

module cluster {
  source = "./modules/k8s"

  network = module.network.network
  subnet  = module.network.gke-subnet
  region  = var.region
  zones   = var.zones
}

module vms {
  source = "./modules/vms"

  network = module.network.network
  subnet = module.network.vms-subnet
}

module dns {
  source = "./modules/dns"

  network = module.network.network
  spire-server-address = module.network.spire-server-ip
}
