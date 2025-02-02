# -*- mode: ruby -*-
# vi: set ft=ruby:

Vagrant.configure("2") do |config|
  # Define the base box to use
  config.vm.box = "bento/ubuntu-24.04"

  # General settings for VirtualBox (memory and CPU cores)
  config.vm.provider "virtualbox" do |vb|
    vb.memory = 4096
    vb.cpus   = 2
  end

  # Function to add NVMe controller and disk to Worker VMs
  def add_nvme_disk(vm, disk_name)
    vm.vm.provider "virtualbox" do |vb|
      # Add NVMe controller
      vb.customize ["storagectl",:id, "--name", "NVMeController", "--add", "pcie", "--controller", "NVMe"]
      # Add disk to the NVMe controller
      vb.customize ["createhd", "--filename", disk_name, "--size", 25600] # Size in MB (25GB)
      vb.customize ["storageattach",:id, "--storagectl", "NVMeController", "--port", 0, "--device", 0, "--type", "hdd", "--medium", disk_name]
    end
  end

  # ----------- Machine 1: Load Balancer -----------
  config.vm.define "lb" do |lb|
    lb.vm.hostname = "lb"
    lb.vm.network "private_network", ip: "192.168.56.100"

    # (Optional) Forwarded port - access to 6443 from the host machine
    lb.vm.network:forwarded_port, guest: 6443, host: 6443

    # Provisioning
    lb.vm.provision "shell", path: "provision/07_configure_hosts.sh"
    lb.vm.provision "shell", path: "provision/01_install_k8s.sh"
    lb.vm.provision "shell", path: "provision/02_configure_lb.sh"
  end

  # ----------- Machine 2: Master 1 -----------
  config.vm.define "master1" do |m|
    m.vm.hostname = "k8s-master-1"
    m.vm.network "private_network", ip: "192.168.56.101"

    # Provisioning
    m.vm.provision "shell", path: "provision/07_configure_hosts.sh"
    m.vm.provision "shell", path: "provision/01_install_k8s.sh"
    m.vm.provision "shell", path: "provision/04_init_master.sh"
  end

  # ----------- Machine 3: Master 2 -----------
  config.vm.define "master2" do |m|
    m.vm.hostname = "k8s-master-2"
    m.vm.network "private_network", ip: "192.168.56.102"

    # Provisioning
    m.vm.provision "shell", path: "provision/07_configure_hosts.sh"
    m.vm.provision "shell", path: "provision/01_install_k8s.sh"
    m.vm.provision "shell", path: "provision/05_wait_for_joininfo.sh", args: ["control-plane"]
  end

  # ----------- Machine 4: Master 3 -----------
  config.vm.define "master3" do |m|
    m.vm.hostname = "k8s-master-3"
    m.vm.network "private_network", ip: "192.168.56.103"

    # Provisioning
    m.vm.provision "shell", path: "provision/07_configure_hosts.sh"
    m.vm.provision "shell", path: "provision/01_install_k8s.sh"
    m.vm.provision "shell", path: "provision/05_wait_for_joininfo.sh", args: ["control-plane"]
  end

  # ----------- Machine 5: Worker 1 -----------
  config.vm.define "worker1" do |w|
    w.vm.hostname = "k8s-worker-1"
    w.vm.network "private_network", ip: "192.168.56.104"

    # Add NVMe controller and disk
    add_nvme_disk(w, "disk-worker1.vdi")

    # Provisioning
    w.vm.provision "shell", path: "provision/07_configure_hosts.sh"
    w.vm.provision "shell", path: "provision/01_install_k8s.sh"
    w.vm.provision "shell", path: "provision/03_configure_nvme.sh"
    w.vm.provision "shell", path: "provision/05_wait_for_joininfo.sh", args: ["worker"]
  end

  # ----------- Machine 6: Worker 2 -----------
  config.vm.define "worker2" do |w|
    w.vm.hostname = "k8s-worker-2"
    w.vm.network "private_network", ip: "192.168.56.105"

    # Add NVMe controller and disk
    add_nvme_disk(w, "disk-worker2.vdi")

    # Provisioning
    w.vm.provision "shell", path: "provision/07_configure_hosts.sh"
    w.vm.provision "shell", path: "provision/01_install_k8s.sh"
    w.vm.provision "shell", path: "provision/03_configure_nvme.sh"
    w.vm.provision "shell", path: "provision/05_wait_for_joininfo.sh", args: ["worker"]
  end

  # ----------- Machine 7: Worker 3 -----------
  config.vm.define "worker3" do |w|
    w.vm.hostname = "k8s-worker-3"
    w.vm.network "private_network", ip: "192.168.56.106"

    # Add NVMe controller and disk
    add_nvme_disk(w, "disk-worker3.vdi")

    # Provisioning
    w.vm.provision "shell", path: "provision/07_configure_hosts.sh"
    w.vm.provision "shell", path: "provision/01_install_k8s.sh"
    w.vm.provision "shell", path: "provision/03_configure_nvme.sh"
    w.vm.provision "shell", path: "provision/05_wait_for_joininfo.sh", args: ["worker"]
  end
end
