module Vcloud
  module EdgeGateway
    class LoadBalancerConfigurationDiffer < ConfigurationDiffer

        def stripped_remote_config
          return @stripped_remote unless @stripped_remote.nil?
          return nil if @remote.nil?
          @stripped_remote = strip_operational_field_from_config(@remote)
          @stripped_remote
        end

        private

        def strip_operational_field_from_config(config)
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
