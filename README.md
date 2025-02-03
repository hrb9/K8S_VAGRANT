## K8S_VAGRANT

This project allows you to easily set up a Kubernetes environment using Vagrant. The environment includes:

  * Load Balancer (LB)
  * Kubernetes Master (Control Plane)
  * Worker Nodes
  * Configured NVMe SSDs for storage
  * OpenEBS installed for storage management

### Project Structure
 ```bash
K8S_VAGRANT/
├── 01_install_k8s.sh
├── 02_configure_lb.sh
├── 03_configure_nvme.sh
├── 04_init_master.sh
├── 05_wait_for_joininfo.sh
├── 06_install_openebs.sh
├── 07_configure_hosts.sh
├── README.md
└── Vagrantfile
   ```

### Prerequisites

  * **Vagrant**: Version 2.2.19 or higher. ([https://www.vagrantup.com/downloads](https://www.vagrantup.com/downloads))
  * **VirtualBox**: Version 6.1 or higher. ([https://www.virtualbox.org/wiki/Downloads](https://www.virtualbox.org/wiki/Downloads))
  * **kubectl**: Command-line tool for managing Kubernetes. ([https://kubernetes.io/docs/tasks/tools/install-kubectl/](https://kubernetes.io/docs/tasks/tools/install-kubectl/))
  * **helm**: Package manager for Kubernetes. ([https://helm.sh/docs/intro/install/](https://helm.sh/docs/intro/install/))

### Getting Started

1.  **Clone the repository:**

    ```bash
    git clone https://github.com/hrb9/K8S_VAGRANT.git
    cd K8S_VAGRANT
    ```

2.  **Run Vagrant:**

    ```bash
    vagrant up
    ```

    This command will create and configure all virtual machines according to the `Vagrantfile`.
    The `.sh` scripts will be executed automatically **per machine**, in the order they are defined within each machine's configuration in the `Vagrantfile`. Generally, this order is:

      * **`07_configure_hosts.sh`**: Configures hostnames and IP addresses. **This runs first on each machine.**
      * **`01_install_k8s.sh`**: Installs required Kubernetes packages. **This runs second on each machine.**
      * **Machine-Specific Scripts:**
        * **Load Balancer (`lb`)**:
          * **`02_configure_lb.sh`**: Configures the Load Balancer.
        * **Master Node 1 (`master1`)**:
          * **`04_init_master.sh`**: Initializes the Kubernetes Master (Control Plane).
        * **Worker Nodes (`worker1`, `worker2`, `worker3`)**:
          * **`03_configure_nvme.sh`**: Configures NVMe devices.
        * **All Other Nodes (Except `lb` and `master1`)**:
          * **`05_wait_for_joininfo.sh`**: Waits for the generation of join commands and executes the appropriate join command.


3.  **Wait for the process to complete.** Running the scripts may take some time (around 20-30 minutes, depending on hardware and internet connection).

4.  **Connect to the Master Node:**

    ```bash
    vagrant ssh master1
    ```

5.  **Check the cluster status:**

    ```bash
    kubectl get nodes
    kubectl get pods -A
    ```

### Notes

  * The default setup creates one control-plane machine (`k8s-master-1`) and two worker machines (`k8s-worker-1`, `k8s-worker-2`). You can change this in the `Vagrantfile`.
  * The default network settings use a "HostOnly" network with static IP addresses in the `192.168.56.0/24` range. You can modify this in the `Vagrantfile` and the `07_configure_hosts.sh` script.
  * The join commands for control-plane and worker nodes are saved in the `/vagrant` directory inside the virtual machines as `control-plane-join-command.sh` and `worker-join-command.sh` respectively.

### Troubleshooting

  * If you encounter any issues, make sure Vagrant, VirtualBox, kubectl, and helm are installed and configured correctly.
  * Check the logs of the scripts in the `/vagrant` directory inside the virtual machines.
  * Check the Kubernetes logs using `kubectl logs`.

### Contributions

Contributions are welcome\! Please open an Issue or Pull Request.