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

    context "Test NatService specifics" do

      before(:all) do
        reset_edge_gateway
        @vars_config_file = generate_vars_file(edge_gateway_vars_hash)
        @initial_nat_config_file = IntegrationHelper.fixture_file('nat_config.yaml.mustache')
        @edge_gateway = Vcloud::Core::EdgeGateway.get_by_name(@edge_name)
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
          start_time = Time.now.getutc
          task_list_before_update = get_all_edge_gateway_update_tasks_ordered_by_start_date_since_time(start_time)
          EdgeGateway::Configure.new(@initial_nat_config_file, @vars_config_file).update
          task_list_after_update = get_all_edge_gateway_update_tasks_ordered_by_start_date_since_time(start_time)
          expect(task_list_after_update.size - task_list_before_update.size).to be(1)
        end

        it "should have configured at least one NAT rule" do
          remote_vcloud_config = @edge_gateway.vcloud_attributes[:Configuration][:EdgeGatewayServiceConfiguration][:NatService]
          expect(remote_vcloud_config[:NatRule].empty?).to be_false
        end

        it "should have configured the same number of nat rules as in our configuration" do
          remote_vcloud_config = @edge_gateway.vcloud_attributes[:Configuration][:EdgeGatewayServiceConfiguration][:NatService]
          expect(remote_vcloud_config[:NatRule].size).
            to eq(@local_vcloud_config[:NatRule].size)
        end

        it "ConfigurationDiffer should return empty if local and remote nat configs match" do
          remote_vcloud_config = @edge_gateway.vcloud_attributes[:Configuration][:EdgeGatewayServiceConfiguration][:NatService]
          differ = EdgeGateway::ConfigurationDiffer.new(@local_vcloud_config, remote_vcloud_config)
          diff_output = differ.diff
          expect(diff_output).to eq([])
        end

        it "and then should not configure the firewall service if updated again with the same configuration (idempotency)" do
          expect(Vcloud::Core.logger).to receive(:info).with('EdgeGateway::Configure.update: Configuration is already up to date. Skipping.')
          EdgeGateway::Configure.new(@initial_nat_config_file, @vars_config_file).update
        end

      end

      context "ensure updated EdgeGateway NatService configuration is as expected" do
        before(:all) do
          @nat_service = @edge_gateway.vcloud_attributes[:Configuration][:EdgeGatewayServiceConfiguration][:NatService]
        end

        it "should configure DNAT rule" do
          dnat_rule = @nat_service[:NatRule].first
          expect(dnat_rule).not_to be_nil
          expect(dnat_rule[:RuleType]).to eq('DNAT')
          expect(dnat_rule[:Id]).to eq('65537')
          expect(dnat_rule[:IsEnabled]).to eq('true')
          expect(dnat_rule[:GatewayNatRule][:Interface][:href]).to include(@ext_net_id)
          expect(dnat_rule[:GatewayNatRule][:OriginalIp]).to eq(@ext_net_ip)
          expect(dnat_rule[:GatewayNatRule][:OriginalPort]).to eq('3412')
          expect(dnat_rule[:GatewayNatRule][:TranslatedIp]).to eq('10.10.1.2-10.10.1.3')
          expect(dnat_rule[:GatewayNatRule][:TranslatedPort]).to eq('3412')
          expect(dnat_rule[:GatewayNatRule][:Protocol]).to eq('tcp')
        end

        it "should configure SNAT rule" do
          snat_rule = @nat_service[:NatRule].last
          expect(snat_rule).not_to be_nil
          expect(snat_rule[:RuleType]).to eq('SNAT')
          expect(snat_rule[:Id]).to eq('65538')
          expect(snat_rule[:IsEnabled]).to eq('true')
          expect(snat_rule[:GatewayNatRule][:Interface][:href]).to include(@ext_net_id)
          expect(snat_rule[:GatewayNatRule][:OriginalIp]).to eq('10.10.1.2-10.10.1.3')
          expect(snat_rule[:GatewayNatRule][:TranslatedIp]).to eq(@ext_net_ip)
        end

      end

      context "ensure hairpin NAT rules are specifiable" do

        it "and then should configure hairpin NATting with orgVdcNetwork" do
          vars_file = generate_vars_file({
            edge_gateway_name: @edge_name,
            org_vdc_network_id: @int_net_id,
            original_ip: @int_net_ip,
          })

          EdgeGateway::Configure.new(
            IntegrationHelper.fixture_file('hairpin_nat_config.yaml.mustache'),
            vars_file
          ).update

          edge_gateway = Vcloud::Core::EdgeGateway.get_by_name(@edge_name)
          nat_service = edge_gateway.vcloud_attributes[:Configuration][:EdgeGatewayServiceConfiguration][:NatService]
          expected_rule = nat_service[:NatRule].first
          expect(expected_rule).not_to be_nil
          expect(expected_rule[:RuleType]).to eq('DNAT')
          expect(expected_rule[:Id]).to eq('65537')
          expect(expected_rule[:RuleType]).to eq('DNAT')
          expect(expected_rule[:IsEnabled]).to eq('true')
          expect(expected_rule[:GatewayNatRule][:Interface][:name]).to eq(@int_net_name)
          expect(expected_rule[:GatewayNatRule][:OriginalIp]).to eq(@int_net_ip)
          expect(expected_rule[:GatewayNatRule][:OriginalPort]).to eq('3412')
          expect(expected_rule[:GatewayNatRule][:TranslatedIp]).to eq('10.10.1.2')
          expect(expected_rule[:GatewayNatRule][:TranslatedPort]).to eq('3412')
          expect(expected_rule[:GatewayNatRule][:Protocol]).to eq('tcp')
        end

        it "should raise error if network provided in rule does not exist" do
          random_network_id = SecureRandom.uuid
          vars_file = generate_vars_file({
            edge_gateway_name: @edge_name,
            network_id: random_network_id,
            original_ip: @int_net_ip,
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
        edge_gateway = Core::EdgeGateway.get_by_name @edge_name
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
          :edge_gateway_name => @edge_name,
          :network_id => @ext_net_id,
          :original_ip => @ext_net_ip,
        }
      end

      def get_all_edge_gateway_update_tasks_ordered_by_start_date_since_time(timestamp)
        vcloud_time = timestamp.strftime('%FT%T.000Z')
        q = Vcloud::Core::QueryRunner.new
        q.run('task',
          :filter => "name==networkConfigureEdgeGatewayServices;objectName==#{@edge_name};startDate=ge=#{vcloud_time}",
          :sortDesc => 'startDate',
        )
      end

    end

  end
end
