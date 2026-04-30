Vagrant.configure("2") do |config|
  config.vm.box = "ubuntu/jammy64"

  # VM 1 - SeaweedFS
  config.vm.define "seaweedfs-node" do |seaweedfs|
    seaweedfs.vm.hostname = "seaweedfs-node"
    seaweedfs.vm.network "private_network", ip: "192.168.56.101"

    seaweedfs.vm.provider "virtualbox" do |vb|
      vb.name = "seaweedfs-node"
      vb.memory = 3072
      vb.cpus = 2
    end
  end

  # VM 2 - Trino
  config.vm.define "trino-sea-node" do |trino|
    trino.vm.hostname = "trino-sea-node"
    trino.vm.network "private_network", ip: "192.168.56.102"
    trino.vm.network "forwarded_port", guest: 8080, host: 8080
    
    trino.vm.provider "virtualbox" do |vb|
      vb.name = "trino-sea-node"
      vb.memory = 4096
      vb.cpus = 2
    end
  end

  # Garante que as VMs se conheçam sem pedir confirmação manual
  config.vm.provision "shell", inline: "echo 'StrictHostKeyChecking no' >> /etc/ssh/ssh_config"

end