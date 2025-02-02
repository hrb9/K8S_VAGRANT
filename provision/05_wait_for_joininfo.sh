#!/bin/bash
set -e

ROLE="$1"
# [INFO] Waiting for the join command file specific to this role to become available...
echo "[INFO] Waiting for $ROLE-join-command.sh to become available..."

# Loop until the file exists
while [ ! -f /vagrant/${ROLE}-join-command.sh ]; do
  # [INFO] The file is not found yet, sleep for a bit...
  echo "[INFO] /vagrant/${ROLE}-join-command.sh not found yet. Sleeping..."
  sleep 5
done

# [INFO] The file has been found, we will adjust it and then execute the join command...
echo "[INFO] Found /vagrant/${ROLE}-join-command.sh. Adjusting and executing join..."

# Read the join command file as raw text
RAW=$(< /vagrant/${ROLE}-join-command.sh)

# Isolate the "kubeadm join" part and everything that follows (about 5-10 lines forward),
# filter out comments and empty lines
LINES=$(echo "$RAW" | sed -n '/kubeadm join/,/^\s*$/p' | grep -v '^#' | grep -v '^\s*$')

# Now we will remove the backslashes from the end of the lines and join everything into a single line:
#   1) Remove backslashes at the end of lines
#   2) Replace newlines with spaces
JOIN_CMD=$(echo "$LINES" \
  | sed 's/\\$//' \
  | tr '\n' ' ' \
  | sed 's/  */ /g' )

# If this is a "control-plane", we'll add some parameters:
if [ "$ROLE" = "control-plane" ]; then
  # Get the private IP address
  PRIVATE_IP=$(hostname -I | awk '{print $2}')
  # [INFO] Detected that this is a control-plane node. We will add the private IP to the command.
  echo "[INFO] Detected control-plane node. Will add --apiserver-advertise-address=${PRIVATE_IP} to the command."

  # Append the advertise-address parameter
  JOIN_CMD="$JOIN_CMD --apiserver-advertise-address=${PRIVATE_IP}"
fi

# [INFO] Print the final join command
echo "[INFO] Final join command: $JOIN_CMD"

# Execute the command
bash -c "$JOIN_CMD"

# [INFO] The kubeadm join command has completed
echo "[INFO] kubeadm join completed for role=${ROLE}."

# Configure kubeconfig for the vagrant user
mkdir -p /home/vagrant/.kube
# If the admin.conf file exists (it should on the control-plane)
if [ -f /etc/kubernetes/admin.conf ]; then
  # Copy it to the user's home directory
  sudo cp /etc/kubernetes/admin.conf /home/vagrant/.kube/config
  # Change ownership to the vagrant user
  sudo chown vagrant:vagrant /home/vagrant/.kube/config
fi

# [INFO] Finished configuring Kube config
echo "[INFO] Done configuring Kube config for user vagrant on role=${ROLE}."