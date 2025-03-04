Vagrant.configure("2") do |config|
  config.vm.box = "opensuse/Leap-15.5.aarch64"
  config.vm.synced_folder ".", "/vagrant", type: "rsync"
  config.vm.synced_folder "~/vagrant_rpm_cache", "/var/cache/zypp/packages", type: "rsync"

  # Allow setting SSH port via an environment variable, default to 2222 if not set
  ssh_port = ENV.fetch("VAGRANT_SSH_PORT", "2222")

  config.vm.provider "qemu" do |qemu|
    qemu.qemu_binary = "/usr/local/bin/qemu-system-aarch64"
    qemu.memory      = 2048
    qemu.cpus        = 8
    qemu.disk_size   = "20G"
    qemu.machine     = "virt,accel=hvf,highmem=off"
    qemu.arch        = "aarch64"
    qemu.qemuargs    = [
      ["-netdev", "user,id=net0,hostfwd=tcp::#{ssh_port}-:22"],
      ["-device", "virtio-net-device,netdev=net0"]
    ]
  end

config.vm.provision "shell", inline: <<-SHELL
    # Ensure the 'keep_packages' option is set to 1 in /etc/zypp/zypp.conf
    if grep -q '^keep_packages' /etc/zypp/zypp.conf; then
        sudo sed -i 's/^keep_packages.*/keep_packages = 1/' /etc/zypp/zypp.conf
    else
        echo 'keep_packages = 1' | sudo tee -a /etc/zypp/zypp.conf
    fi
    sudo zypper mr --keep-packages repo-oss
    sudo zypper mr --keep-packages repo-update

    # Update and install basic utilities
    sudo zypper --non-interactive refresh
    sudo zypper --non-interactive update -y
    sudo zypper --non-interactive install -y wget gcc make bzip2 tar automake libtool zlib-devel glibc-devel libopenssl-devel procps hostname zip unzip git jq tree xz

    # Update PATH environment variable
    echo 'export PATH=$PATH:/usr/sbin:/sbin' | sudo tee -a /etc/profile
    export PATH=$PATH:/usr/sbin:/sbin

    # Build and install MUNGE from source
    cd /tmp
    wget https://github.com/dun/munge/releases/download/munge-0.5.15/munge-0.5.15.tar.xz
    tar -xf munge-0.5.15.tar.xz
    cd munge-0.5.15
    ./configure --prefix=/usr/local
    make -j4
    sudo make install

    # Ensure /usr/local/lib is in the dynamic linker config
    echo "/usr/local/lib" | sudo tee /etc/ld.so.conf.d/munge.conf
    sudo /sbin/ldconfig

    # Create munge group, user, and directories
    sudo groupadd --system munge || true
    sudo useradd --system --home /var/lib/munge --shell /sbin/nologin -g munge munge || true
    sudo mkdir -p /etc/munge /var/lib/munge /usr/local/var/run/munge /var/log/munge
    sudo chown -R munge:munge /var/lib/munge /usr/local/var/run/munge /var/log/munge
    sudo chmod 0700 /var/lib/munge /var/log/munge

    # Set permissions for MUNGE log file
    sudo chown -R munge:munge /usr/local/var/log/munge
    sudo touch /usr/local/var/log/munge/munged.log
    sudo chown munge:munge /usr/local/var/log/munge/munged.log
    sudo chmod 0600 /usr/local/var/log/munge/munged.log

    # Create munge key
    sudo /usr/local/sbin/mungekey --create

    # Import MUNGE key and service file from host
    sudo cp /usr/local/etc/munge/munge.key /etc/munge/munge.key
    sudo cp /vagrant/munge_files/munge.service /etc/systemd/system/munge.service

    # Set permissions for the MUNGE key
    sudo chown munge:munge /etc/munge/munge.key
    sudo chmod 0400 /etc/munge/munge.key

    # Adjust socket directory permissions
    sudo chown -R munge:munge /usr/local/var/run/munge
    sudo chmod 0751 /usr/local/var/run/munge

    # Enable and start MUNGE service
    sudo systemctl daemon-reload
    sudo systemctl enable munge
    sudo systemctl start munge

    # Verify MUNGE is running
    /usr/local/bin/munge -n | /usr/local/bin/unmunge

    # Install SLURM dependencies
    sudo zypper --non-interactive install -y readline-devel pam-devel perl-ExtUtils-MakeMaker patterns-devel-base-devel_basis python3 python3-pip

    # Download and install SLURM
    SLURM_VERSION=23.02.6
    wget https://download.schedmd.com/slurm/slurm-$SLURM_VERSION.tar.bz2
    tar -xvjf slurm-$SLURM_VERSION.tar.bz2
    cd slurm-$SLURM_VERSION
    ./configure
    make -j4
    sudo make install

    # Copy SLURM config
    sudo mkdir -p /etc/slurm
    sudo cp /vagrant/slurm.conf /usr/local/etc/slurm.conf
    sudo cp /vagrant/cgroup.conf /usr/local/etc/cgroup.conf
    sudo mkdir -p /var/spool/slurmctld /var/spool/slurmd


    # Configure SLURM systemd services
    sudo cp etc/slurmctld.service /etc/systemd/system/
    sudo cp etc/slurmd.service /etc/systemd/system/

    # Enable and start SLURM services
    sudo systemctl daemon-reload
    sudo systemctl enable slurmctld
    sudo systemctl enable slurmd
    sudo systemctl start slurmctld
    sudo systemctl start slurmd

    # Installing nomad
    export NOMAD_VERSION=1.9.4
    wget https://releases.hashicorp.com/nomad/${NOMAD_VERSION}/nomad_${NOMAD_VERSION}_linux_arm64.zip
    unzip nomad_${NOMAD_VERSION}_linux_arm64.zip
    sudo mv nomad /usr/local/bin/

    # Create nomad certificates
    sudo cp /vagrant/nomad_files/create_nomad_certs.sh ~/create_nomad_certs.sh
    sudo mkdir -p ~/certs
    sudo sh ~/create_nomad_certs.sh 

    # Copy Nomad configs
    sudo mkdir -p /etc/nomad.d
    sudo mkdir -p /etc/nomad.d/certs
    sudo cp /vagrant/nomad_files/nomad.hcl /etc/nomad.d/nomad.hcl
    sudo cp /vagrant/nomad_files/nomad.service /etc/systemd/system/nomad.service
    sudo cp ~/certs/nomad-ca.pem /etc/nomad.d/certs/nomad-ca.pem
    sudo cp ~/certs/nomad-server.pem /etc/nomad.d/certs/nomad-server.pem
    sudo cp ~/certs/nomad-server.key /etc/nomad.d/certs/nomad-server.key

    # Setting the correct key permission
    sudo chown vagrant /etc/nomad.d/certs/nomad-server.key
    sudo chmod 400 /etc/nomad.d/certs/nomad-server.key


    # Enable and start Nomad services
    sudo systemctl daemon-reload
    sudo systemctl enable nomad
    sudo systemctl start nomad

  SHELL

  # Provision 2: Wait for Nomad to be ready, then bootstrap ACL
  config.vm.provision "shell", inline: <<-SHELL

    # Setting up nomad env vars
    export PATH=$PATH:/usr/local/bin
    export NOMAD_ADDR="https://127.0.0.1:4646"
    export NOMAD_CACERT="/etc/nomad.d/certs/nomad-ca.pem"

    echo "==> Waiting for Nomad to become active..."
    # Check for Nomad to be up
    for i in {1..10}; do
      if sudo systemctl is-active --quiet nomad; then
        echo "Nomad is active."
        break
      fi
      echo "Nomad not ready, retrying in 3s..."
      sleep 3
    done

    echo "==> Bootstrapping ACL..."
    BOOTSTRAP_OUTPUT=$(nomad acl bootstrap 2>&1)
    echo "$BOOTSTRAP_OUTPUT"

    # Extract the "Secret ID" from the output
    NOMAD_TOKEN=$(echo "$BOOTSTRAP_OUTPUT" | grep "Secret ID" | awk '{print $4}')

    if [ -z "$NOMAD_TOKEN" ]; then
      echo "ERROR: Could not parse bootstrap token." >&2
      exit 1
    fi

    # Set env vars in bashrc
    echo "==> Setting environment variables in /home/vagrant/.bashrc ..."
    echo 'export NOMAD_ADDR="https://127.0.0.1:4646"' >> /home/vagrant/.bashrc
    echo 'export NOMAD_CACERT="/etc/nomad.d/certs/nomad-ca.pem"' >> /home/vagrant/.bashrc
    echo "export NOMAD_TOKEN=\"$NOMAD_TOKEN\"" >> /home/vagrant/.bashrc

    # Set token for next check
    export NOMAD_TOKEN="$NOMAD_TOKEN"

    # ACL verification
    echo "==> Verifying ACL works..."
    nomad node status

    # Installing terraform
    export TERRAFORM_VERSION=1.10.5
    wget https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_arm64.zip
    unzip terraform_${TERRAFORM_VERSION}_linux_arm64.zip
    sudo mv terraform /usr/local/bin/

    # Set env vars for vServices
    echo 'export TF_VAR_nomad_server_url="https://127.0.0.1:4646"' >> /home/vagrant/.bashrc
    echo 'export TF_VAR_nomad_secret_id="$NOMAD_TOKEN"' >> /home/vagrant/.bashrc
    echo 'export TF_VAR_nomad_ca_cert="/etc/nomad.d/certs/nomad-ca.pem"' >> /home/vagrant/.bashrc
    echo 'export TF_VAR_nomad_cli_cert="/etc/nomad.d/certs/nomad-server.pem"' >> /home/vagrant/.bashrc
    echo 'export TF_VAR_nomad_cli_key="/etc/nomad.d/certs/nomad-server.key"' >> /home/vagrant/.bashrc

    # Install Alps-specific RPMs
    sudo mkdir -p ~/rpms
    sudo cp /vagrant/rpms/fakerootuidsync-0.0.3-3.aarch64.rpm ~/rpms/fakerootuidsync-0.0.3-3.aarch64.rpm
    cd ~/rpms
    sudo zypper install ./fakerootuidsync-0.0.3-3.aarch64.rpm

    # Copy vCluster spec
    sudo mkdir -p ~/vcluster
    sudo cp /vagrant/vcluster/* ~/vcluster
    
    # Install Go test framework Ginkgo
    export GO_VERSION=1.24.0
    wget https://go.dev/dl/go${GO_VERSION}.linux-arm64.tar.gz
    sudo rm -rf /usr/local/go && sudo tar -C /usr/local -xzf go${GO_VERSION}.linux-arm64.tar.gz
    echo 'export PATH=$PATH:/usr/local/go/bin' >> ~/.bashrc
    export PATH=$PATH:/usr/local/go/bin
    go get -u github.com/onsi/gomega
    go install github.com/onsi/ginkgo/v2

    # install podman-nfs dependencies
    sudo zypper --non-interactive install -y device-mapper-devel btrfsprogs

  SHELL
end
