module Vcloud
  module EdgeGateway
    class FirewallConfigurationDiffer < ConfigurationDiffer

        def strip_unused_field_from_config(config)
          deep_cloned_config = Marshal.load( Marshal.dump(config) )
          if deep_cloned_config.key?(:FirewallRule)
            deep_cloned_config[:FirewallRule].each do |firewall_rule|
              firewall_rule.delete(:Id)
            end
          end
          deep_cloned_config
        end

    end
  end

end
