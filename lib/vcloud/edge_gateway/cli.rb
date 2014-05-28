require 'optparse'

module Vcloud
  module EdgeGateway
    class Cli
      def initialize(argv_array)
        @usage_text = nil
        @config_file = nil
        @options = {
          :template_vars => nil,
          :validate_only => false,
        }

        parse(argv_array)
      end

      def run
        config_args = [@config_file]
        if @options[:template_vars]
          config_args << @options[:template_vars]
        end

        vse = Vcloud::EdgeGateway::Configure.new(*config_args)
        unless @options.fetch(:validate_only)
          vse.update
        end
      end

      private

      def parse(args)
        opt_parser = OptionParser.new do |opts|
          opts.banner = <<-EOS
Usage: #{$0} [options] config_file

vcloud-edge_gateway allows you to configure an EdgeGateway with an input
file which may optionally be a Mustache template.

See https://github.com/alphagov/vcloud-edge_gateway for more info
          EOS

          opts.separator ""
          opts.separator "Options:"

          opts.on("--template-vars FILE", "Enable templating with variables from this file") do |f|
            @options[:template_vars] = f
          end

          opts.on("--validate", "Validate config_file against schema and exit") do
            @options[:validate_only] = true
          end

          opts.on("-h", "--help", "Print usage and exit") do
            $stderr.puts opts
            exit
          end

          opts.on("--version", "Display version and exit") do
            puts Vcloud::EdgeGateway::VERSION
            exit
          end
        end

        @usage_text = opt_parser.to_s
        begin
          opt_parser.parse!(args)
        rescue OptionParser::InvalidOption => e
          exit_error_usage(e)
        end

        exit_error_usage("must supply config_file") unless args.size == 1
        @config_file = args.first
      end

      def exit_error_usage(error)
        $stderr.puts "#{$0}: #{error}"
        $stderr.puts @usage_text
        exit 2
      end
    end
  end
end
