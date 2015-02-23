module Vcloud
  module EdgeGateway
    class StaticRoutingConfigurationDiffer < ConfigurationDiffer
      def strip_fields_for_differ_to_ignore(config)
        remote_cfg = Marshal.load(Marshal.dump(config))
        if remote_cfg.key?(:StaticRoute)
          remote_cfg[:StaticRoute].each do |route_rule|
            route_rule.delete(:IsEnabled)
          end
        end
        remote_cfg
      end
    end
  end

end
