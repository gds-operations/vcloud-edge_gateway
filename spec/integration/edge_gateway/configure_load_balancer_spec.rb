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

    context "Test LoadBalancerService specifics" do

      before(:all) do
        reset_edge_gateway
        @vars_config_file = generate_vars_file(edge_gateway_vars_hash)
        @initial_load_balancer_config_file = IntegrationHelper.fixture_file('load_balancer_config.yaml.mustache')
        @edge_gateway = Vcloud::Core::EdgeGateway.get_by_name(@edge_name)
      end

      context "Check update is functional" do

        before(:all) do
          local_config = Core::ConfigLoader.new.load_config(
            @initial_load_balancer_config_file,
            Vcloud::EdgeGateway::Schema::EDGE_GATEWAY_SERVICES,
            @vars_config_file
          )
          @local_vcloud_config  = EdgeGateway::ConfigurationGenerator::LoadBalancerService.new(
            @edge_gateway.interfaces
          ).generate_fog_config(local_config[:load_balancer_service])
        end

        it "should be starting our tests from an empty LoadBalancerService" do
          edge_service_config = @edge_gateway.vcloud_attributes[:Configuration][:EdgeGatewayServiceConfiguration]
          remote_vcloud_config = edge_service_config[:LoadBalancerService]
          expect(remote_vcloud_config[:Pool].empty?).to be_true
          expect(remote_vcloud_config[:VirtualServer].empty?).to be_true
        end

        it "should only make one EdgeGateway update task, to minimise EdgeGateway reload events" do
          start_time = Time.now.getutc
          task_list_before_update = get_all_edge_gateway_update_tasks_ordered_by_start_date_since_time(start_time)
          EdgeGateway::Configure.new(@initial_load_balancer_config_file, @vars_config_file).update
          task_list_after_update = get_all_edge_gateway_update_tasks_ordered_by_start_date_since_time(start_time)
          expect(task_list_after_update.size - task_list_before_update.size).to be(1)
        end

        it "should have configured at least one LoadBancer Pool entry" do
          edge_service_config = @edge_gateway.vcloud_attributes[:Configuration][:EdgeGatewayServiceConfiguration]
          remote_vcloud_config = edge_service_config[:LoadBalancerService]
          expect(remote_vcloud_config[:Pool].empty?).to be_false
        end

        it "should have configured at least one LoadBancer VirtualServer entry" do
          edge_service_config = @edge_gateway.vcloud_attributes[:Configuration][:EdgeGatewayServiceConfiguration]
          remote_vcloud_config = edge_service_config[:LoadBalancerService]
          expect(remote_vcloud_config[:VirtualServer].empty?).to be_false
        end

        it "should have configured the same number of Pools as in our configuration" do
          edge_service_config = @edge_gateway.vcloud_attributes[:Configuration][:EdgeGatewayServiceConfiguration]
          remote_vcloud_config = edge_service_config[:LoadBalancerService]
          expect(remote_vcloud_config[:Pool].size).
            to eq(@local_vcloud_config[:Pool].size)
        end

        it "should have configured the same number of VirtualServers as in our configuration" do
          edge_service_config = @edge_gateway.vcloud_attributes[:Configuration][:EdgeGatewayServiceConfiguration]
          remote_vcloud_config = edge_service_config[:LoadBalancerService]
          expect(remote_vcloud_config[:VirtualServer].size).
            to eq(@local_vcloud_config[:VirtualServer].size)
        end

        it "ConfigurationDiffer should return empty if local and remote LoadBalancer configs match" do
          edge_service_config = @edge_gateway.vcloud_attributes[:Configuration][:EdgeGatewayServiceConfiguration]
          remote_vcloud_config = edge_service_config[:LoadBalancerService]
          differ = EdgeGateway::LoadBalancerConfigurationDiffer.new(@local_vcloud_config, remote_vcloud_config)
          diff_output = differ.diff
          expect(diff_output).to eq([])
        end

        it "should not then configure the LoadBalancerService if updated again with the same configuration" do
          expect(Vcloud::Core.logger).
            to receive(:info).with('EdgeGateway::Configure.update: Configuration is already up to date. Skipping.')
          EdgeGateway::Configure.new(@initial_load_balancer_config_file, @vars_config_file).update
        end

      end

      context "Check specific LoadBalancerService update cases" do

        it "should be able to configure with no pools and virtual_servers" do
          config_file = IntegrationHelper.fixture_file('load_balancer_empty.yaml.mustache')
          EdgeGateway::Configure.new(config_file, @vars_config_file).update
          edge_config = @edge_gateway.vcloud_attributes[:Configuration]
          remote_vcloud_config = edge_config[:EdgeGatewayServiceConfiguration][:LoadBalancerService]
          expect(remote_vcloud_config[:Pool].size).to be == 0
          expect(remote_vcloud_config[:VirtualServer].size).to be == 0
        end

        it "should be able to configure with a single Pool and no VirtualServers" do
          config_file = IntegrationHelper.fixture_file('load_balancer_single_pool.yaml.mustache')
          EdgeGateway::Configure.new(config_file, @vars_config_file).update
          edge_config = @edge_gateway.vcloud_attributes[:Configuration]
          remote_vcloud_config = edge_config[:EdgeGatewayServiceConfiguration][:LoadBalancerService]
          expect(remote_vcloud_config[:Pool].size).to be == 1
        end

        it "should raise an error when trying configure with a single VirtualServer, and no pool mentioned" do
          config_file = IntegrationHelper.fixture_file('load_balancer_single_virtual_server_missing_pool.yaml.mustache')
          expect { EdgeGateway::Configure.new(config_file, @vars_config_file).update }.
            to raise_error('Supplied configuration does not match supplied schema')
        end

        it "should raise an error when trying configure with a single VirtualServer, with an unconfigured pool" do
          config_file = IntegrationHelper.fixture_file('load_balancer_single_virtual_server_invalid_pool.yaml.mustache')
          expect { EdgeGateway::Configure.new(config_file, @vars_config_file).update }.
            to raise_error(
              'Load balancer virtual server integration-test-vs-1 does not have a valid backing pool.'
            )
        end

      end

      after(:all) do
        @files_to_delete.each { |f|
          f.unlink
        }
      end

      def reset_edge_gateway
        edge_gateway = Core::EdgeGateway.get_by_name @edge_name
        edge_gateway.update_configuration({
          LoadBalancerService: {
            IsEnabled: "false",
            Pool: [],
            VirtualServer: []
          }
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

      def get_all_edge_gateway_update_tasks_ordered_by_start_date_since_time(timestamp)
        vcloud_time = timestamp.strftime('%FT%T.000Z')
        q = Vcloud::Core::QueryRunner.new
        q.run('task',
          :filter =>
            "name==networkConfigureEdgeGatewayServices;objectName==#{@edge_name};startDate=ge=#{vcloud_time}",
          :sortDesc => 'startDate',
        )
      end

    end

  end
end
