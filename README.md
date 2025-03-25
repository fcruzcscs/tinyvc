# Vagrant VM for vService development on openSUSE Leap 15.5 (aarch64) with SLURM and Nomad

## Overview

This repository provides a Vagrant configuration for setting up an openSUSE Leap 15.5 (aarch64) virtual machine using QEMU. The VM includes a fully configured SLURM workload manager, Nomad, and other necessary dependencies compatible for vService development.

## Requirements

Before running this setup, ensure you have the following installed on your host machine:

- [Vagrant](https://www.vagrantup.com/)
- [QEMU](https://www.qemu.org/)
- [Vagrant QEMU Provider](https://github.com/sciurus/vagrant-qemu)

## Setup Instructions

1. **Clone the repository**

   ```sh
   git clone ...
   ```

2. **Start the Vagrant machine:**

   ```sh
   vagrant up
   ```

   This will provision the VM, install necessary dependencies, and configure SLURM, Nomad, and Terraform.

3. **Access the virtual machine:**

   ```sh
   vagrant ssh
   ```

4. **Verify installations:**

   - Check if SLURM is running:

     ```sh
     scontrol show nodes
     ```

   - Check if Nomad is running:

     ```sh
     nomad node status
     ```

## SLURM Configuration Overview

SLURM is installed and configured with the following key settings:
- **MUNGE authentication** is enabled to ensure secure communication.
- **SLURM control daemon (slurmctld)** is enabled to manage job scheduling.
- **SLURM compute daemon (slurmd)** is set up for node execution.
- Configuration files (`slurm.conf`, `cgroup.conf`) are provided via the Vagrant synced folder.
- Systemd services for `slurmctld` and `slurmd` are installed and enabled.

## Nomad Configuration Overview

Nomad is installed with the following key settings:
- **SSL certificates** are configured to secure communication.
- **Nomad service** is installed and enabled via systemd.
- **Bootstrap ACL process** is performed to initialize authentication.
- **Environment variables** for Nomad access (`NOMAD_ADDR`, `NOMAD_TOKEN`) are set up.
- Configuration files (`nomad.hcl`, `nomad.service`, and certificates) are provided via the Vagrant synced folder.


## Environment Variables Setup

After provisioning, the following environment variables are automatically set in `/home/vagrant/.bashrc`:

```sh
export NOMAD_ADDR="https://127.0.0.1:4646"
export NOMAD_CACERT="/etc/nomad.d/certs/nomad-ca.pem"
export NOMAD_TOKEN="<your-generated-token>"
export TF_VAR_nomad_server_url="https://127.0.0.1:4646"
export TF_VAR_nomad_secret_id="$NOMAD_TOKEN"
export TF_VAR_nomad_ca_cert="/etc/nomad.d/certs/nomad-ca.pem"
export TF_VAR_nomad_cli_cert="/etc/nomad.d/certs/nomad-server.pem"
export TF_VAR_nomad_cli_key="/etc/nomad.d/certs/nomad-server.key"
```

## Notes

- The VM provisions automatically on `vagrant up`.
- To destroy the VM, use:

  ```sh
  vagrant destroy -f
  ```

- If changes are made to the configuration, reload the VM with:

  ```sh
  vagrant reload --provision
  ```
