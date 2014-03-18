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
          strip_fields_for_differ_to_ignore(@local) unless @local.nil?
        end

        def stripped_remote_config
          strip_fields_for_differ_to_ignore(@remote) unless @remote.nil?
        end

        def strip_fields_for_differ_to_ignore(config)
          config
        end

    end
  end

end
