module Vcloud
  module EdgeGateway
    class ConfigurationDiffer

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
          @stripped_local = strip_unused_field_from_config(@local)
          @stripped_local
        end

        def stripped_remote_config
          return @stripped_remote unless @stripped_remote.nil?
          return nil if @remote.nil?
          @stripped_remote = strip_unused_field_from_config(@remote)
          @stripped_remote
        end

        def strip_unused_field_from_config(config)
          config
        end

    end
  end

end
