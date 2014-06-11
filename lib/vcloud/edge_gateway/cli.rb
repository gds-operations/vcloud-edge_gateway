require 'optparse'

module Vcloud
  module EdgeGateway
    class Cli
      ANSI_RESET = "\033[0m"
      ANSI_RED   = "\033[31m"
      ANSI_GREEN = "\033[32m"

      def initialize(argv_array)
        @usage_text = nil
        @config_file = nil
        @options = {
          :template_vars => nil,
          :colour => STDOUT.tty?,
          :dry_run => nil,
        }

        parse(argv_array)
      end

      def run
        config_args = [@config_file]
        if @options[:template_vars]
          config_args << @options[:template_vars]
        end

        update_args = []
        if @options[:dry_run]
          update_args << @options[:dry_run]
        end

        conf = Vcloud::EdgeGateway::Configure.new(*config_args)
        diff = conf.update(*update_args)
        puts render_diff(diff)
      end

      private

      def parse(args)
        opt_parser = OptionParser.new do |opts|
          opts.banner = <<-EOS
Usage: #{$0} [options] config_file

vcloud-edge_gateway allows you to configure an EdgeGateway with an input
file which may optionally be a Mustache template.

It will always output a diff of the changes between the remote config and
your local config.

See https://github.com/gds-operations/vcloud-edge_gateway for more info
          EOS

          opts.separator ""
          opts.separator "Options:"

          opts.on("--dry-run", "Don't apply configuration changes") do
            @options[:dry_run] = true
          end

          opts.on("--template-vars FILE", "Enable templating with variables from this file") do |f|
            @options[:template_vars] = f
          end

          opts.on("--[no-]colour", "Disable/enable colour output. Enabled by default unless output is redirected") do |c|
            @options[:colour] = c
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

      def render_diff(diff)
        lines = diff.collect { |service_name, service_diff|
          service_diff.collect { |diff_tuple|
            key = "#{service_name}.#{diff_tuple[1]}"
            case diff_tuple[0]
            when "-"
              diff_line_rem(key, diff_tuple[2])
            when "+"
              diff_line_add(key, diff_tuple[2])
            when "~"
              [
                diff_line_rem(key, diff_tuple[2]),
                diff_line_add(key, diff_tuple[3]),
              ]
            end
          }
        }

        lines.join("\n")
      end

      def diff_line_add(key, value)
        line = "+ #{key}: #{value}"
        if @options.fetch(:colour)
          line = "#{ANSI_GREEN}#{line}#{ANSI_RESET}"
        end

        line
      end

      def diff_line_rem(key, value)
        line = "- #{key}: #{value}"
        if @options.fetch(:colour)
          line = "#{ANSI_RED}#{line}#{ANSI_RESET}"
        end

        line
      end
    end
  end
end
