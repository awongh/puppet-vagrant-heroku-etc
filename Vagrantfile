# -*- mode: ruby -*-
# vi: set ft=ruby :
box_name = "36-puppet-test"

Vagrant::Config.run do |config|
    config.vm.host_name = "#{box_name}"
    config.vm.box = "#{box_name}"

    config.vm.forward_port 3000, 80

    # share a local code folder for editing in a native env
    config.vm.share_folder "#{box_name}", "/code", "/code/vagrant/#{box_name}", :create=>true

    # share your home folder so that you can grab shell configs into the vm
    config.vm.share_folder "local-home", "/local-home", "/Users/akira"

    # turn on the path to the shared home folder configs
    config.vm.provision :puppet do |puppet|
        # set paths
        puppet.manifests_path = "puppet/manifests"
        puppet.module_path = "puppet/modules"

        puppet.options = "--verbose --debug --fileserverconfig=/code/vagrant/fileserver.conf"
        #puppet.options = "--fileserverconfig=/code/vagrant/fileserver.conf"
    end
end 
