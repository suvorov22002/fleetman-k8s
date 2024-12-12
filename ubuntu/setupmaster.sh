#!/bin/bash

echo "[TASK 1] Pull required containers"
kubeadm config images pull >/dev/null 2>&1

echo "[TASK 2] Initialize Kubernetes Cluster"
kubeadm init --pod-network-cidr 10.244.0.0/16 --apiserver-advertise-address=192.168.56.2>> /root/kubeinit.log --v=5

echo "[TASK 3] Deploy Calico network"
kubectl --kubeconfig=/etc/kubernetes/admin.conf create -f https://raw.githubusercontent.com/projectcalico/calico/release-v3.26/manifests/tigera-operator.yaml >/dev/null 2>&1
curl https://github.com/projectcalico/calico/blob/release-v3.26/manifests/custom-resources.yaml -O
sed -i 's/cidr: 192\.168\.0\.0\/16/cidr: 10.244.0.0\/16/g' custom-resources.yaml
kubectl create -f custom-resources.yaml

cd 
echo "[TASK 4] Generate and save cluster join command to /joincluster.sh"
kubeadm token create --print-join-command > /joincluster.sh 2>/dev/null

echo "[TASK 5] Setup public key for workers to access master"
cat >>~/.ssh/authorized_keys<<EOF
ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDgzZPMoIdRUw8DEmk6sm/SU3643qU9Km1ANbDGm6/9hDqz80WzniCnW2M3rgNpfhu8tB5QycwEV4Jjz8unVHyWWA1fkb+C6rPEEoIzI1DGTUgt+KSCeJSGrj53fnzv7whfvrfvFKaY0qTxs0tlnK00xygPHJpj8pKsp1HxfkTgHAVmbvtXx84t/3mgC4zJC8kGt8s3sbETml+G1Du88yBn9pUO7fJelDlPJoxLDDDSow9FibsqHyx1MLFam5Web7p6XLsjxXZM6y4FFyUmDGVPOizOESc7M2NHxOxW6Dgy5KKTOqAlQMLniXb0oL7pBb3SO27IEFu4nbtHc7JEtKn0kC7ilamjA8GGydxqyaXT4J/lUSN0kTyDUZYbr9T1Jz1a3/VaCEK0qXGWlxjVuCCy7cbXsTnTHvS+jHEUVlUa+8wwpmZ0UqDfawssqT/XaTVymWx4y+tj124zH2bSHq6MmHGsexDzuaOxvZwGsYClvYwGRSdbHI5BVn6FuslgLfgGviYJZM1HMCipSa7vnuX+KcH/CAdXOeqnVt9qJTd87a5S8XOaGto+/ZjPVaZSoxyi1YtEaVjy1heLSMAN98iTA9kD/tTvvjOg9EPWkkjzfhCiTwX57Cd9SppTDiLQwthTGi2y4qzGlFlrT+GuMYc2r89QB7oJT2yQjnuzR9aaLw== kubernetes-cluster-key
EOF

echo "[TASK 6] Setup kubectl"
mkdir -p $HOME/.kube
cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
chown $(id -u):$(id -g) $HOME/.kube/config