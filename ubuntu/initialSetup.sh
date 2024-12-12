export DEBIAN_FRONTEND=noninteractive
echo "[TASK 0] disable swap"
sudo swapoff -a
sudo sed -i '/swap/s/^/#/' /etc/fstab 

echo "[TASK 1] show whoami"
whoami

echo "[TASK 2] Stop and Disable firewall"
systemctl disable --now ufw >/dev/null 2>&1

echo "[TASK 3] Enable and Load Kernel modules"
cat <<EOF | sudo tee /etc/modules-load.d/k8s.conf
overlay
br_netfilter
EOF

echo "[TASK 3] Letting iptables see bridged traffic"
sudo modprobe br_netfilter
sudo modprobe overlay

echo "[TASK 5] Add Kernel settings"
cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward                 = 1
EOF

sudo sysctl --system

echo "[TASK 6] Install kubernetes v1.31"

sudo apt update
sudo apt install curl gpg ca-certificates apt-transport-https -y
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.31/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.31/deb/ /' | sudo tee /etc/apt/sources.list.d/kubernetes.list
sudo apt update
sudo apt install -y kubelet=1.31.4-1.1 kubeadm=1.31.4-1.1 kubectl=1.31.4-1.1
sudo apt-mark hold kubelet kubeadm kubectl

echo "[TASK 7] Install docker"

sudo apt install docker.io -y
sudo mkdir /etc/containerd
sudo sh -c "containerd config default > /etc/containerd/config.toml"
sudo sed -i 's/SystemdCgroup = false/SystemdCgroup = true/' /etc/containerd/config.toml
sudo systemctl restart containerd.service
sudo systemctl restart kubelet.service
sudo systemctl enable kubelet.service

echo "[TASK 8] Activate QEMU arm64 architecture"
sudo apt update
sudo apt install -y qemu qemu-user-static
docker run --rm --privileged multiarch/qemu-user-static --reset -p yes
docker run --rm --platform linux/arm64 busybox uname -m