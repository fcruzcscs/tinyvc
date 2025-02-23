module "vcluster" {
  source     = "git::https://git.cscs.ch/alps-platforms/vservices/vs-vcluster.git"
  datacenter = "vc-tiny"
  namespace  = "default"
  owner                    = "Super8"
  nomad_lock_token         = var.nomad_secret_id
  packages_os              = "opensuse-15.5"
  # mem limits
  default_resources_memory = "60"
  default_resources_memory_max = "300"
}

module "podman" {
  source   = "git::https://git.cscs.ch/alps-platforms/vservices/vs-podman.git?ref=main"
  deploy   = true
  vcluster = module.vcluster

  podman_version  = "5.4.0-0"
  podman_maturity = "-dev"
}
