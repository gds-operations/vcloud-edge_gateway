module Vcloud
  module EdgeGateway
    class LoadBalancerConfigurationDiffer < ConfigurationDiffer

        def strip_unused_field_from_config(config)
          deep_cloned_remote_config = Marshal.load( Marshal.dump(config) )
          if deep_cloned_remote_config.key?(:Pool)
            deep_cloned_remote_config[:Pool].each do |pool_entry|
              pool_entry.delete(:Operational)
            end
          end
          deep_cloned_remote_config
        end

    end
  end

end
