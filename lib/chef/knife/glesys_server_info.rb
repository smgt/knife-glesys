require "chef/knife/glesys_base"

class Chef
  class Knife
    class GlesysServerInfo < Knife

      include Knife::GlesysBase

      banner "knife glesys server info SERVER"

      deps do
        require 'fog'
        require 'readline'
        Chef::Knife::Bootstrap.load_deps
      end

      def run
        @server = connection.servers.get(@name_args.first)
        print_server_info
      end

    end
  end
end
