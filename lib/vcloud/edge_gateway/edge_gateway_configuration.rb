module Vcloud
  module EdgeGateway
    class EdgeGatewayConfiguration

      attr_reader :config, :diff

      def initialize(local_config, remote_config, edge_gateway_interfaces)
        @config, @diff = generate_new_config(local_config, remote_config, edge_gateway_interfaces)
      end

      def update_required?
        @config.any?
      end

      private
      def generate_new_config(local_config, remote_config, edge_gateway_interfaces)
        new_config = { }
        diff = { }

        firewall_service_config =
          EdgeGateway::ConfigurationGenerator::FirewallService.new.
            generate_fog_config(local_config[:firewall_service])

        unless firewall_service_config.nil?
          differ = EdgeGateway::FirewallConfigurationDiffer.new(
            remote_config[:FirewallService],
            firewall_service_config
          )
          unless differ.diff.empty?
            diff[:FirewallService] = differ.diff
            new_config[:FirewallService] = firewall_service_config
          end
        end

        nat_service_config = EdgeGateway::ConfigurationGenerator::NatService.new(
          local_config[:nat_service],
          edge_gateway_interfaces
        ).generate_fog_config

        unless nat_service_config.nil?
          differ = EdgeGateway::NatConfigurationDiffer.new(
            remote_config[:NatService],
            nat_service_config
          )
          unless differ.diff.empty?
            diff[:NatService] = differ.diff
            new_config[:NatService] = nat_service_config
          end
        end

        load_balancer_service_config =
          EdgeGateway::ConfigurationGenerator::LoadBalancerService.new(
            edge_gateway_interfaces
          ).generate_fog_config(local_config[:load_balancer_service])

        unless load_balancer_service_config.nil?
          differ = EdgeGateway::LoadBalancerConfigurationDiffer.new(
            remote_config[:LoadBalancerService],
            load_balancer_service_config
          )
          unless differ.diff.empty?
            diff[:LoadBalancerService] = differ.diff
            new_config[:LoadBalancerService] = load_balancer_service_config
          end
        end

        static_routing_service_config = EdgeGateway::ConfigurationGenerator::StaticRoutingService.new(
          local_config[:static_routing_service],
          edge_gateway_interfaces
        ).generate_fog_config

        unless static_routing_service_config.nil?
          differ = EdgeGateway::StaticRoutingConfigurationDiffer.new(
            remote_config[:StaticRoutingService],
            static_routing_service_config
          )
          unless differ.diff.empty?
            diff[:StaticRoutingService] = differ.diff
            new_config[:StaticRoutingService] = static_routing_service_config
          end
        end
        return new_config, diff
      end

    end
  end
end
