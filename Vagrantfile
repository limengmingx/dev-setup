# -*- mode: ruby -*-
# vi: set ft=ruby :

options = {
  :ip => "10.10.10.100",
  :scriptDir => "setup",
  :testDir => "test"
}

Vagrant.configure("2") do |config|

  # Use [omnibus plugin](https://github.com/schisamo/vagrant-omnibus) 
  # to use the omnibus installer to install [chef](http://www.opscode.com/chef/)
  # Install plugin: `vagrant plugin install vagrant-omnibus`
  config.omnibus.chef_version = :latest

  # VM name
  config.vm.hostname = "stucco"

  # Every Vagrant virtual environment requires a box to build off of.
  config.vm.box = "precise-server-cloudimg-amd64-vagrant-disk1"

  # The url from where the 'config.vm.box' box will be fetched if it
  # doesn't already exist on the user's system.
  # Ubuntu cloud images, including virtual box images for vagrant, can
  # be found here: http://cloud-images.ubuntu.com/
  config.vm.box_url = "http://cloud-images.ubuntu.com/vagrant/precise/current/precise-server-cloudimg-amd64-vagrant-disk1.box"

  # Create a forwarded port mapping which allows access to a specific port
  # within the machine from a port on the host machine.
  # config.vm.network :forwarded_port, guest: 5672, host: 5672
  # No port forwarding, use private network IP to connect to VM

  # Create a public network, which generally matched to bridged network.
  # Bridged networks make the machine appear as another physical device on
  # your network.
  config.vm.network :public_network

  # Create a private network, which allows host-only access to the machine
  # using a specific IP.
  config.vm.network :private_network, ip: "#{options[:ip]}"

  # Mount the parent directory under /stucco-shared in the VM
  # All project repos should be in the parent dir
  config.vm.synced_folder "../", "/stucco-shared"

  # Provider-specific configuration so you can fine-tune various
  # backing providers for Vagrant. These expose provider-specific options.
  
  # Use VBoxManage to customize the VM. Change memory and limit VM's CPU.
  config.vm.provider :virtualbox do |vb|
    vb.customize ["modifyvm", :id, "--memory", "4096"]
    vb.customize ["modifyvm", :id, "--cpuexecutioncap", "60"]
  end
  

  # Update package list, but do not do upgrade. Upgrades should
  # be done manually, if required (`sudo apt-get upgrade`)
  config.vm.provision :shell, :inline => "echo 'Running apt-get update' ; sudo apt-get update"

  # Recommended for riak
  config.vm.provision :shell, :inline => "echo 'Increasing ulimit for Riak' ; ulimit -n 64000"

  # Install required packages
  config.vm.provision :chef_solo do |chef|
    chef.json = {

      # The apt cookbook uses port 11371 to connect to the keyserver, but this
      # port is often blocked. To force apt to use port 80 we need to specify
      # a keyserver proxy. Setting this to " " is sufficient.
      "apt" => {
        "key_proxy" => " " # one space so it is not empty
      },

      "ntp" => {
        "servers" => ["0.us.pool.ntp.org", "1.us.pool.ntp.org", "2.us.pool.ntp.org"]
      },

      # use Oracle Java JDK instead of default OpenJDK
      "java" => {
        "install_flavor" => 'oracle',
        "jdk_version" => 7,
        "oracle" => {
          "accept_oracle_download_terms" => true
        }
      },

      # set up riak to use the configured IP address
      "riak" => {
        "args" => {
          "-name" => "riak@#{options[:ip]}"
        },
        "config" => {
          "riak_core" => {
            "http" => {
              "__string_#{options[:ip]}" => 8098
            }
          },
          "riak_api" => {
            "pb_ip" => "__string_#{options[:ip]}"
          }
        }
      },

      "elasticsearch" => {
        "cluster_name" => "stucco-es",
        "bootstrap.mlockall" => false
      },

      "logstash" => {
        "basedir" => "/usr/local/logstash",
        "server" => {
          "version" => "1.3.2",
          "enable_embedded_es" => false,
          "install_rabbitmq" => false,
          "inputs" => [
            "file" => {
              "type" => "stucco-rt",
              "path" => "/stucco/rt/logstash.log",
              "exclude" => "*.gz",
              "charset" => "UTF-8",
              "format" => "json_event"
            },
            "tcp" => {
              "type" => "stucco-tcp",
              "port" => 9563,
              "charset" => "UTF-8",
              "format" => "json_event"
            }
          ],
          "outputs" => [
            "elasticsearch_http" => {
              "host" => "localhost",
              "port" => 9200,
              "flush_size" => 1
            }
          ]
        }
      },

      "kibana" => {
        "repo" => "https://github.com/elasticsearch/kibana",
        "installdir" => "/usr/local/kibana",
        "es_server" => "#{options[:ip]}",
        "es_port" => 9200,
        "webserver" => "nginx",
        "webserver_listen" => "0.0.0.0",
        "webserver_port" => 8000
      },

      "nodejs" => {
        "version" => "0.10.24"
      },

      "etcd" => {
        "version" => "0.2.0"
      }      

    }

    chef.add_recipe "ntp"
    chef.add_recipe "git"
    chef.add_recipe "chef-sbt"
    chef.add_recipe "python"
    chef.add_recipe "java"
    chef.add_recipe "zookeeper"
    chef.add_recipe "rabbitmq"
    chef.add_recipe "riak"
    chef.add_recipe "elasticsearch"
    chef.add_recipe "logstash::server"
    chef.add_recipe "kibana"
    chef.add_recipe "nodejs::install_from_package"
    chef.add_recipe "nodejs::npm"
    chef.add_recipe "etcd"
  end

  # Install [Storm](http://storm-project.net/), passing version as argument
  config.vm.provision :shell do |shell|
    shell.path = "#{options[:scriptDir]}/storm.sh"
    shell.args = "0.9.0.1"
  end

  # Install [Titan](http://thinkaurelius.github.io/titan/), passing version as argument if needed
  config.vm.provision :shell do |shell|
    shell.path = "#{options[:scriptDir]}/titan.sh"
    shell.args = "0.4.2"
  end

  # Get stucco
  config.vm.provision "shell", path: "#{options[:scriptDir]}/stucco.sh"

  # Run stucco tests
  config.vm.provision "shell", path: "#{options[:testDir]}/run-tests.sh"

end
