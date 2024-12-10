NUM_MASTER_NODE = 1
NUM_WORKER_NODE = 2

IP_NW = "192.168.56."
MASTER_IP_START = 1
NODE_IP_START = 2
Vagrant.configure("2") do |config|
  config.vm.box = "bento/ubuntu-22.04"
  config.vm.box_version = "202407.23.0"
  # Disable automatic box update checking.
  config.vm.box_check_update = false

  # Provision Master Nodes
  (1..NUM_MASTER_NODE).each do |i|
      config.vm.define "master0#{i}" do |node|
        node.vm.provider "virtualbox" do |vb|
            vb.name = "master0#{i}"
            vb.memory = 2048
            vb.cpus = 2
        end
        node.vm.hostname = "master0#{i}"
        node.vm.network :private_network, ip: IP_NW + "#{MASTER_IP_START + i}"
        end
  end

  # Provision Worker Nodes
  (1..NUM_WORKER_NODE).each do |i|
    config.vm.define "worker0#{i}" do |node|
        node.vm.provider "virtualbox" do |vb|
            vb.name = "worker0#{i}"
            vb.memory = 1024
            vb.cpus = 1
        end
        node.vm.hostname = "worker0#{i}"
        node.vm.network :private_network, ip: IP_NW + "#{NODE_IP_START + i}"
        end
  end
end
