#!/bin/bash
set -e

# [INFO] Initializing Kubernetes master (control-plane).
echo "[INFO] Initializing Kubernetes master (control-plane)."

# Capture private IP
NODE_IP=$(hostname -I | awk '{print $2}')
# [INFO] Using the detected private IP for apiserver-advertise-address
echo "[INFO] Using NODE_IP=${NODE_IP}"

sudo kubeadm init \
  --control-plane-endpoint "lb:6443" \
  --apiserver-advertise-address="${NODE_IP}" \
  --upload-certs \
  --pod-network-cidr=192.168.0.0/16 | sudo tee /vagrant/kubeadm-init.out

# [INFO] kubeadm init completed.
echo "[INFO] kubeadm init completed successfully."

mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config

mkdir -p /home/vagrant/.kube
sudo cp -i /etc/kubernetes/admin.conf /home/vagrant/.kube/config
sudo chown vagrant:vagrant /home/vagrant/.kube/config
# [INFO] Installing Calico with a custom Pod Network CIDR...
echo "[INFO] Installing Calico with custom Pod Network CIDR..."

# Download the Calico manifest file
curl -LO https://raw.githubusercontent.com/projectcalico/calico/v3.26.1/manifests/calico.yaml

# Adjust the CIDR to the desired network range
sed -i 's#- name: CALICO_IPV4POOL_CIDR\n  value: "192.168.0.0/16"#- name: CALICO_IPV4POOL_CIDR\n  value: "192.168.0.0/16"#' calico.yaml

# Apply the manifest using a custom kubeconfig
kubectl --kubeconfig=/home/vagrant/.kube/config apply -f calico.yaml

# Clean up the manifest file
rm calico.yaml

# [INFO] Calico installed successfully.
echo "[INFO] Calico installed successfully."



# [INFO] Extracting control-plane join command from kubeadm-init.out...
echo "[INFO] Extracting control-plane join command from kubeadm-init.out..."
JOIN_CMD_CP=$(
  grep -A7 "You can now join any number of control-plane nodes" /vagrant/kubeadm-init.out \
    | tail -n +2 \
    | sed 's/^ *//' \
    | sed '/^$/d' \
    | grep -v "^You can now join any number of worker" \
    | grep -v "^Please note" \
    | grep -v "^As a safeguard"
)

if ! echo "$JOIN_CMD_CP" | grep -q "kubeadm join"; then
  # [ERROR] Could not parse control-plane join command.
  echo "[ERROR] Could not parse control-plane join command."
  exit 1
fi

echo "#!/bin/bash" > /vagrant/control-plane-join-command.sh
echo "$JOIN_CMD_CP" >> /vagrant/control-plane-join-command.sh
chmod +x /vagrant/control-plane-join-command.sh

# [INFO] Extracting worker join command...
echo "[INFO] Extracting worker join command..."
JOIN_CMD_WORKER=$(
  grep -A5 "Then you can join any number of worker nodes" /vagrant/kubeadm-init.out \
    | tail -n +2 \
    | sed 's/^ *//' \
    | sed '/^$/d'
)

if ! echo "$JOIN_CMD_WORKER" | grep -q "kubeadm join"; then
  # [ERROR] Could not parse worker join command.
  echo "[ERROR] Could not parse worker join command."
  exit 1
fi

echo "#!/bin/bash" > /vagrant/worker-join-command.sh
echo "$JOIN_CMD_WORKER" >> /vagrant/worker-join-command.sh
chmod +x /vagrant/worker-join-command.sh

# [INFO] Master (control-plane) init script completed successfully.
echo "[INFO] Master (control-plane) init script completed successfully."
# [INFO] Created join command files for control-plane and worker nodes.
echo "[INFO] Created /vagrant/control-plane-join-command.sh and /vagrant/worker-join-command.sh."