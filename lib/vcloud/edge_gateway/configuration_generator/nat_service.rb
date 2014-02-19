module Vcloud
  module EdgeGateway
    module ConfigurationGenerator

      class NatService
        def initialize input_config, edge_gateway_interfaces
          @input_config = input_config
          @edge_gateway_interfaces = edge_gateway_interfaces
        end

        def generate_fog_config
          if @input_config
            nat_service = {}
            nat_service[:IsEnabled] = @input_config.key?(:enabled) ? @input_config[:enabled].to_s : 'true'
            nat_service[:NatRule] = populate_nat_rules
            nat_service
          end
        end

        def populate_nat_rules
          rules = @input_config[:nat_rules]
            i = ID_RANGES::NAT_SERVICE[:min]
            rules.collect do |rule|
              new_rule = {}
              new_rule[:Id] = rule.key?(:id) ? rule[:id] : i.to_s
              new_rule[:IsEnabled] = rule.key?(:enabled) ? rule[:enabled].to_s : 'true'
              new_rule[:RuleType] = rule[:rule_type]
              gateway_nat_rule = populate_gateway_nat_rule(rule)
              new_rule[:GatewayNatRule] = gateway_nat_rule
              i += 1
              new_rule
          end
        end

        def populate_gateway_nat_rule(rule)
          raise "Must supply a :network_id parameter" unless net_id = rule[:network_id]
          edge_gw_interface = @edge_gateway_interfaces.find do |interface|
            interface.network_id == net_id
          end
          raise "unable to find gateway network interface with id #{net_id}" unless edge_gw_interface
          gateway_nat_rule = {}
          gateway_nat_rule[:Interface] = populate_nat_interface(edge_gw_interface)
          gateway_nat_rule[:OriginalIp] = rule[:original_ip]
          gateway_nat_rule[:TranslatedIp] = rule[:translated_ip]
          gateway_nat_rule[:OriginalPort] = rule[:original_port] if rule.key?(:original_port)
          gateway_nat_rule[:TranslatedPort] = rule[:translated_port] if rule.key?(:translated_port)
          if rule[:rule_type] == 'DNAT'
            gateway_nat_rule[:Protocol] = rule.key?(:protocol) ? rule[:protocol] : "tcp"
          end
          gateway_nat_rule
        end

        def populate_nat_interface(edge_interface)
          vcloud_interface = {}
          vcloud_interface[:type] = 'application/vnd.vmware.admin.network+xml'
          vcloud_interface[:name] = edge_interface.network_name
          vcloud_interface[:href] = edge_interface.network_href
          vcloud_interface
        end

      end
    end
  end
end
