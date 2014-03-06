module Vcloud
  module EdgeGateway
    class NatConfigurationDiffer

        def initialize local, remote
          @local = local
          @remote = remote
          @stripped_local = nil
          @stripped_remote = nil
        end

        def diff
          ( stripped_local_config == stripped_remote_config ) ? [] : HashDiff.diff(stripped_local_config, stripped_remote_config)
        end

        def stripped_local_config
          return @stripped_local unless @stripped_local.nil?
          return nil if @local.nil?
          @stripped_local = strip_id_param_from_nat_rules(@local)
          @stripped_local
        end

        def stripped_remote_config
          return @stripped_remote unless @stripped_remote.nil?
          return nil if @remote.nil?
          @stripped_remote = strip_id_param_from_nat_rules(@remote)
          @stripped_remote
        end

        private

        def strip_id_param_from_nat_rules(config)
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
