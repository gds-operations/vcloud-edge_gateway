module Vcloud
  module EdgeGateway
    class ConfigurationDiffer

        def initialize local, remote
          @local = local
          @remote = remote
        end

        def diff
          ( stripped_local_config == stripped_remote_config ) ? [] : HashDiff.diff(stripped_local_config, stripped_remote_config)
        end

        def stripped_local_config
          strip_unused_field_from_config(@local) unless @local.nil?
        end

        def stripped_remote_config
          strip_unused_field_from_config(@remote) unless @remote.nil?
        end

        def strip_unused_field_from_config(config)
          config
        end

    end
  end

end
