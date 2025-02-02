#!/bin/bash
set -e

# [INFO] Configuring basic system settings for Kubernetes...
echo "[INFO] Configuring basic system settings for Kubernetes..."

# 1) Update
sudo apt-get update -y

# 2) Disable swap
sudo swapoff -a
sudo sed -i '/ swap / s/^/#/' /etc/fstab

# 3) Set hostname
echo "$(hostname)" | sudo tee /etc/hostname



# 4) Rewrite /etc/hosts
sudo tee /etc/hosts > /dev/null <<EOF
127.0.0.1 localhost
192.168.56.100 lb
192.168.56.101 k8s-master-1
192.168.56.102 k8s-master-2
192.168.56.103 k8s-master-3
192.168.56.104 k8s-worker-1
192.168.56.105 k8s-worker-2
192.168.56.105 k8s-worker-3
EOF

# Read only the hostname without the domain
HOSTNAME="$(hostname -s)"
NETPLAN_PATH="/etc/netplan/50-vagrant-static.yaml"

# Assume all machines use eth1 as the "HostOnly" network
# And these are the addresses:
# lb=192.168.56.100, master1=192.168.56.101, master2=192.168.56.102,
# master3=192.168.56.103, worker1=192.168.56.104, worker2=192.168.56.105

case "$HOSTNAME" in
  lb)
    IP_ADDR="192.168.56.100/24"
    ;;
  k8s-master-1)
    IP_ADDR="192.168.56.101/24"
    ;;
  k8s-master-2)
    IP_ADDR="192.168.56.102/24"
    ;;
  k8s-master-3)
    IP_ADDR="192.168.56.103/24"
    ;;
  k8s-worker-1)
    IP_ADDR="192.168.56.104/24"
    ;;
  k8s-worker-2)
    IP_ADDR="192.168.56.105/24"
    ;;
  k8s-worker-3)
    IP_ADDR="192.168.56.106/24"
    ;;
  *)
    echo "Unrecognized hostname: $HOSTNAME. Skipping static IP config."
    exit 0
    ;;
esac

# Create (or replace) a netplan file with a static address on eth1
cat <<EOF | sudo tee $NETPLAN_PATH
network:
  version: 2
  renderer: networkd
  ethernets:
    eth1:
      addresses:
        - ${IP_ADDR}
      # Optional: If you want a default gateway, depending on the network structure
      # routes:
      #   - to: 0.0.0.0/0
      #     via: 192.168.56.1
      # If you want a specific DNS:
      # nameservers:
      #   addresses: [8.8.8.8, 1.1.1.1]

EOF

# Activate the settings
sudo netplan generate
sudo netplan apply

sudo apt update -y
sudo apt install -y lsscsi nvme-cli

# 5) IPv4 over IPv6 preference
sudo sed -i 's/^#precedence ::ffff:0:0\/96  100/precedence ::ffff:0:0\/96  100/' /etc/gai.conf

# 6) Enable IP forward
echo 'net.ipv4.ip_forward=1' | sudo tee -a /etc/sysctl.conf
sudo sysctl -p

# 7) Load modules
sudo modprobe overlay
sudo modprobe br_netfilter

# 8) Persist modules
echo 'overlay' | sudo tee /etc/modules-load.d/k8s.conf
echo 'br_netfilter' | sudo tee -a /etc/modules-load.d/k8s.conf

# 9) /etc/sysctl.d/kubernetes.conf
sudo tee /etc/sysctl.d/kubernetes.conf <<EOF
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
net.ipv4.ip_forward = 1
EOF

sudo sysctl --system

# If net.ipv4.ip_forward=1 hasn't been enabled yet
# sudo sysctl -w net.ipv4.ip_forward=1
# echo "net.ipv4.ip_forward = 1" | sudo tee -a /etc/sysctl.conf

# [INFO] Checking/Setting up HugePages...
echo "[INFO] Checking/Setting up HugePages..."
echo 1024 | sudo tee /sys/kernel/mm/hugepages/hugepages-2048kB/nr_hugepages
echo "vm.nr_hugepages=1024" | sudo tee -a /etc/sysctl.conf

# Load nvme-tcp module if needed
if ! lsmod | grep -q nvme_tcp; then
  sudo modprobe nvme_tcp
  echo "nvme_tcp" | sudo tee -a /etc/modules

  # [INFO] nvme-tcp module loaded.
  echo "[INFO] nvme-tcp module loaded."
else
  # [INFO] nvme-tcp module already loaded.
  echo "[INFO] nvme-tcp module already loaded."
fi
sudo modprobe ext4

sudo sysctl -p


# Set node-ip on the machine (kubelet is not necessarily installed yet, so we won't restart)
PRIVATE_IP="$(hostname -I | awk '{print $2}')"
# [INFO] Detected PRIVATE_IP=$PRIVATE_IP
echo "[INFO] Detected PRIVATE_IP=$PRIVATE_IP"
sudo mkdir -p /etc/default

cat <<EOF | sudo tee /etc/default/kubelet
KUBELET_EXTRA_ARGS="--node-ip=${PRIVATE_IP}"
EOF

# [INFO] Created /etc/default/kubelet with node-ip=$PRIVATE_IP
echo "[INFO] Created /etc/default/kubelet with node-ip=$PRIVATE_IP"