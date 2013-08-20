require "chef/knife/glesys_base"

# These two are needed for the '--purge' deletion case
require 'chef/node'
require 'chef/api_client'

class Chef
  class Knife
    class GlesysServerDelete < Knife

      include Knife::GlesysBase

      banner "knife glesys server delete SERVER [SERVER] (options)"

      deps do
        require 'fog'
        require 'readline'
        Chef::Knife::Bootstrap.load_deps
      end

      option :purge,
        :short => "-P",
        :long => "--purge",
        :boolean => true,
        :default => false,
        :description => "Destroy corresponding node and client on the Chef Server, in addition to destroying the Glesys server itself. Assumes node and client have the same name as the server (if not, add the '--node-name' option)."

      option :keepip,
        :short => "-i",
        :long => "--keep-ip",
        :boolean => true,
        :default => false,
        :description => "Don't release the IP"

      option :chef_node_name,
        :short => "-N NAME",
        :long => "--node-name NAME",
        :description => "The name of the node and client to delete, if it differs from the server name.  Only has meaning when used with the '--purge' option."

      # Extracted from Chef::Knife.delete_object, because it has a
      # confirmation step built in... By specifying the '--purge'
      # flag (and also explicitly confirming the server destruction!)
      # the user is already making their intent known.  It is not
      # necessary to make them confirm two more times.
      def destroy_item(klass, name, type_name)
        begin
          object = klass.load(name)
          object.destroy
          ui.warn("Deleted #{type_name} #{name}")
        rescue Net::HTTPServerException
          ui.warn("Could not find a #{type_name} named #{name} to delete!")
        end
      end

      def run
        @name_args.each do |server_id|
          @server = connection.servers.get(server_id)

          print_server_info

          ui.confirm("Do you wan't to delete this server?")

          if config[:keepip]
            server.keepip = config[:keepip]
          end

          server.destroy

          ui.warn("Deleted server #{server_id}")

          if config[:purge]
            thing_to_delete = config[:chef_node_name] || server_id
            destroy_item(Chef::Node, thing_to_delete, "node")
            destroy_item(Chef::ApiClient, thing_to_delete, "client")
          else
            ui.warn("Corresponding node and client for the #{server_id} server were not deleted and remain registered with the Chef Server")
          end
        end

      rescue NoMethodError
        ui.error("Could not locate server '#{server_id}'.")
      end

    end
  end
end
