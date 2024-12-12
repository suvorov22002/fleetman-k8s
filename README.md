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
* Virtual Box (https://www.virtualbox.org/)
* Unbuntu-22.04
* Windows 10/11
* Vagrant (https://developer.hashicorp.com/vagrant/install)

## Démarrage
Pour commencer nous allons mettre en place notre cluster. Il sera installé sur Unbuntu-22.04 et comportera un noeud master et deux noeuds workers.

Après avoir installé virtualBox et Vagrant sur notre poste, suivre les étapes suivantes:

* copier le fichier VagrantFile et le dossier ubuntu du projet dans un dossier de notre machine
* se déplacer dans ce dossier en ligne de commande et exécuter la commande _vagrant up_. Cela va créer 3 machines virtuelles avec Unbuntu installé dessus. Les machines ont des adresses IP dejà fixées: master (192.168.56.2), workers (192.168.56.3, 192.168.56.4)
* se connecter sur chaque machine: dans le dossier où se trouve la vagrantfile éxecuter la commande à partir de trois terminaux différents `vagrant ssh master01`, `vagrant ssh worker01`, `vagrant ssh worker02`
* Sur chaque machine vérifier si les adresses IP sont bien configurés et que le ping vers les différentes machines passe normalement. En cas de problème d'IP mal configuré, éxécuter l'ensemble des commandes suivantes:
    ```bash
    sudo ip link set eth1 up
    sudo ip addr add <adresse IP>/24 dev eth1
    sudo ip link set eth1 up
    ip addr show eth1
    ```
Pour vérifier que notre cluster est bien installé et démarré, en tant que root sur le master éxécuter la commande: `kubectl get nodes -o wide`
## Déploiement des composants dans sur le master

copier les differents fichiers de manifest sur le master node. A partir de votre invite de commande windows executer: `scp fleetman-queue.yaml mongo-pvc.yaml fleetman-position-simulator.yaml fleetman-api-gateway.yaml fleetman-position-tracker.yaml fleetman-mongo.yaml fleetman-mongo-secret.yaml fleetman-web-app.yaml fleetman-cm.yaml storageclass.yaml vagrant@192.168.56.2:/home/vagrant/`

* Se connecter au noeud worker01 et créer le repertoire /mnt/mongo/data: `sudo mkdir -p /mnt/mongo/data`. Ce dossier sera utiliser par le persistent volume pour le stockage.
Se positionner sur la machine master pour la suite
* Créer une ressource storageclass; `kubectl apply -f storageclass.yaml`
* créer un namespace pour l'application nommée: kubectl create namespace _fleetman-001_. Pour cela éxécuter la commande: `kubectl create namespace fleetman-001`
* Créer le configmap. `kubectl apply -f fleetman-cm.yaml`
* Créer le secret. `kubectl apply -f fleetman-mongo-secret.yaml`
* Créer le persistent volume. `kubectl apply -f mongo-pv.yaml`
* Créer le persistent volume claim. `kubectl apply -f mongo-pvc.yaml`
* Ensuite lancer le reste de déploiement:
    ```bash
    kubectl apply -f fleetman-mongo.yaml
    kubectl apply -f fleetman-api-gateway.yaml
    kubectl apply -f fleetman-queue.yaml
    kubectl apply -f fleetman-position-simulator.yaml
    kubectl apply -f fleetman-position-tracker.yaml
    kubectl apply -f fleetman-web-app.yaml
    ```

