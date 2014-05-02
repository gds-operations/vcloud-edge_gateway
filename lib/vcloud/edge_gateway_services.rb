require 'hashdiff'

module Vcloud
  class EdgeGatewayServices

    def initialize
      @config_loader = Vcloud::Core::ConfigLoader.new
    end

    def update(config_file = nil)
      local_config = @config_loader.load_config(config_file, Vcloud::Schema::EDGE_GATEWAY_SERVICES)

      edge_gateway = Core::EdgeGateway.get_by_name local_config[:gateway]
      remote_config = edge_gateway.vcloud_attributes[:Configuration][:EdgeGatewayServiceConfiguration]
      edge_gateway_interface_list = edge_gateway.interfaces

      proposed_config = EdgeGateway::EdgeGatewayConfiguration.new(
        local_config,
        remote_config,
        edge_gateway_interface_list
      )

      if proposed_config.update_required?
        edge_gateway.update_configuration proposed_config.config
      else
        Vcloud::Core.logger.info("EdgeGatewayServices.update: Configuration is already up to date. Skipping.")
      end
    end

  end
end
