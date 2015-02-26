require 'spec_helper'
require 'tempfile'

module Vcloud
  describe EdgeGateway::Configure do

    before(:all) do
      config_file = File.join(File.dirname(__FILE__), "../vcloud_tools_testing_config.yaml")
      required_user_params = [
        "edge_gateway",
        "provider_network",
        "provider_network_default_gateway"
      ]

      @test_params = Vcloud::Tools::Tester::TestSetup.new(config_file, required_user_params).test_params
      @files_to_delete = []
    end

    context "Test StaticRoutingService specifics" do

      before(:all) do
        reset_edge_gateway
        @vars_config_file = generate_vars_file(edge_gateway_vars_hash)
        @initial_static_routing_config_file = IntegrationHelper.fixture_file('static_routing_config.yaml.mustache')
        @edge_gateway = Vcloud::Core::EdgeGateway.get_by_name(@test_params.edge_gateway)
      end

      context "Check update is functional" do

        before(:all) do
          local_config = Core::ConfigLoader.new.load_config(
            @initial_static_routing_config_file,
            Vcloud::EdgeGateway::Schema::EDGE_GATEWAY_SERVICES,
            @vars_config_file
          )
          @local_vcloud_config  = EdgeGateway::ConfigurationGenerator::StaticRoutingService.new(
            local_config[:static_routing_service],
            @edge_gateway.interfaces
          ).generate_fog_config
        end

        it "should be starting our tests from an empty StaticRoutingService" do
          edge_service_config = @edge_gateway.vcloud_attributes[:Configuration][:EdgeGatewayServiceConfiguration]
          remote_vcloud_config = edge_service_config[:StaticRoutingService]
          if remote_vcloud_config
            expect(remote_vcloud_config[:StaticRoute].nil?).to be_true
          end
        end

        it "should only make one EdgeGateway update task, to minimise EdgeGateway reload events" do
          start_time = Time.now.getutc
          task_list_before_update = get_all_edge_gateway_update_tasks_ordered_by_start_date_since_time(start_time)
          diff = EdgeGateway::Configure.new(@initial_static_routing_config_file, @vars_config_file).update
          task_list_after_update = get_all_edge_gateway_update_tasks_ordered_by_start_date_since_time(start_time)

          expect(diff.keys).to eq([:StaticRoutingService])
          expect(diff[:StaticRoutingService]).to have_at_least(1).items
          expect(task_list_after_update.size - task_list_before_update.size).to be(1)
        end

        it "should have configured at least one static route" do
          edge_service_config = @edge_gateway.vcloud_attributes[:Configuration][:EdgeGatewayServiceConfiguration]
          remote_vcloud_config = edge_service_config[:StaticRoutingService]
          expect(remote_vcloud_config[:StaticRoute].empty?).to be_false
        end

        it "should have configured the same number of static routes as in our configuration" do
          edge_service_config = @edge_gateway.vcloud_attributes[:Configuration][:EdgeGatewayServiceConfiguration]
          remote_vcloud_config = edge_service_config[:StaticRoutingService]
          expect(remote_vcloud_config[:StaticRoute].size).
            to eq(@local_vcloud_config[:StaticRoute].size)
        end


        it "should not then configure the StaticRoutingService if updated again with the same configuration" do
          expect(Vcloud::Core.logger).to receive(:info).
            with('EdgeGateway::Configure.update: Configuration is already up to date. Skipping.')
          diff = EdgeGateway::Configure.new(@initial_static_routing_config_file, @vars_config_file).update

          expect(diff).to eq({})
        end

      end

      context "Check specific StaticRoutingService update cases" do

        it "should be able to configure with no static routes" do
          config_file = IntegrationHelper.fixture_file('static_routing_empty.yaml.mustache')
          diff = EdgeGateway::Configure.new(config_file, @vars_config_file).update
          edge_config = @edge_gateway.vcloud_attributes[:Configuration]
          remote_vcloud_config = edge_config[:EdgeGatewayServiceConfiguration][:StaticRoutingService]

          expect(diff.keys).to eq([:StaticRoutingService])
          expect(diff[:StaticRoutingService]).to have_at_least(1).items
          expect(remote_vcloud_config[:StaticRoute].nil?).to be_true
        end

      end

      after(:all) do
        IntegrationHelper.remove_temp_config_files(@files_to_delete)
      end

      def reset_edge_gateway
        edge_gateway = Core::EdgeGateway.get_by_name @test_params.edge_gateway
        edge_gateway.update_configuration({
          StaticRoutingService: {
            IsEnabled: "false",
            StaticRoute: []
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
          :edge_gateway_name => @test_params.edge_gateway,
          :edge_gateway_ext_network_name => @test_params.provider_network,
          :edge_gateway_ext_default_gateway => @test_params.provider_network_default_gateway
        }
      end

      def get_all_edge_gateway_update_tasks_ordered_by_start_date_since_time(timestamp)
        vcloud_time = timestamp.strftime('%FT%T.000Z')
        q = Vcloud::Core::QueryRunner.new
        q.run('task',
          :filter =>
            "name==networkConfigureEdgeGatewayServices;objectName==#{@test_params.edge_gateway};startDate=ge=#{vcloud_time}",
          :sortDesc => 'startDate',
        )
      end

    end

  end
end
