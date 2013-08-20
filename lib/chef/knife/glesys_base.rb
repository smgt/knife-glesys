require "chef/knife"

class Chef
  class Knife
    module GlesysBase

      attr_reader :server

      def self.included(includer)
        includer.class_eval do

          deps do
            require 'fog'
            require 'readline'
            require 'chef/json_compat'
          end

          option :glesys_api_key,
            :short => "-A KEY",
            :long => "--glesys-api-key KEY",
            :description => "Your Glesys API key",
            :proc => Proc.new { |key| Chef::Config[:knife][:glesys_api_key] = key }

          option :glesys_username,
            :short => "-U USERNAME",
            :long => "--glesys-username USERNAME",
            :description => "Your Glesysusername",
            :proc => Proc.new { |key| Chef::Config[:knife][:glesys_username] = key }
        end
      end

      def connection
        @connection ||= begin
          connection = Fog::Compute.new(
            :provider        => 'Glesys',
            :glesys_api_key  => Chef::Config[:knife][:glesys_api_key],
            :glesys_username => Chef::Config[:knife][:glesys_username],
          )
        end
      end

      def msg_pair(label, value, color=:cyan)
        if value && !value.to_s.empty?
          puts "#{ui.color(label, color)}: #{value}"
        end
      end

      def locate_config_value(key)
        key = key.to_sym
        config[key] || Chef::Config[:knife][key]
      end

      def color_state(state)

        return ui.color("unknown", :cyan) if state.nil?

        case state.to_s.downcase
          when 'shutting-down','terminated','stopping','stopped' then ui.color(state, :red)
          when 'pending', 'locked' then ui.color(state, :yellow)
          else ui.color(state, :green)
        end

      end

      def validate!
      end

      def print_server_info
        puts "\n"
        msg_pair("Server ID", server.serverid)
        state = case server.state.to_s.downcase
          when 'shutting-down','terminated','stopping','stopped' then ui.color(server.state, :red)
          when 'pending' then ui.color(server.state, :yellow)
          else ui.color(server.state, :green)
        end
        msg_pair("State", ui.color(state,:bold))
        msg_pair("Hostname", server.hostname)
        msg_pair("Description", server.description) if server.respond_to? :description # When fog supports description
        puts "\n"

        [4, 6].each do |ver|
          msg_pair("IPv#{ver}", server.iplist.select{|i| i["version"] == ver}.collect{|i| i["ipaddress"]}.join(", "))          
        end
        puts "\n"
        msg_pair("CPU Cores", server.cpucores)
        msg_pair("Memory", "#{server.memorysize} MB")
        msg_pair("Disk", "#{server.disksize} GB")
        puts "\n"
        msg_pair("Template", server.templatename)
        msg_pair("Platform", server.platform)
        msg_pair("Datacenter", server.datacenter)
        puts "\n"

        if server.usage
          msg(ui.color("Current Usage:",:bold))
          msg_pair("Transfer", "#{ui.color(server.usage['transfer']['usage'].to_s, :yellow)} of #{server.usage['transfer']['max']} #{server.usage['transfer']['unit']}")
          msg_pair("Memory", "#{ui.color(server.usage['memory']['usage'].to_s, :yellow)} of #{server.usage['memory']['max']} #{server.usage['memory']['unit']}")
          msg_pair("CPU", "#{ui.color(server.usage['cpu']['usage'].to_s, :yellow)} of #{server.usage['cpu']['max']} #{server.usage['cpu']['unit']}")
          msg_pair("Disk", "#{ui.color(server.usage['disk']['usage'].to_s, :yellow)} of #{server.usage['disk']['max']} #{server.usage['disk']['unit']}")
          msg_pair("Cost", "#{ui.color(server.cost['amount'].to_s, :yellow)} #{server.cost['currency']} per #{server.cost['timeperiod']}")
          puts "\n"
        end

      end

    end
  end
end
