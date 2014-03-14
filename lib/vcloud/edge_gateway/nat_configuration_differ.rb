module Vcloud
  module EdgeGateway
    class NatConfigurationDiffer < ConfigurationDiffer

        def strip_unused_field_from_config(config)
          deep_cloned_config = Marshal.load( Marshal.dump(config) )
          if deep_cloned_config.key?(:NatRule)
            deep_cloned_config[:NatRule].each do |nat_rule|
              nat_rule.delete(:Id)
            end
          end
          deep_cloned_config
        end

    end
  end

end
