# -*- mode: ruby -*-
# vi: set ft=ruby :

# Vagrantfile API/syntax version. Don't touch unless you know what you're doing!
VAGRANTFILE_API_VERSION = "2"

# YAML Module
require 'yaml'

# Defaults
$memory = 1024
$cpus = 2
$box = "cloudhotspot/ubuntu"

# Inventory file
$stack = YAML.load_file('vagrant.yml') || {}

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|
  # Disable new SSH key generation - appears to solve similar issue to https://github.com/test-kitchen/kitchen-vagrant/issues/130
  config.ssh.insert_key = false

  # Fix for https://github.com/mitechellh/vagrant/issues/1673
  config.ssh.shell = "bash -c 'BASH_ENV=/etc/profile exec bash'"

  $stack.each do |key,values|
    config.vm.define key do |config|
      config.vm.box = values["box"] || $box
      config.vm.hostname = key

      # VMWare Fusion Settings
      config.vm.provider "vmware_fusion" do |v|
        v.vmx["memsize"] = values["memory"] || $memory
        v.vmx["numvcpus"] = values["cpu"] || $cpus
      end

      # Virtualbox Settings
      config.vm.provider "virtualbox" do |v|
        v.memory = $memory
        v.cpus = $cpus
      end

      # Network Settings
      if values["ip"]
        config.vm.network "private_network", ip: values["ip"]
      end

      # Folders
      folders = values["folders"] || []
      folders.each do |folder| 
        config.vm.synced_folder folder["host"], folder["guest"], type: folder["type"]
      end

      # Shell Provisioner
      shell = values["shell_provisioner"]
      if shell
        shell.each do |sh|
          sh.each do |sh_key,sh_value|
            config.vm.provision "shell", sh_key.to_sym => sh_value
          end
        end
      end

      # Docker Provisioner
      provisioner = values["docker_provisioner"]  
      if provisioner
        config.vm.provision "docker" do |d|
          run = provisioner["run"] || []
          run.each do |r|
            d.run r["name"], image: r["image"], args: r["args"], cmd: r["cmd"], daemonize: r["daemonize"] || true
          end
        end
      end
    end
  end

  # Add guests to host hosts file
  # config.hostmanager.enabled = true
  config.vm.provision :hostmanager
  config.hostmanager.manage_host = true
end
