# -*- mode: ruby -*-
# vi: set ft=ruby :

RAM = 8196
VCPUS = 4

# If host can take it, give vm some more mem+cpu
# RAM = 16384
# VCPUS = 32

$tweak_disk = <<SCRIPT
sgdisk -e /dev/vda
yes | parted /dev/vda ---pretend-input-tty resizepart 4 100%
btrfs filesystem resize max /
SCRIPT

$completed_msg = <<SCRIPT
echo 'Provisioning completed'
echo 'Use "vagrant ssh" to access vagrant vm'
echo 'Then, call "~/start_cluster.sh" to start kind cluster'
echo 'Then, call "~/run_robocni.sh -h" for options on running robocni'
SCRIPT

Vagrant.configure("2") do |config|
  vm_memory = ENV['VM_MEMORY'] || RAM
  vm_cpus = ENV['VM_CPUS'] || VCPUS

  config.vm.box = "fedora/40-cloud-base"

  # libvirt
  config.vm.provider "libvirt" do |lv, override|
    lv.cpus = vm_cpus
    lv.memory = vm_memory
    lv.nested = true
    # Set the primary disk size to 100 GB
    lv.machine_virtual_size = 100
  end

  # Add bridged network interface to fedora vm
  # config.vm.network "public_network",
  #                   :dev => "bridge0",
  #                   :mode => "bridge",
  #                   :type => "bridge",
  #                   use_dhcp_assigned_default_route: true

  # config.hostmanager.enabled = true
  # config.hostmanager.manage_host = true
  # config.hostmanager.manage_guest = true
  # config.ssh.forward_agent = true

  config.vm.hostname = "fedora"
  # Uncomment one of these to mount host folder from vm
  # config.vm.synced_folder "#{ENV['PWD']}", "/vagrant", type: "sshfs"
  # config.vm.synced_folder "#{ENV['PWD']}", "/vagrant", type: "nfs", nfs_udp: false, nfs_udp: false

  # config.vm.provision :shell do |shell|
  #   shell.privileged = true
  #   shell.path = 'provision/checkNested.sh'
  # end

  config.vm.provision "tweak_disk", type: "shell",
                      inline: $tweak_disk

  config.vm.provision :shell do |shell|
    shell.privileged = false
    shell.path = 'provision/setup.sh'
  end

  config.vm.provision :shell do |shell|
    shell.privileged = false
    shell.path = 'provision/start_local_ollama.sh'
  end

  config.vm.provision "completed_msg", type: "shell",
                      inline: $completed_msg

end
