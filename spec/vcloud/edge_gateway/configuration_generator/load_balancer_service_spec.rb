require 'spec_helper'

module Vcloud
  module EdgeGateway
    module ConfigurationGenerator
      describe LoadBalancerService do

        before(:each) do
          mock_uplink_interface = double(
            :mock_uplink,
            :network_name => "ExternalNetwork",
            :network_id   => "12345678-1234-1234-1234-123456789012",
            :network_href => 'https://example.com/api/admin/network/12345678-1234-1234-1234-123456789012',
          )
          mock_internal_interface = double(
            :mock_uplink,
            :network_name => "InternalNetwork",
            :network_id   => "12346788-1234-1234-1234-123456789000",
            :network_href => "https://example.com/api/admin/network/12346788-1234-1234-1234-123456789000",
          )
          @edge_gw_interface_list = [ mock_internal_interface, mock_uplink_interface ]
        end

        context "top level LoadBalancer configuration defaults" do

          before(:each) do
            input = { } # minimum configuration
            @output = LoadBalancerService.new(@edge_gw_interface_list).generate_fog_config(input)
          end

          it 'should default to LoadBalancerService enabled' do
            expect(@output[:IsEnabled]).to eq('true')
          end

          it 'should match our expected defaults' do
            expect(@output).to eq({
              :IsEnabled=>"true", :Pool=>[], :VirtualServer=>[]
            })
          end

        end

        context "When configuring a minimal VirtualServer entry" do

          before(:each) do
            input = { virtual_servers: [{
              name: "virtual-server-1",
              ip_address: '192.2.0.1',
              network: "12345678-1234-1234-1234-123456789012",
              pool: "pool-1",
            }]}
            output = LoadBalancerService.new(@edge_gw_interface_list).generate_fog_config(input)
            @rule = output[:VirtualServer].first
          end

          it 'should default to the entry being enabled' do
            expect(@rule[:IsEnabled]).to eq('true')
          end

          it 'should default to description being empty' do
            expect(@rule[:Description]).to eq('')
          end

          it 'should match our expected complete entry' do
            expect(@rule).to eq({
              :IsEnabled=>"true",
              :Name=>"virtual-server-1",
              :Description=>"",
              :Interface=>{
                :type=>"application/vnd.vmware.vcloud.orgVdcNetwork+xml",
                :name=>"ExternalNetwork",
                :href=>"https://example.com/api/admin/network/12345678-1234-1234-1234-123456789012",
              },
              :IpAddress=>"192.2.0.1",
              :ServiceProfile=>[
                {
                  :IsEnabled=>"false",
                  :Protocol=>"HTTP",
                  :Port=>"80",
                  :Persistence=>{:Method=>""}
                },
                {
                  :IsEnabled=>"false",
                  :Protocol=>"HTTPS",
                  :Port=>"443",
                  :Persistence=>{:Method=>""}
                },
                {
                  :IsEnabled=>"false",
                  :Protocol=>"TCP",
                  :Port=>"",
                  :Persistence=>{:Method=>""}
                }
              ],
              :Logging=>"false",
              :Pool=>"pool-1"
            })
          end

        end

        context "When configuring a minimal Pool entry" do

          before(:each) do
            input = { pools: [{
              name: "pool-1",
              members: [ { ip_address: '10.10.10.10' } ],
            }]}
            output = LoadBalancerService.new(@edge_gw_interface_list).generate_fog_config(input)
            @rule = output[:Pool].first
          end

          it 'should default to description being not set' do
            expect(@rule.key?(:Description)).to be false
          end

          it 'should match our expected complete entry' do
            expect(@rule).to eq({
              :Name=>"pool-1",
              :ServicePort=>[
                {
                  :IsEnabled=>"false",
                  :Protocol=>"HTTP",
                  :Algorithm=>"ROUND_ROBIN",
                  :Port=>"80",
                  :HealthCheckPort=>"",
                  :HealthCheck=>{
                    :Mode=>"HTTP",
                    :Uri=>"/",
                    :HealthThreshold=>"2",
                    :UnhealthThreshold=>"3",
                    :Interval=>"5",
                    :Timeout=>"15"
                  }
                },
                {
                  :IsEnabled=>"false",
                  :Protocol=>"HTTPS",
                  :Algorithm=>"ROUND_ROBIN",
                  :Port=>"443",
                  :HealthCheckPort=>"",
                  :HealthCheck=>{
                    :Mode=>"SSL",
                    :Uri=>"",
                    :HealthThreshold=>"2",
                    :UnhealthThreshold=>"3",
                    :Interval=>"5",
                    :Timeout=>"15"
                  }
                },
                {
                  :IsEnabled=>"false",
                  :Protocol=>"TCP",
                  :Algorithm=>"ROUND_ROBIN",
                  :Port=>"",
                  :HealthCheckPort=>"",
                  :HealthCheck=>{
                    :Mode=>"TCP",
                    :Uri=>"",
                    :HealthThreshold=>"2",
                    :UnhealthThreshold=>"3",
                    :Interval=>"5",
                    :Timeout=>"15"
                  }
                }],
              :Member=>[
                {
                  :IpAddress=>"10.10.10.10",
                  :Weight=>"1",
                  :ServicePort=>[
                    {:Protocol=>"HTTP",
                     :Port=>"",
                     :HealthCheckPort=>""},
                    {:Protocol=>"HTTPS",
                     :Port=>"",
                     :HealthCheckPort=>""},
                    {:Protocol=>"TCP",
                      :Port=>"",
                      :HealthCheckPort=>""}
                  ]
                }
              ]
            })
          end
        end

        context "When configuring HTTP load balancer" do

          it 'should expand out input config into Fog expected input' do
            input            = read_data_file('load_balancer_http-input.yaml')
            expected_output  = read_data_file('load_balancer_http-output.yaml')
            generated_config = LoadBalancerService.new(@edge_gw_interface_list).
              generate_fog_config input
            expect(generated_config).to eq(expected_output)
          end

          it "should set the healthcheck URI to '/' by default" do
            input = read_data_file('load_balancer_http-input.yaml')
            expect(input[:pools][0][:service][:http][:health_check][:protocol]).to eq('HTTP')
            expect(input[:pools][0][:service][:http][:health_check].key?(:uri)).to be(false)

            generated_config = LoadBalancerService.new(@edge_gw_interface_list).
              generate_fog_config input

            http_pool_service_port = generated_config[:Pool][0][:ServicePort][0]
            expect(http_pool_service_port[:IsEnabled]).to eq('true')
            expect(http_pool_service_port[:HealthCheck][:Mode]).to eq('HTTP')
            expect(http_pool_service_port[:HealthCheck][:Uri]).to eq('/')
          end

          it "should set the healthchech URI to '' by default for a TCP healthcheck" do
            input = read_data_file('load_balancer_http-tcp-healthcheck-input.yaml')
            expect(input[:pools][0][:service][:http][:health_check][:protocol]).to eq('TCP')
            expect(input[:pools][0][:service][:http][:health_check].key?(:uri)).to be(false)

            generated_config = LoadBalancerService.new(@edge_gw_interface_list).
              generate_fog_config input

            http_pool_service_port = generated_config[:Pool][0][:ServicePort][0]
            expect(http_pool_service_port[:IsEnabled]).to eq('true')
            expect(http_pool_service_port[:HealthCheck][:Mode]).to eq('TCP')
            expect(http_pool_service_port[:HealthCheck][:Uri]).to eq('')
          end

          it 'should raise an exception if I define a healthcheck URI on a TCP healthcheck' do
            input = read_data_file('load_balancer_http-tcp-healthcheck-with-uri-input.yaml')
            expect(input[:pools][0][:service][:http][:health_check][:uri]).to eq('/notsupported')
            expect(input[:pools][0][:service][:http][:health_check][:protocol]).to eq('TCP')

            expect {
              LoadBalancerService.new(@edge_gw_interface_list).generate_fog_config input
            }.to raise_error "vCloud Director does not support healthcheck URI on protocols other than HTTP"
          end

        end

        context "When configuring HTTPS load balancer" do

          it 'should expand out input config into Fog expected input' do
            input            = read_data_file('load_balancer_https-input.yaml')
            expected_output  = read_data_file('load_balancer_https-output.yaml')
            generated_config = LoadBalancerService.new(@edge_gw_interface_list).
              generate_fog_config input
            expect(generated_config).to eq(expected_output)
          end

          it "should set the healthcheck URI to '' by default" do
            input = read_data_file('load_balancer_https-input.yaml')
            expect(input[:pools][0][:service][:https].key?(:health_check)).to be(false)

            generated_config = LoadBalancerService.new(@edge_gw_interface_list).
              generate_fog_config input

            https_pool_service_port = generated_config[:Pool][0][:ServicePort][1]
            expect(https_pool_service_port[:IsEnabled]).to eq('true')
            expect(https_pool_service_port[:HealthCheck][:Mode]).to eq('SSL')
            expect(https_pool_service_port[:HealthCheck][:Uri]).to eq('')
          end

          it 'should raise an exception if I define a healthcheck URI on a HTTPS healthcheck' do
            input = read_data_file('load_balancer_https-healthcheck-uri-input.yaml')
            expect(input[:pools][0][:service][:https][:health_check][:uri]).to eq('/notsupported')
            expect(input[:pools][0][:service][:https][:health_check].key?(:protocol)).to be(false)

            expect {
              LoadBalancerService.new(@edge_gw_interface_list).generate_fog_config input
            }.to raise_error "vCloud Director does not support healthcheck URI on protocols other than HTTP"
          end

        end

        context "When configuring complex mixed protocol load balancer" do

          it 'should expand out input config into Fog expected input' do
            input = read_data_file('load_balancer_mixed_complex-input.yaml')
            expected_output  = read_data_file('load_balancer_mixed_complex-output.yaml')
            generated_config = LoadBalancerService.new(@edge_gw_interface_list).
              generate_fog_config input
            expect(generated_config).to eq(expected_output)
          end

        end

        def read_data_file(name)
          full_path = File.join(File.dirname(__FILE__), 'data', name)
          unsymbolized_data = YAML::load(File.open(full_path))
          json_string = JSON.generate(unsymbolized_data)
          JSON.parse(json_string, :symbolize_names => true)
        end

      end

    end
  end
end
