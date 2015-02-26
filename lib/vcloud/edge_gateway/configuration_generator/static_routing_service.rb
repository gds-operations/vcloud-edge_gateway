module Vcloud
  module EdgeGateway
    module ConfigurationGenerator

      class StaticRoutingService
        def initialize input_config, edge_gateway_interfaces
          @input_config = input_config
          @edge_gateway_interfaces = edge_gateway_interfaces
        end

        def generate_fog_config
          return nil unless @input_config
          {
            IsEnabled:   routing_enabled?,
            StaticRoute: generate_static_route_section
          }
        end

        def generate_static_route_section
          routes = @input_config[:static_routes]
          return [] if routes.nil?
          routes.collect do |route|
            route[:enabled] ||= 'true'
            {
              Name:             route[:name],
              Network:          route[:network],
              NextHopIp:        route[:next_hop],
              IsEnabled:        route[:enabled],
              GatewayInterface: generate_gateway_interface_section(route[:apply_on])

            }
          end
        end

        def generate_gateway_interface_section(network_name)
          egw_interface = find_egw_interface(network_name)
          raise "unable to find gateway network interface with id #{network_id}" unless egw_interface

          {
            type: "application/vnd.vmware.vcloud.orgVdcNetwork+xml",
            name: egw_interface.network_name,
            href: egw_interface.network_href
          }
        end

        def routing_enabled?
            return 'false' unless @input_config
            @input_config.key?(:enabled) ? @input_config[:enabled].to_s : 'true'
        end

        def find_egw_interface(network_name)
          @edge_gateway_interfaces.find{|i| i.network_name == network_name}
        end

      end
    end
  end
end
