module Vcloud
  module EdgeGateway
    class GatewayIpsecVpnConfigurationDiffer < ConfigurationDiffer

      def strip_fields_for_differ_to_ignore(config)
        deep_cloned_config = Marshal.load( Marshal.dump(config) )
        if deep_cloned_config.key?(:GatewayIpsecVpnService)
          deep_cloned_config[:GatewayIpsecVpnService].each do |vpn|
            vpn.delete(:Id)
          end
        end
        deep_cloned_config
      end

    end
  end

end
