# vi: set ft=ruby :
VAGRANTFILE_API_VERSION = "2"

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|
  config.vm.box = "ubuntu/trusty64"
  config.vm.provision 'shell', path: 'script.sh' # A script.
  config.vm.provider "virtualbox" do 
    |vb|
    vb.customize ["modifyvm", :id, "--memory", "1024"]
  end
 
end
