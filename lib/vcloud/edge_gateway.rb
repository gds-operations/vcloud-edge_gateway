require 'vcloud/edge_gateway/version'

require 'vcloud/core'
require 'vcloud/fog'

require 'vcloud/config_loader'

require 'vcloud/edge_gateway_services'

require 'vcloud/schema/nat_service'
require 'vcloud/schema/firewall_service'
require 'vcloud/schema/load_balancer_service'
require 'vcloud/schema/edge_gateway'

require 'vcloud/edge_gateway/configuration_generator/id_ranges'
require 'vcloud/edge_gateway/configuration_generator/firewall_service'
require 'vcloud/edge_gateway/configuration_generator/nat_service'
require 'vcloud/edge_gateway/configuration_generator/load_balancer_service'
require 'vcloud/edge_gateway/configuration_differ'
require 'vcloud/edge_gateway/load_balancer_configuration_differ'
require 'vcloud/edge_gateway/edge_gateway_configuration'


module Vcloud
  module EdgeGateway

    def self.logger
      @logger ||=Logger.new(STDOUT)
    end

  end
end
