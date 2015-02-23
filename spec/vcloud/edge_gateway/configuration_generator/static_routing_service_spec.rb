require 'spec_helper'

module Vcloud
  module EdgeGateway
    module ConfigurationGenerator
      describe StaticRoutingService do
        before(:each) do
          mock_uplink_interface = double(
              :mock_uplink,
              :network_name => "ane012345",
              :network_id   => "2ad93597-7b54-43dd-9eb1-631dd337e5a7",
              :network_href   => "https://vmware.api.net/api/admin/network/2ad93597-7b54-43dd-9eb1-631dd337e5a7",
          )
          mock_internal_interface = double(
             :mock_uplink,
             :network_name => "internal_interface",
             :network_id   => "12346788-1234-1234-1234-123456789000",
             :network_href => "https://vmware.api.net/api/admin/network/12346788-1234-1234-1234-123456789000",
           )
          @edge_gw_interface_list = [ mock_internal_interface, mock_uplink_interface ]
        end

        context "top level static routing configuration defaults" do

          it 'should default to StaticRoutingService enabled' do
            @output = StaticRoutingService.new({}, @edge_gw_interface_list).generate_fog_config
            expect(@output[:IsEnabled]).to eq('true')
          end
        end

        context "static routing defaults" do

          before(:each) do
            routes = { static_routes: [{
              name: "Test Route",
              network: "192.2.0.0/24",
              next_hop: "192.168.1.1",
              apply_on: "ane012345"
            }]}
            output = StaticRoutingService.new(routes,@edge_gw_interface_list).generate_fog_config
            @route = output[:StaticRoute].first
          end

          it 'should default to route being enabled' do
            expect(@route[:IsEnabled]).to eq('true')
          end

          it 'should have name set' do
            expect(@route[:Name]).to eq('Test Route')
          end

          it 'should have next hop set' do
            expect(@route[:NextHopIp]).to eq('192.168.1.1')
          end

          it 'should have correct gateway interface set' do
            interface = @route[:GatewayInterface]
            expect(interface[:name]).to eq('ane012345')
          end
        end

        context "static route config generation" do

          it 'should have disabled firewall with a disabled rule' do
            input = {
              static_routes: [{ 
                name: 'Disabled route',
                enabled: 'false',
                network: '192.192.192.0/24',
                next_hop: '192.192.182.1',
                apply_on: 'ane012345'
              }]
            }
            output = {
                IsEnabled: 'true',
                StaticRoute: [
                  {
                    Name: 'Disabled route',
                    Network: '192.192.192.0/24',
                    NextHopIp: '192.192.182.1',
                    IsEnabled: 'false',
                    GatewayInterface: {
                      type: 'application/vnd.vmware.vcloud.orgVdcNetwork+xml',
                      name: 'ane012345',
                      href: 'https://vmware.api.net/api/admin/network/2ad93597-7b54-43dd-9eb1-631dd337e5a7'
                    }
                  }
                ]
            }
            generated_config = StaticRoutingService.new(input, @edge_gw_interface_list).generate_fog_config
            expect(generated_config).to eq(output)
          end

        end
      end
    end
  end
end
