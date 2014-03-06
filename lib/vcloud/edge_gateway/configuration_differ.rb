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
          @local
        end

        def stripped_remote_config
          @remote
        end

    end
  end

end
