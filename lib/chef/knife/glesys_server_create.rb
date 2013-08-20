require "chef/knife/glesys_base"

class Chef
  class Knife
    class GlesysServerCreate < Knife

      include Knife::GlesysBase

      banner "knife glesys server create (options)"

      deps do
        require 'fog'
        require 'readline'
        require 'chef/json_compat'
        require 'chef/knife/bootstrap'
        Chef::Knife::Bootstrap.load_deps
      end

      option :image,
        :short => "-i IMAGE",
        :long => "--image IMAGE",
        :description => "The image to use on the server (Debian 6.0 64-bit, Ubuntu, etc)",
        :proc => Proc.new { |f| Chef::Config[:knife][:image] = f },
        :required => true

      option :platform,
        :short => "-p PLATFORM",
        :long => "--platform PLATFORM",
        :description => "The platform to launch the server on (Xen or OpenVZ)",
        :proc => Proc.new { |f| Chef::Config[:knife][:platform] = f },
        :required => true

      option :datacenter,
        :long => "--data-center DATACENTER",
        :description => "The data center to launch the server in (Falkenberg, New York, Amsterdam or Stockholm)",
        :proc => Proc.new { |f| Chef::Config[:knife][:datacenter] = f },
        :required => true

      option :rootpassword,
        :short => "-P PASSWORD",
        :long => "--root-password PASSWORD",
        :description => "Root password to set on the new server",
        :required => true

      option :hostname,
        :short => "-h HOSTNAME",
        :long => "--hostname HOSTNAME",
        :hostname => "Server hostname",
        :required => true

      option :cpucores,
        :long => "--cpu-cores CPUCORES",
        :description => "The number cpu cores (1-8)",
        :proc => Proc.new { |f| Chef::Config[:knife][:cpucores] = f }

      option :memorysize,
        :long => "--memory-size MEMORY",
        :description => "The amount of memory (128mb - 16384mb)",
        :proc => Proc.new { |f| Chef::Config[:knife][:memorysize] = f }

      option :disksize,
        :long => "--disk-size DISK",
        :description => "The amount of disk (5gb-100gb)",
        :proc => Proc.new { |f| Chef::Config[:knife][:disksize] = f }

      option :transfer,
        :long        => "--transfer TRANSFER",
        :description => "Transfer (50gb - 10000gb)",
        :proc        => Proc.new { |f| Chef::Config[:knife][:transfer] = f }

      option :chef_node_name,
        :short => "-N NAME",
        :long => "--node-name NAME",
        :description => "Chef node name",
        :proc        => Proc.new { |f| Chef::Config[:knife][:chef_node_name] = f }

      option :description,
        :short => "-D DESCRIPTION",
        :long => "--description DESCRIPTION",
        :description => "Server description"

      option :ipv4,
        :long => "--ipv4 IP",
        :hostname => "IPV4 to assign the server"

      option :ipv6,
        :long => "--ipv6 IP",
        :hostname => "IPV6 to assign the server"

      option :run_list,
        :short => "-r RUN_LIST",
        :long => "--run-list RUN_LIST",
        :description => "Comma separated list of roles/recipes to apply",
        :proc => lambda { |o| o.split(/[\s,]+/) }

      option :ssh_gateway,
        :short => "-w GATEWAY",
        :long => "--ssh-gateway GATEWAY",
        :description => "The SSH gateway server",
        :proc => Proc.new { |key| Chef::Config[:knife][:ssh_gateway] = key }

      option :ssh_port,
        :short => "-o PORT",
        :long => "--ssh-port PORT",
        :default => "22",
        :description => "SSH Port",
        :proc => Proc.new { |key| Chef::Config[:knife][:ssh_port] = key }

      option :json_attributes,
        :short => "-j JSON",
        :long => "--json-attributes JSON",
        :description => "A JSON string to be added to the first run of chef-client",
        :proc => lambda { |o| JSON.parse(o) }

      def tcp_test_ssh(hostname, ssh_port)
        tcp_socket = TCPSocket.new(hostname, ssh_port)
        readable = IO.select([tcp_socket], nil, nil, 5)
        if readable
          Chef::Log.debug("sshd accepting connections on #{hostname}, banner is #{tcp_socket.gets}")
          yield
          true
        else
          false
        end
      rescue SocketError, Errno::ECONNREFUSED, Errno::EHOSTUNREACH, Errno::ENETUNREACH, IOError
        sleep 2
        false
      rescue Errno::EPERM, Errno::ETIMEDOUT
        false
      ensure
        tcp_socket && tcp_socket.close
      end

      def run
        validate!

        default_server = create_server_def
        @server = connection.servers.create default_server

        # Show information about the new server
        print_server_info

        # Waiting for server to boot
        print "\nBooting"
        @server.wait_for{ print "."; ready? }

        # Waiting for sshd to start
        wait_for_sshd(@server.public_ip_address)

        # Bootstrap the node
        bootstrap_for_node(@server,@server.public_ip_address).run

        print_server_info

        msg_pair("Environment", config[:environment] || '_default')
        msg_pair("Run List", (config[:run_list] || []).join(', '))
        msg_pair("JSON Attributes", config[:json_attributes]) unless !config[:json_attributes] || config[:json_attributes].empty?
      end

      def create_server_def
        default_server = {
          templatename: locate_config_value(:image),
          datacenter: locate_config_value(:datacenter),
          platform: locate_config_value(:platform),
          memorysize: locate_config_value(:memorysize),
          disksize: locate_config_value(:disksize),
          cpucores: locate_config_value(:cpucores),
          transfer: locate_config_value(:transfer),
          description: config[:description],
          hostname: config[:hostname],
          rootpassword: config[ :rootpassword ]
        }

        default_server
      end

      def bootstrap_for_node(server,ssh_host)
        bootstrap = Chef::Knife::Bootstrap.new
        bootstrap.name_args = [ssh_host]
        bootstrap.config[:run_list] = locate_config_value(:run_list) || []
        bootstrap.config[:ssh_user] = "root"
        bootstrap.config[:ssh_port] = config[:ssh_port]
        bootstrap.config[:ssh_password] = server.rootpassword
        bootstrap.config[:ssh_gateway] = config[:ssh_gateway]
        bootstrap.config[:use_sudo] = false
        # bootstrap.config[:identity_file] = config[:identity_file]
        bootstrap.config[:chef_node_name] = locate_config_value(:chef_node_name) || server.serverid
        bootstrap.config[:prerelease] = config[:prerelease]
        bootstrap.config[:bootstrap_version] = locate_config_value(:bootstrap_version)
        bootstrap.config[:first_boot_attributes] = locate_config_value(:json_attributes) || {}
        bootstrap.config[:distro] = locate_config_value(:distro) || "chef-full"
        bootstrap.config[:template_file] = locate_config_value(:template_file)
        bootstrap.config[:environment] = config[:environment]

        # knife-bootstrap
        Chef::Config[:knife][:hints] ||= {}
        Chef::Config[:knife][:hints]["glesys"] ||= {}
        bootstrap
      end

      def wait_for_sshd(hostname)
        config[:ssh_gateway] ? wait_for_tunnelled_sshd(hostname) : wait_for_direct_sshd(hostname, config[:ssh_port])
      end

      def wait_for_tunnelled_sshd(hostname)
        print("\nWaiting for sshd tunnel.")
        print(".") until tunnel_test_ssh(ssh_connect_host) {
          sleep @initial_sleep_delay ||= (vpc_mode? ? 40 : 10)
          puts("done")
        }
      end

      def tunnel_test_ssh(hostname, &block)
        gw_host, gw_user = config[:ssh_gateway].split('@').reverse
        gw_host, gw_port = gw_host.split(':')
        gateway = Net::SSH::Gateway.new(gw_host, gw_user, :port => gw_port || 22)
        status = false
        gateway.open(hostname, config[:ssh_port]) do |local_tunnel_port|
          status = tcp_test_ssh('localhost', local_tunnel_port, &block)
        end
        status
      rescue SocketError, Errno::ECONNREFUSED, Errno::EHOSTUNREACH, Errno::ENETUNREACH, IOError
        sleep 2
        false
      rescue Errno::EPERM, Errno::ETIMEDOUT
        false
      end

      def wait_for_direct_sshd(hostname, ssh_port)
        print "\nWaiting for ssh."
        print(".") until tcp_test_ssh(ssh_connect_host, ssh_port) {
          puts "done"
        }
      end

      def ssh_connect_host
        @server.public_ip_address
      end
    end
  end
end
