#!/bin/bash
set -e

export DEBIAN_FRONTEND=noninteractive

echo "[INFO] Installing Kubernetes prerequisites..."

echo "[INFO] apt-get update ..."
sudo apt-get update -y
sudo apt purge --auto-remove apparmor -y 
echo "[INFO] Installing base packages (force-confdef/confold)..."
sudo apt-get install -y \
  --option Dpkg::Options::="--force-confdef" \
  --option Dpkg::Options::="--force-confold" \
  apt-transport-https \
  ca-certificates \
  curl \
  gnupg2 \
  software-properties-common

echo "[INFO] Configuring Docker repository & installing containerd..."
# Add Docker repo
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/trusted.gpg.d/docker.gpg
sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
sudo apt-get update -y

sudo apt-get install -y \
  --option Dpkg::Options::="--force-confdef" \
  --option Dpkg::Options::="--force-confold" \
  containerd.io

# Configure containerd
sudo mkdir -p /etc/containerd
sudo containerd config default | sudo tee /etc/containerd/config.toml >/dev/null
# enable SystemdCgroup
sudo sed -i 's/SystemdCgroup = false/SystemdCgroup = true/' /etc/containerd/config.toml
sudo sed -i 's|sandbox_image = ".*"|sandbox_image = "registry.k8s.io/pause:3.10"|' /etc/containerd/config.toml
sudo systemctl daemon-reload
sudo systemctl restart containerd
sudo systemctl enable containerd

echo "[INFO] Adding Kubernetes repository..."
sudo mkdir -p /etc/apt/keyrings
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.32/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/k8s.gpg
echo 'deb [signed-by=/etc/apt/keyrings/k8s.gpg] https://pkgs.k8s.io/core:/stable:/v1.32/deb/ /' | sudo tee /etc/apt/sources.list.d/kubernetes.list

sudo apt-get update -y
echo "[INFO] Installing kubeadm, kubelet, kubectl..."
sudo apt-get install -y \
  --option Dpkg::Options::="--force-confdef" \
  --option Dpkg::Options::="--force-confold" \
  kubelet kubeadm kubectl

sudo apt-mark hold kubelet kubeadm kubectl
sudo apt purge --auto-remove apparmor

echo "[INFO] Done installing Kubernetes components."


