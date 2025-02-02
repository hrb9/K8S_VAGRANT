#!/usr/bin/env bash
set -euxo pipefail

#################################
# 0. Preliminary checks
#################################

# Require that the script runs as root (or via sudo).
if [ "$(id -u)" -ne 0 ]; then
  echo "[ERROR] Script must be run as root (or sudo)."
  exit 1
fi

curl https://baltocdn.com/helm/signing.asc | gpg --dearmor | sudo tee /usr/share/keyrings/helm.gpg > /dev/null
sudo apt-get install apt-transport-https --yes
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/helm.gpg] https://baltocdn.com/helm/stable/debian/ all main" | sudo tee /etc/apt/sources.list.d/helm-stable-debian.list
sudo apt-get update
sudo apt-get install helm
helm version

# [INFO] Adding 'openebs' helm repo...
echo "[INFO] Adding 'openebs' helm repo..."
helm repo add openebs https://openebs.github.io/openebs
helm repo update

# Check for 'helm' existence
if ! command -v helm >/dev/null 2>&1; then
  echo "[ERROR] Helm is not installed! Please install Helm v3+ first."
  exit 1
fi

HELM_VERSION=$(helm version --short)
# [INFO] Print the Helm version
echo "[INFO] Helm version: $HELM_VERSION"


#################################
# 2. Labeling the worker nodes for Mayastor
#################################
# (Adjust the names of the Worker nodes according to your actual names)

# [INFO] Label the worker nodes so that Mayastor will use them
echo "[INFO] Labeling the worker nodes for Mayastor usage..."

kubectl label node k8s-worker-1 openebs.io/engine=mayastor
kubectl label node k8s-worker-2 openebs.io/engine=mayastor
kubectl label node k8s-worker-3 openebs.io/engine=mayastor

#################################
# 4. Installing Mayastor from dedicated repo
#################################
helm install openebs openebs/openebs --namespace openebs --create-namespace 
#################################
# 5. Finish
#################################

# [INFO] We are done. You can check the status of the pods now.
echo "[INFO] Done installing OpenEBS & Mayastor. Check pods in 'openebs' and 'mayastor' namespaces."