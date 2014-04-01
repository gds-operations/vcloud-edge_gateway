require 'spec_helper'

module Vcloud
  describe EdgeGatewayServices do

    required_env = {
      'VCLOUD_EDGE_GATEWAY' => 'to name of VSE',
      'VCLOUD_PROVIDER_NETWORK_ID' => 'to ID of VSE external network',
      'VCLOUD_PROVIDER_NETWORK_IP' => 'to an available IP on VSE external network',
      'VCLOUD_NETWORK1_ID' => 'to the ID of a VSE internal network',
      'VCLOUD_NETWORK1_NAME' => 'to the name of the VSE internal network',
      'VCLOUD_NETWORK1_IP' => 'to an ID on the VSE internal network',
    }

    error = false
    required_env.each do |var,message|
      unless ENV[var]
        puts "Must set #{var} #{message}" unless ENV[var]
        error = true
      end
    end
    Kernel.exit(2) if error

    before(:all) do
      @edge_name = ENV['VCLOUD_EDGE_GATEWAY']
      @ext_net_id = ENV['VCLOUD_PROVIDER_NETWORK_ID']
      @ext_net_ip = ENV['VCLOUD_PROVIDER_NETWORK_IP']
      @ext_net_name = ENV['VCLOUD_PROVIDER_NETWORK_NAME']
      @int_net_id = ENV['VCLOUD_NETWORK1_ID']
      @int_net_ip = ENV['VCLOUD_NETWORK1_IP']
      @int_net_name = ENV['VCLOUD_NETWORK1_NAME']
      @files_to_delete = []
    end

    context "Test EdgeGatewayServices with multiple services" do

      before(:all) do
        reset_edge_gateway
        @initial_config_file = generate_input_config_file(
          'nat_and_firewall_config.yaml.erb',
          edge_gateway_erb_input
        )
        @adding_load_balancer_config_file = generate_input_config_file(
          'nat_and_firewall_plus_load_balancer_config.yaml.erb',
          edge_gateway_erb_input
        )
        @edge_gateway = Vcloud::Core::EdgeGateway.get_by_name(@edge_name)
      end

      context "Check update is functional" do

        it "should be starting our tests from an empty EdgeGateway" do
          remote_vcloud_config = @edge_gateway.vcloud_attributes[:Configuration][:EdgeGatewayServiceConfiguration]
          expect(remote_vcloud_config[:FirewallService][:FirewallRule].empty?).to be_true
          expect(remote_vcloud_config[:NatService][:NatRule].empty?).to be_true
          expect(remote_vcloud_config[:LoadBalancerService][:Pool].empty?).to be_true
          expect(remote_vcloud_config[:LoadBalancerService][:VirtualServer].empty?).to be_true
        end

        it "should only create one edgeGateway update task when updating the configuration" do
          start_time = Time.now.getutc
          task_list_before_update = get_all_edge_gateway_update_tasks_ordered_by_start_date_since_time(start_time)
          EdgeGatewayServices.new.update(@initial_config_file)
          task_list_after_update = get_all_edge_gateway_update_tasks_ordered_by_start_date_since_time(start_time)
          expect(task_list_after_update.size - task_list_before_update.size).to be(1)
        end

        it "should now have nat and firewall rules configured, no load balancer yet" do
          remote_vcloud_config = @edge_gateway.vcloud_attributes[:Configuration][:EdgeGatewayServiceConfiguration]
          expect(remote_vcloud_config[:FirewallService][:FirewallRule].empty?).to be_false
          expect(remote_vcloud_config[:NatService][:NatRule].empty?).to be_false
          expect(remote_vcloud_config[:LoadBalancerService][:Pool].empty?).to be(true)
          expect(remote_vcloud_config[:LoadBalancerService][:VirtualServer].empty?).to be(true)
        end

        it "should not update the EdgeGateway again if the config hasn't changed" do
          start_time = Time.now.getutc
          task_list_before_update = get_all_edge_gateway_update_tasks_ordered_by_start_date_since_time(start_time)
          EdgeGatewayServices.new.update(@initial_config_file)
          task_list_after_update = get_all_edge_gateway_update_tasks_ordered_by_start_date_since_time(start_time)
          expect(task_list_after_update.size - task_list_before_update.size).to be(0)
        end

        it "should only create one additional edgeGateway update task when adding the LoadBalancer config" do
          start_time = Time.now.getutc
          task_list_before_update = get_all_edge_gateway_update_tasks_ordered_by_start_date_since_time(start_time)
          EdgeGatewayServices.new.update(@adding_load_balancer_config_file)
          task_list_after_update = get_all_edge_gateway_update_tasks_ordered_by_start_date_since_time(start_time)
          expect(task_list_after_update.size - task_list_before_update.size).to be(1)
        end

        it "should not update the EdgeGateway again if we reapply the 'adding load balancer' config" do
          start_time = Time.now.getutc
          task_list_before_update = get_all_edge_gateway_update_tasks_ordered_by_start_date_since_time(start_time)
          EdgeGatewayServices.new.update(@adding_load_balancer_config_file)
          task_list_after_update = get_all_edge_gateway_update_tasks_ordered_by_start_date_since_time(start_time)
          expect(task_list_after_update.size - task_list_before_update.size).to be(0)
        end

      end

      after(:all) do
        reset_edge_gateway unless ENV['VCLOUD_NO_RESET_VSE_AFTER']
        remove_temp_config_files
      end

      def remove_temp_config_files
        FileUtils.rm(@files_to_delete)
      end

      def reset_edge_gateway
        edge_gateway = Core::EdgeGateway.get_by_name @edge_name
        edge_gateway.update_configuration({
                                            FirewallService: {IsEnabled: false, FirewallRule: []},
                                            NatService: {:IsEnabled => "true", :NatRule => []},
                                            LoadBalancerService: {
                                              IsEnabled: "false",
                                              Pool: [],
                                              VirtualServer: []
                                            }
                                          })
      end

      def generate_input_config_file(data_file, erb_input)
        config_erb = File.expand_path("data/#{data_file}", File.dirname(__FILE__))
        output_file = ErbHelper.convert_erb_template_to_yaml(erb_input, config_erb)
        @files_to_delete << output_file
        output_file
      end

      def edge_gateway_erb_input
        {
          edge_gateway_name: @edge_name,
          network_id: @ext_net_id,
          original_ip: @ext_net_ip,
          edge_gateway_ext_network_id: @ext_net_id,
          edge_gateway_ext_network_ip: @ext_net_ip,
        }
      end

      def get_all_edge_gateway_update_tasks_ordered_by_start_date_since_time(timestamp)
        vcloud_time = timestamp.strftime('%FT%T.000Z')
        q = QueryRunner.new

        q.run('task',
          :filter =>
            "name==networkConfigureEdgeGatewayServices;objectName==#{@edge_name};startDate=ge=#{vcloud_time}",
          :sortDesc => 'startDate',
        )
      end


    end

  end
end
