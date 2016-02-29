require 'spec_helper'
require 'tempfile'

module Vcloud
  describe EdgeGateway::Configure do

    before(:all) do
      config_file = File.join(File.dirname(__FILE__), "../vcloud_tools_testing_config.yaml")
      required_user_params = [
        "edge_gateway",
        "network_1",
        "network_1_id",
        "network_1_ip",
        "provider_network_id",
        "provider_network_ip",
      ]

      @test_params = Vcloud::Tools::Tester::TestSetup.new(config_file, required_user_params).test_params
      @files_to_delete = []
    end

    context "Test NatService specifics" do

      before(:all) do
        reset_edge_gateway
        @vars_config_file = generate_vars_file(edge_gateway_vars_hash)
        @initial_nat_config_file = IntegrationHelper.fixture_file('nat_config.yaml.mustache')
        @edge_gateway = Vcloud::Core::EdgeGateway.get_by_name(@test_params.edge_gateway)
      end

      context "Check update is functional" do

        before(:all) do
          local_config = Core::ConfigLoader.new.load_config(
            @initial_nat_config_file,
            Vcloud::EdgeGateway::Schema::EDGE_GATEWAY_SERVICES,
            @vars_config_file
          )
          @local_vcloud_config  = EdgeGateway::ConfigurationGenerator::NatService.new(
            local_config[:nat_service],
            @edge_gateway.interfaces
          ).generate_fog_config
        end

        it "should be starting our tests from an empty NatService" do
          remote_vcloud_config = @edge_gateway.vcloud_attributes[:Configuration][:EdgeGatewayServiceConfiguration][:NatService]
          expect(remote_vcloud_config[:NatRule].empty?).to be_true
        end

        it "should only make one EdgeGateway update task, to minimise EdgeGateway reload events" do
          pending("This test will fail until https://github.com/fog/fog/pull/3695 is merged and released by Fog")

          last_task = IntegrationHelper.get_last_task(@test_params.edge_gateway)
          diff = EdgeGateway::Configure.new(@initial_nat_config_file, @vars_config_file).update
          tasks_elapsed = IntegrationHelper.get_tasks_since(@test_params.edge_gateway, last_task)

          expect(diff.keys).to eq([:NatService])
          expect(diff[:NatService]).to have_at_least(1).items
          expect(tasks_elapsed).to have(1).items
        end

        it "should have configured at least one NAT rule" do
          pending("This test will fail until https://github.com/fog/fog/pull/3695 is merged and released by Fog")

          remote_vcloud_config = @edge_gateway.vcloud_attributes[:Configuration][:EdgeGatewayServiceConfiguration][:NatService]
          expect(remote_vcloud_config[:NatRule].empty?).to be_false
        end

        it "should have configured the same number of nat rules as in our configuration" do
          pending("This test will fail until https://github.com/fog/fog/pull/3695 is merged and released by Fog")

          remote_vcloud_config = @edge_gateway.vcloud_attributes[:Configuration][:EdgeGatewayServiceConfiguration][:NatService]
          expect(remote_vcloud_config[:NatRule].size).
            to eq(@local_vcloud_config[:NatRule].size)
        end

        it "and then should not configure the firewall service if updated again with the same configuration (idempotency)" do
          pending("This test will fail until https://github.com/fog/fog/pull/3695 is merged and released by Fog")

          expect(Vcloud::Core.logger).to receive(:info).with('EdgeGateway::Configure.update: Configuration is already up to date. Skipping.')
          diff = EdgeGateway::Configure.new(@initial_nat_config_file, @vars_config_file).update

          expect(diff).to eq({})
        end

      end

      context "ensure updated EdgeGateway NatService configuration is as expected" do
        before(:all) do
          @nat_service = @edge_gateway.vcloud_attributes[:Configuration][:EdgeGatewayServiceConfiguration][:NatService]
        end

        it "should configure DNAT rule" do
          pending("This test will fail until https://github.com/fog/fog/pull/3695 is merged and released by Fog")

          dnat_rule = @nat_service[:NatRule].first
          expect(dnat_rule).not_to be_nil
          expect(dnat_rule[:RuleType]).to eq('DNAT')
          expect(dnat_rule[:Id]).to eq('65537')
          expect(dnat_rule[:Description]).to eq('Example DNAT')
          expect(dnat_rule[:IsEnabled]).to eq('true')
          expect(dnat_rule[:GatewayNatRule][:Interface][:href]).to include(@test_params.provider_network_id)
          expect(dnat_rule[:GatewayNatRule][:OriginalIp]).to eq(@test_params.provider_network_ip)
          expect(dnat_rule[:GatewayNatRule][:OriginalPort]).to eq('3412')
          expect(dnat_rule[:GatewayNatRule][:TranslatedIp]).to eq('10.10.1.2-10.10.1.3')
          expect(dnat_rule[:GatewayNatRule][:TranslatedPort]).to eq('3412')
          expect(dnat_rule[:GatewayNatRule][:Protocol]).to eq('tcp')
        end

        it "should configure SNAT rule" do
          pending("This test will fail until https://github.com/fog/fog/pull/3695 is merged and released by Fog")

          snat_rule = @nat_service[:NatRule].last
          expect(snat_rule).not_to be_nil
          expect(snat_rule[:RuleType]).to eq('SNAT')
          expect(snat_rule[:Id]).to eq('65538')
          expect(snat_rule[:Description]).to eq('Example SNAT')
          expect(snat_rule[:IsEnabled]).to eq('true')
          expect(snat_rule[:GatewayNatRule][:Interface][:href]).to include(@test_params.provider_network_id)
          expect(snat_rule[:GatewayNatRule][:OriginalIp]).to eq('10.10.1.2-10.10.1.3')
          expect(snat_rule[:GatewayNatRule][:TranslatedIp]).to eq(@test_params.provider_network_ip)
        end

      end

      context "ensure hairpin NAT rules are specifiable" do

        it "and then should configure hairpin NATting with orgVdcNetwork" do
          vars_file = generate_vars_file({
            edge_gateway_name: @test_params.edge_gateway,
            org_vdc_network_id: @test_params.network_1_id,
            original_ip: @test_params.network_1_ip,
          })

          diff = EdgeGateway::Configure.new(
            IntegrationHelper.fixture_file('hairpin_nat_config.yaml.mustache'),
            vars_file
          ).update

          expect(diff.keys).to eq([:NatService])
          expect(diff[:NatService]).to have_at_least(1).items

          edge_gateway = Vcloud::Core::EdgeGateway.get_by_name(@test_params.edge_gateway)
          nat_service = edge_gateway.vcloud_attributes[:Configuration][:EdgeGatewayServiceConfiguration][:NatService]
          expected_rule = nat_service[:NatRule].first
          expect(expected_rule).not_to be_nil
          expect(expected_rule[:RuleType]).to eq('DNAT')
          expect(expected_rule[:Id]).to eq('65537')
          expect(dnat_rule[:Description]).to eq('Example DNAT')
          expect(expected_rule[:RuleType]).to eq('DNAT')
          expect(expected_rule[:IsEnabled]).to eq('true')
          expect(expected_rule[:GatewayNatRule][:Interface][:name]).to eq(@test_params.network_1)
          expect(expected_rule[:GatewayNatRule][:OriginalIp]).to eq(@test_params.network_1_ip)
          expect(expected_rule[:GatewayNatRule][:OriginalPort]).to eq('3412')
          expect(expected_rule[:GatewayNatRule][:TranslatedIp]).to eq('10.10.1.2')
          expect(expected_rule[:GatewayNatRule][:TranslatedPort]).to eq('3412')
          expect(expected_rule[:GatewayNatRule][:Protocol]).to eq('tcp')
        end

        it "should raise error if network provided in rule does not exist" do
          random_network_id = SecureRandom.uuid
          vars_file = generate_vars_file({
            edge_gateway_name: @test_params.edge_gateway,
            network_id: random_network_id,
            original_ip: @test_params.network_1_ip,
          })

          expect {
            EdgeGateway::Configure.new(
              IntegrationHelper.fixture_file('nat_config.yaml.mustache'),
              vars_file
            ).update
          }.to raise_error("unable to find gateway network interface with id #{random_network_id}")
        end
      end

      after(:all) do
        IntegrationHelper.remove_temp_config_files(@files_to_delete)
      end

      def reset_edge_gateway
        edge_gateway = Core::EdgeGateway.get_by_name @test_params.edge_gateway
        edge_gateway.update_configuration({
          NatService: {:IsEnabled => "true", :NatRule => []},
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
          :edge_gateway_name => @test_params.edge_gateway,
          :network_id => @test_params.provider_network_id,
          :original_ip => @test_params.provider_network_ip,
        }
      end
    end

  end
end
