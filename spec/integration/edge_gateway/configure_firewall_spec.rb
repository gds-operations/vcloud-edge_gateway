require 'spec_helper'
require 'tempfile'

module Vcloud
  describe EdgeGateway::Configure do

    before(:all) do
      config_file = File.join(File.dirname(__FILE__), "../vcloud_tools_testing_config.yaml")
      @test_data = Vcloud::Tools::Tester::TestParameters.new(config_file)
      @edge_name = @test_data.edge_gateway
      @ext_net_id = @test_data.provider_network_id
      @ext_net_ip = @test_data.provider_network_ip
      @ext_net_name = @test_data.provider_network
      @int_net_id = @test_data.network_1_id
      @int_net_ip = @test_data.network_1_ip
      @int_net_name = @test_data.network_1
      @files_to_delete = []
    end

    context "Test FirewallService specifics" do

      before(:all) do
        reset_edge_gateway
        @vars_config_file = generate_vars_file(edge_gateway_vars_hash)
        @initial_firewall_config_file = IntegrationHelper.fixture_file('firewall_config.yaml.mustache')
        @edge_gateway = Vcloud::Core::EdgeGateway.get_by_name(@edge_name)
        @firewall_service = {}
      end

      context "Check update is functional" do

        before(:all) do
          local_config = Core::ConfigLoader.new.load_config(
            @initial_firewall_config_file,
            Vcloud::EdgeGateway::Schema::EDGE_GATEWAY_SERVICES,
            @vars_config_file
          )
          @local_vcloud_config  = EdgeGateway::ConfigurationGenerator::FirewallService.new.generate_fog_config(local_config[:firewall_service])
        end

        it "should be starting our tests from an empty firewall" do
          remote_vcloud_config = @edge_gateway.vcloud_attributes[:Configuration][:EdgeGatewayServiceConfiguration][:FirewallService]
          expect(remote_vcloud_config[:FirewallRule].empty?).to be_true
        end

        it "should only need to make one call to Core::EdgeGateway.update_configuration" do
          expect_any_instance_of(Core::EdgeGateway).to receive(:update_configuration).exactly(1).times.and_call_original
          EdgeGateway::Configure.new(@initial_firewall_config_file, @vars_config_file).update
        end

        it "should have configured at least one firewall rule" do
          remote_vcloud_config = @edge_gateway.vcloud_attributes[:Configuration][:EdgeGatewayServiceConfiguration][:FirewallService]
          expect(remote_vcloud_config[:FirewallRule].empty?).to be_false
        end

        it "should have configured the same number of firewall rules as in our configuration" do
          remote_vcloud_config = @edge_gateway.vcloud_attributes[:Configuration][:EdgeGatewayServiceConfiguration][:FirewallService]
          expect(remote_vcloud_config[:FirewallRule].size).
            to eq(@local_vcloud_config[:FirewallRule].size)
        end

        it "and then should not configure the firewall service if updated again with the same configuration (idempotency)" do
          expect(Vcloud::Core.logger).to receive(:info).with('EdgeGateway::Configure.update: Configuration is already up to date. Skipping.')
          EdgeGateway::Configure.new(@initial_firewall_config_file, @vars_config_file).update
        end

        it "ConfigurationDiffer should return empty if local and remote firewall configs match" do
          remote_vcloud_config = @edge_gateway.vcloud_attributes[:Configuration][:EdgeGatewayServiceConfiguration][:FirewallService]
          differ = EdgeGateway::ConfigurationDiffer.new(@local_vcloud_config, remote_vcloud_config)
          diff_output = differ.diff
          expect(diff_output).to eq([])
        end

        it "should highlight a difference if local firewall config has been updated" do
          local_config = Core::ConfigLoader.new.load_config(
            IntegrationHelper.fixture_file('firewall_config_updated_rule.yaml.mustache'),
            Vcloud::EdgeGateway::Schema::EDGE_GATEWAY_SERVICES,
            @vars_config_file
          )
          local_firewall_config = EdgeGateway::ConfigurationGenerator::FirewallService.new.generate_fog_config(local_config[:firewall_service])

          edge_gateway = Core::EdgeGateway.get_by_name local_config[:gateway]
          remote_config = edge_gateway.vcloud_attributes[:Configuration][:EdgeGatewayServiceConfiguration]
          remote_firewall_config = remote_config[:FirewallService]

          differ = EdgeGateway::ConfigurationDiffer.new(local_firewall_config, remote_firewall_config)
          diff_output = differ.diff

          expect(diff_output.empty?).to be_false
        end

      end

      context "ensure EdgeGateway FirewallService configuration is as expected" do
        before(:all) do
          @firewall_service = @edge_gateway.vcloud_attributes[:Configuration][:EdgeGatewayServiceConfiguration][:FirewallService]
        end

        it "should configure firewall rule with destination and source ip addresses" do
          expect(@firewall_service[:FirewallRule].first).to eq({:Id => "1",
                                                                :IsEnabled => "true",
                                                                :MatchOnTranslate => "false",
                                                                :Description => "A rule",
                                                                :Policy => "allow",
                                                                :Protocols => {:Tcp => "true"},
                                                                :Port => "-1",
                                                                :DestinationPortRange => "Any",
                                                                :DestinationIp => "10.10.1.2",
                                                                :SourcePort => "-1",
                                                                :SourcePortRange => "Any",
                                                                :SourceIp => "192.0.2.2",
                                                                :EnableLogging => "false"})
        end

        it "should configure firewall rule with destination and source ip ranges" do
          expect(@firewall_service[:FirewallRule].last).to eq({:Id => "2",
                                                               :IsEnabled => "true",
                                                               :MatchOnTranslate => "false",
                                                               :Description => "",
                                                               :Policy => "allow",
                                                               :Protocols => {:Tcp => "true"},
                                                               :Port => "-1",
                                                               :DestinationPortRange => "Any",
                                                               :DestinationIp => "10.10.1.3-10.10.1.5",
                                                               :SourcePort => "-1",
                                                               :SourcePortRange => "Any",
                                                               :SourceIp => "192.0.2.2/24",
                                                               :EnableLogging => "false"})
        end

      end

      context "Specific FirewallService update tests" do

        it "should have the same rule order as the input rule order" do
          EdgeGateway::Configure.new(
            IntegrationHelper.fixture_file('firewall_rule_order_test.yaml.mustache'),
            @vars_config_file
          ).update
          remote_rules = @edge_gateway.vcloud_attributes[:Configuration][:EdgeGatewayServiceConfiguration][:FirewallService][:FirewallRule]
          remote_descriptions_list = remote_rules.map {|rule| rule[:Description]}
          expect(remote_descriptions_list).
            to eq([
              "First Input Rule",
              "Second Input Rule",
              "Third Input Rule",
              "Fourth Input Rule",
              "Fifth Input Rule"
              ])
        end

      end

      after(:all) do
        reset_edge_gateway unless ENV['VCLOUD_NO_RESET_VSE_AFTER']
        @files_to_delete.each { |f|
          f.unlink
        }
      end

      def reset_edge_gateway
        edge_gateway = Core::EdgeGateway.get_by_name @edge_name
        edge_gateway.update_configuration({
          FirewallService: {IsEnabled: false, FirewallRule: []},
        })
      end

      def generate_vars_file(vars_hash)
        file = Tempfile.new('vars_file')
        file.write(vars_hash.to_yaml)
        file.close
        @files_to_delete << file

        file.path
      end

      def edge_gateway_vars_hash
        {
          :edge_gateway_name => @edge_name,
          :edge_gateway_ext_network_id => @ext_net_id,
          :edge_gateway_ext_network_ip => @ext_net_ip,
        }
      end

    end

  end
end
