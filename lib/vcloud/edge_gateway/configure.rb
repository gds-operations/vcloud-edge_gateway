module Vcloud
  module EdgeGateway
    class Configure

      def initialize(config_file = nil, vars_file = nil)
        config_loader = Vcloud::Core::ConfigLoader.new
        @local_config = config_loader.load_config(config_file, Vcloud::EdgeGateway::Schema::EDGE_GATEWAY_SERVICES, vars_file)
      end

      def update
        edge_gateway = Vcloud::Core::EdgeGateway.get_by_name @local_config[:gateway]
        remote_config = edge_gateway.vcloud_attributes[:Configuration][:EdgeGatewayServiceConfiguration]
        edge_gateway_interface_list = edge_gateway.interfaces

        proposed_config = Vcloud::EdgeGateway::EdgeGatewayConfiguration.new(
          @local_config,
          remote_config,
          edge_gateway_interface_list
        )

        if proposed_config.update_required?
          edge_gateway.update_configuration proposed_config.config
        else
          Vcloud::Core.logger.info("EdgeGateway::Configure.update: Configuration is already up to date. Skipping.")
        end

        proposed_config.diff
      end

    end
  end
end
