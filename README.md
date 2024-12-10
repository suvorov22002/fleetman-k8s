# FLEET MANAGEMENT APPLICATION
Ce projet est une application distribué permettant de suivre en temps réel une flotte de véhicule éffectuant des livraisons.
Elle sera déployé dans un cluster kubernetes, composé d'un node control panel et de 2 nodes worker.

## Fontionnalités
* fleetman-position-simulator
* fleetman-queue
* fleetman-position-tracker
* fleetman-mongo
* fleetman-api-gateway
* fleetman-web-app

## Technologies
* Kubernetes
* Docker - Container runtime
* Virtual Box
* Unbuntu-22.04
* Windows 10

## Démarrage
Pour commencer nous allons mettre en place notre cluster. Il sera installé sur Unbuntu-22.04 et comportera un noeud master et deux noeuds workers.

Après avoir installé virtualBox sur notre poste, suivre les étapes suivantes:

* copier le fichier VagrantFile dans un dossier de notre machine
* se déplacer dans ce dossier en ligne de commande et exécuter la commande _vagrant up_. Cela va créer 3 machines virtuelles avec Unbuntu installé dessus. 

La suite est l'installation de notre cluster via kubeadm. Les étapes suivantes sont à réaliser sur l'ensemble des trois machines.

* Désactivation permanente du swap. Se mettre en root et éxecuter les commandes suivantes:   
    ```bash 
    sudo swapoff -a  
    sudo sed -i '/swap/s/^/#/' /etc/fstab 
    ```
* configuration du hostname: cette étape est dejà effectué dans le Vagranfile. Le master a pour hostname _master01_ et les workers _worker01_ , _worker02_
* mise à jour du fichiers hosts pour la résolution des hostnames. Exécuter la commande `sudo vim etc/hosts` pour éditer le fichier hosts. Ajouter les lignes suivantes à la fin du fichier.
192.168.56.2 master01
192.168.56.3 worker01
192.168.56.4 worker02
* Configuration de IPV4 bridges.
    ```bash
    cat <<EOF | sudo tee /etc/modules-load.d/k8s/conf
    overlay
    br_netfilter
    EOF
    ```
 Charger les kernel modules suivant sur tous les noeuds.
    `sudo modprobe overlay` et `sudo modprobe br_netfilter`


* Configuration du kernel pour kubernetes
   ```bash
   cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
   net.bridge.bridge-nf-call-iptables  = 1
   net.bridge.bridge-nf-call-ip6tables = 1
   net.ipv4.ip_forward                 = 1
   EOF
   ```
Ensuite executer la commande `sudo sysctl --system` pour prendre en considération des modification sans besoin de rédemarrer.
* Installation de: kubelet, kubeadm, kubectl
    ```bash
    sudo apt update
    sudo apt install curl gpg ca-certificates apt-transport-https -y
    curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.31/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
    echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.31/deb/ /' | sudo tee /etc/apt/sources.list.d/kubernetes.list
    sudo apt update
    sudo apt install -y kubelet kubeadm kubectl
    sudo apt-mark hold kubelet kubeadm kubectl
    ```
* Installation de Docker - container runtime
    ```bash
    sudo apt install docker.io
    sudo mkdir /etc/containerd
    sudo sh -c "containerd config default > /etc/containerd/config.toml"
    #cgroup filter
    sudo sed -i 's/ SystemdCgroup = false/ SystemdCgroup = true' /etc/containerd/config.toml
    sudo systemctl restart containerd.service
    sudo systemctl restart kubelet.service
    sudo systemctl enable kubelet.service
    ```
* Initialisation du cluster kubernetes: Cette étape ce passe uniquement sur le master. On télecharge d'abord les différents packages des composants du noeud master (apiserver, scheduler, control manager, etcd)
    ```bash
    sudo kubeadm config images pull
    sudo kubeadm init --pod-network-cidr=10.244.0.0/16
    ```
A la fin de l'initialisation, lire les consignes afficher. Copier et noter la commande afficher _kubeadm join ...._, elle va servir pour joindre les noeuds worker au master.
Ensuite éxecuter les commandes suivantes pour créer le fichier de configuration de kubernetes.
    ```bash
    mkdir -p $HOME/.kube
    sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
    sudo chown $(id -u):$(id -g) $HOME/.kube/config
    ```
* Configuration de calico network, pour une communication entre les differents pods dans les cluster. (Uniquement sur le master)
    ```bash
    kubectl create -f https://raw.githubusercontent.com/projectcalico/v3.26.1/manifests/tigera-operator.yaml
    curl https://raw.githubusercontent.com/projectcalico/v3.26.1/manifests/custom-resources.yaml -O
    sed -i 's/cidr: 192\.168\.0\.0\/16/cidr: 10.244.0.0\/16/g' custom-resources.yaml
    kubectl create -f custom-resources.yaml
    ```
* Sur les noeuds worker uniquement, éxecuter la commande copier précedemment.
`kubeadm join 192.168.56.2:6443 --token y760wm.939eg87qay1f99mh --discovery-token-ca-cert-hash sha256:cc1f5e9379a047afb4353dfff280d669ff90eed6fb7e7435396864eb75644706`

## Déploiement des composants dans sur le master
* Créer le configmap. `kubectl apply -f fleetman-cm.yaml`
* Créer le secret. `kubectl apply -f fleetman-mongo-secret.yaml`
* Créer le persistent volume claim. `kubectl apply -f mongo-pvc.yaml`
* Ensuite lancer le reste de déploiement:
    ```bash
    kubectl apply -f fleetman-queue.yaml
    kubectl apply -f fleetman-api-gateway.yaml
    kubectl apply -f fleetman-mongo.yaml
    kubectl apply -f fleetman-position-simulator.yaml
    kubectl apply -f fleetman-position-tracker.yaml
    kubectl apply -f fleetman-web-app.yaml
    ```


