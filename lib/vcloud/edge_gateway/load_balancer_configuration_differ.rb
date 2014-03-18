module Vcloud
  module EdgeGateway
    class LoadBalancerConfigurationDiffer < ConfigurationDiffer

        def strip_fields_for_differ_to_ignore(config)
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
