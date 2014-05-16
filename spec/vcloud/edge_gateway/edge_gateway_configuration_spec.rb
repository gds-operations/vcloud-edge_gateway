require 'spec_helper'

module Vcloud
  module EdgeGateway
    describe EdgeGatewayConfiguration do

      before(:each) do
        @edge_gateway_id = "1111111-7b54-43dd-9eb1-631dd337e5a7"
        mock_edge_gateway_interface = double(
          :mock_edge_gateway_interface,
          :network_name => "ane012345",
          :network_id   => "01234567-1234-1234-1234-0123456789aa",
          :network_href => 'https://vmware.example.com/api/admin/network/01234567-1234-1234-1234-0123456789aa',
        )
        @edge_gw_interface_list = [ mock_edge_gateway_interface ]
      end

      context "config object doesn't require methods called in a particular order" do

        before(:each) do
          @test_config = {
            :gateway => @edge_gateway_id,
            :nat_service => test_nat_config,
            :firewall_service => test_firewall_config,
            :load_balancer_service => test_load_balancer_config,
          }
          @remote_config = {
            :FirewallService => different_firewall_config,
            :NatService => different_nat_config,
            :LoadBalancerService => different_load_balancer_config,
          }
          @proposed_config = EdgeGateway::EdgeGatewayConfiguration.new(
            @test_config,
            @remote_config,
            @edge_gw_interface_list
          )
        end

        it "if `config` is called before `update_required` then config is not empty when it shouldn't be" do
          config = @proposed_config.config
          expect(config.empty?).to be_false
        end

      end

      context "all configurations are changed" do

        before(:each) do
          @test_config = {
            :gateway => @edge_gateway_id,
            :nat_service => test_nat_config,
            :firewall_service => test_firewall_config,
            :load_balancer_service => test_load_balancer_config
          }
          @remote_config = {
            :FirewallService => different_firewall_config,
            :NatService => different_nat_config,
            :LoadBalancerService => different_load_balancer_config
          }
          @proposed_config = EdgeGateway::EdgeGatewayConfiguration.new(
            @test_config,
            @remote_config,
            @edge_gw_interface_list
          )
        end

        it "requires update" do
          expect(@proposed_config.update_required?).to be(true)
        end

        it "proposed config contains firewall config in the form expected" do
          proposed_firewall_config = @proposed_config.config[:FirewallService]
          expect(proposed_firewall_config).to eq(expected_firewall_config)
        end

        it "proposed config contains nat config in the form expected" do
          proposed_nat_config = @proposed_config.config[:NatService]
          expect(proposed_nat_config).to eq(expected_nat_config)
        end

        it "proposed config contains load balancer config in the form expected" do
          proposed_load_balancer_config = @proposed_config.config[:LoadBalancerService]
          expect(proposed_load_balancer_config).to eq(expected_load_balancer_config)
        end

      end

      context "firewall config has changed and nat has not, load_balancer absent" do

        before(:each) do
          @test_config = {
            :gateway => @edge_gateway_id,
            :nat_service => test_nat_config,
            :firewall_service => test_firewall_config
          }
          @remote_config = {
            :FirewallService => different_firewall_config,
            :NatService => same_nat_config
          }
          @proposed_config = EdgeGateway::EdgeGatewayConfiguration.new(
            @test_config,
            @remote_config,
            @edge_gw_interface_list
          )
        end

        it "requires update" do
          expect(@proposed_config.update_required?).to be(true)
        end

        it "proposed config contains firewall config in the form expected" do
          proposed_firewall_config = @proposed_config.config[:FirewallService]
          expect(proposed_firewall_config).to eq(expected_firewall_config)
        end

        it "proposed config does not contain nat config" do
          expect(@proposed_config.config.key?(:NatService)).to be(false)
        end

        it "proposed config does not contain load_balancer config" do
          expect(@proposed_config.config.key?(:LoadBalancerService)).to be(false)
        end

      end

      context "firewall config has changed and nat & load_balancer configs are absent" do

        before(:each) do
          @test_config = {
            :gateway => @edge_gateway_id,
            :firewall_service => test_firewall_config
          }
          @remote_config = {
            :FirewallService => different_firewall_config,
            :NatService => same_nat_config,
            :LoadBalancerService => same_load_balancer_config,
          }
          @proposed_config = EdgeGateway::EdgeGatewayConfiguration.new(
            @test_config,
            @remote_config,
            @edge_gw_interface_list
          )
        end

        it "requires update" do
          expect(@proposed_config.update_required?).to be(true)
        end

        it "proposed config contains firewall config in the form expected" do
          proposed_firewall_config = @proposed_config.config[:FirewallService]
          expect(proposed_firewall_config).to eq(expected_firewall_config)
        end

        it "proposed config does not contain nat config" do
          expect(@proposed_config.config.key?(:NatService)).to be(false)
        end

        it "proposed config does not contain load_balancer config" do
          expect(@proposed_config.config.key?(:LoadBalancerService)).to be(false)
        end

      end

      context "load_balancer config has changed and firewall & nat have not" do

        before(:each) do
          @test_config = {
            :gateway => @edge_gateway_id,
            :nat_service => test_nat_config,
            :firewall_service => test_firewall_config,
            :load_balancer_service => test_load_balancer_config,
          }
          @remote_config = {
            :FirewallService => same_firewall_config,
            :NatService => same_nat_config,
            :LoadBalancerService => different_load_balancer_config,
          }
          @proposed_config = EdgeGateway::EdgeGatewayConfiguration.new(
            @test_config,
            @remote_config,
            @edge_gw_interface_list
          )
        end

        it "requires update" do
          expect(@proposed_config.update_required?).to be(true)
        end

        it "proposed config contains load_balancer config in the form expected" do
          proposed_load_balancer_config = @proposed_config.config[:LoadBalancerService]
          expect(proposed_load_balancer_config).to eq(expected_load_balancer_config)
        end

        it "proposed config does not contain nat config" do
          expect(@proposed_config.config.key?(:NatService)).to be(false)
        end

        it "proposed config does not contain firewall config" do
          expect(@proposed_config.config.key?(:FirewallService)).to be(false)
        end

      end

      context "load_balancer & firewall config have changed and nat has not" do

        before(:each) do
          @test_config = {
            :gateway => @edge_gateway_id,
            :nat_service => test_nat_config,
            :firewall_service => test_firewall_config,
            :load_balancer_service => test_load_balancer_config,
          }
          @remote_config = {
            :FirewallService => different_firewall_config,
            :NatService => same_nat_config,
            :LoadBalancerService => different_load_balancer_config,
          }
          @proposed_config = EdgeGateway::EdgeGatewayConfiguration.new(
            @test_config,
            @remote_config,
            @edge_gw_interface_list
          )
        end

        it "requires update" do
          expect(@proposed_config.update_required?).to be(true)
        end

        it "proposed config contains load_balancer config in the form expected" do
          proposed_load_balancer_config = @proposed_config.config[:LoadBalancerService]
          expect(proposed_load_balancer_config).to eq(expected_load_balancer_config)
        end

        it "proposed config does not contain nat config" do
          expect(@proposed_config.config.key?(:NatService)).to be(false)
        end

        it "proposed config contains firewall config in the form expected" do
          proposed_firewall_config = @proposed_config.config[:FirewallService]
          expect(proposed_firewall_config).to eq(expected_firewall_config)
        end

      end


      context "load_balancer config has changed and firewall & nat are absent" do

        before(:each) do
          @test_config = {
            :gateway => @edge_gateway_id,
            :load_balancer_service => test_load_balancer_config,
          }
          @remote_config = {
            :FirewallService => same_firewall_config,
            :NatService => same_nat_config,
            :LoadBalancerService => different_load_balancer_config,
          }
          @proposed_config = EdgeGateway::EdgeGatewayConfiguration.new(
            @test_config,
            @remote_config,
            @edge_gw_interface_list
          )
        end

        it "requires update" do
          expect(@proposed_config.update_required?).to be(true)
        end

        it "proposed config contains load_balancer config in the form expected" do
          proposed_load_balancer_config = @proposed_config.config[:LoadBalancerService]
          expect(proposed_load_balancer_config).to eq(expected_load_balancer_config)
        end

        it "proposed config does not contain nat config" do
          expect(@proposed_config.config.key?(:NatService)).to be(false)
        end

        it "proposed config does not contain firewall config" do
          expect(@proposed_config.config.key?(:FirewallService)).to be(false)
        end

      end

      context "all configs are present but haven't changed" do

        before(:each) do
          @test_config = {
            :gateway => @edge_gateway_id,
            :nat_service => test_nat_config,
            :firewall_service => test_firewall_config,
            :load_balancer_service => test_load_balancer_config,
          }
          @remote_config = {
            :FirewallService => same_firewall_config,
            :NatService => same_nat_config,
            :LoadBalancerService => same_load_balancer_config,
          }
          @proposed_config = EdgeGateway::EdgeGatewayConfiguration.new(
            @test_config,
            @remote_config,
            @edge_gw_interface_list
          )
        end

        it "does not require update" do
          expect(@proposed_config.update_required?).to be(false)
        end

        it "there is no proposed config" do
          expect(@proposed_config.config.empty?).to be(true)
        end

      end

      context "firewall config has not changed and nat & load_balancer config is absent" do

        before(:each) do
          @test_config = {
            :gateway => @edge_gateway_id,
            :firewall_service => test_firewall_config
          }
          @remote_config = {
            :FirewallService => same_firewall_config,
            :NatService => different_nat_config,
            :LoadBalancerService => different_load_balancer_config,
          }
          @proposed_config = EdgeGateway::EdgeGatewayConfiguration.new(
            @test_config,
            @remote_config,
            @edge_gw_interface_list
          )
        end

        it "does not require update" do
          expect(@proposed_config.update_required?).to be(false)
        end

        it "there is no proposed config" do
          expect(@proposed_config.config.empty?).to be(true)
        end

      end

      context "no service config is present" do

        before(:each) do
          @test_config = {
            :gateway => @edge_gateway_id,
          }
          @remote_config = {
            :FirewallService => different_firewall_config,
            :NatService => different_nat_config,
            :LoadBalancerService => different_load_balancer_config,
          }
          @proposed_config = EdgeGateway::EdgeGatewayConfiguration.new(
            @test_config,
            @remote_config,
            @edge_gw_interface_list
          )
        end

        it "does not require update" do
          expect(@proposed_config.update_required?).to be(false)
        end

        it "there is no proposed config" do
          expect(@proposed_config.config.empty?).to be(true)
        end

      end

      context "when there is a missing remote LoadBalancerService, we can still update NatService" do

        before(:each) do
          @test_config = {
            :gateway => @edge_gateway_id,
            :nat_service => test_nat_config,
          }
          @remote_config = {
            :FirewallService => different_firewall_config,
            :NatService => different_nat_config,
          }
          @proposed_config = EdgeGateway::EdgeGatewayConfiguration.new(
            @test_config,
            @remote_config,
            @edge_gw_interface_list
          )
        end

        it "requires update" do
          expect(@proposed_config.update_required?).to be(true)
        end

        it "proposed config contains nat config in the form expected" do
          proposed_nat_config = @proposed_config.config[:NatService]
          expect(proposed_nat_config).to eq(expected_nat_config)
        end

        it "proposed config does not contain load balancer config" do
          expect(@proposed_config.config.key?(:LoadBalancerService)).to be(false)
        end

        it "proposed config does not contain firewall config" do
          expect(@proposed_config.config.key?(:FirewallService)).to be(false)
        end

      end

      context "there is no remote FirewallService config, but we are trying to update it" do

        before(:each) do
          @test_config = {
            :gateway => @edge_gateway_id,
            :firewall_service => test_firewall_config,
          }
          @remote_config = {
            :NatService => different_nat_config,
            :LoadBalancerService => different_load_balancer_config,
          }
          @proposed_config = EdgeGateway::EdgeGatewayConfiguration.new(
            @test_config,
            @remote_config,
            @edge_gw_interface_list
          )
        end

        it "requires update" do
          expect(@proposed_config.update_required?).to be(true)
        end

        it "proposed config contains firewall config in the form expected" do
          proposed_firewall_config = @proposed_config.config[:FirewallService]
          expect(proposed_firewall_config).to eq(expected_firewall_config)
        end

        it "proposed config does not contain load balancer config" do
          expect(@proposed_config.config.key?(:LoadBalancerService)).to be(false)
        end

        it "proposed config does not contain nat config" do
          expect(@proposed_config.config.key?(:NatService)).to be(false)
        end

      end

      context "there is no remote NatService config, but we are trying to update it" do

        before(:each) do
          @test_config = {
            :gateway => @edge_gateway_id,
            :nat_service => test_nat_config,
          }
          @remote_config = {
            :FirewallService => different_firewall_config,
            :LoadBalancerService => different_load_balancer_config,
          }
          @proposed_config = EdgeGateway::EdgeGatewayConfiguration.new(
            @test_config,
            @remote_config,
            @edge_gw_interface_list
          )
        end

        it "requires update" do
          expect(@proposed_config.update_required?).to be(true)
        end

        it "proposed config contains nat config in the form expected" do
          proposed_nat_config = @proposed_config.config[:NatService]
          expect(proposed_nat_config).to eq(expected_nat_config)
        end

        it "proposed config does not contain load balancer config" do
          expect(@proposed_config.config.key?(:LoadBalancerService)).to be(false)
        end

        it "proposed config does not contain firewall config" do
          expect(@proposed_config.config.key?(:FirewallService)).to be(false)
        end

      end

      context "there is no remote LoadBalancer config, but we are trying to update it" do

        before(:each) do
          @test_config = {
            :gateway => @edge_gateway_id,
            :load_balancer_service => test_load_balancer_config,
          }
          @remote_config = {
            :FirewallService => different_firewall_config,
            :NatService => different_nat_config,
          }
          @proposed_config = EdgeGateway::EdgeGatewayConfiguration.new(
            @test_config,
            @remote_config,
            @edge_gw_interface_list
          )
        end

        it "requires update" do
          expect(@proposed_config.update_required?).to be(true)
        end

        it "proposed config contains load_balancer config in the form expected" do
          proposed_load_balancer_config = @proposed_config.config[:LoadBalancerService]
          expect(proposed_load_balancer_config).to eq(expected_load_balancer_config)
        end

        it "proposed config does not contain nat config" do
          expect(@proposed_config.config.key?(:NatService)).to be(false)
        end

        it "proposed config does not contain firewall config" do
          expect(@proposed_config.config.key?(:FirewallService)).to be(false)
        end

      end

      def test_firewall_config
        {
          :policy => "drop",
          :log_default_action => true,
          :firewall_rules => [{
            :enabled => true,
            :description => "A rule",
            :policy => "allow",
            :protocols => "tcp",
            :destination_port_range => "Any",
            :destination_ip => "10.10.1.2",
            :source_port_range => "Any",
            :source_ip => "192.0.2.2"
          }, {
            :enabled => true,
            :destination_ip =>  "10.10.1.3-10.10.1.5",
            :source_ip => "192.0.2.2/24"
          }]
        }
      end

      def test_nat_config
        {
          :nat_rules => [{
            :enabled => true,
            :network_id => "01234567-1234-1234-1234-0123456789aa",
            :rule_type => "DNAT",
            :translated_ip => "10.10.1.2-10.10.1.3",
            :translated_port => "3412",
            :original_ip => "192.0.2.58",
            :original_port => "3412",
            :protocol =>"tcp"
          }]
        }
      end

      def test_load_balancer_config
        {
          enabled: 'true',
          pools: [{
            name: 'unit-test-pool-1',
            description: 'A pool',
            service: {
              http: {
                enabled: true,
                port: 8080,
                algorithm: 'ROUND_ROBIN',
              }
            },
            members: [
              { ip_address: '10.0.2.55' },
              { ip_address: '10.0.2.56' },
            ],
          }],
          virtual_servers: [{
            name: 'unit-test-vs-1',
            description: 'A virtual server',
            ip_address: '192.0.2.88',
            network: '01234567-1234-1234-1234-0123456789aa',
            pool: 'unit-test-pool-1',
            service_profiles: {
              http: {
                port: 8080
              },
            }
          }]
        }
      end

      def different_firewall_config
        {
          :IsEnabled => "true",
          :DefaultAction => "drop",
          :LogDefaultAction => "false",
          :FirewallRule => [{
            :Id => "1",
            :IsEnabled => "true",
            :MatchOnTranslate => "false",
            :Description => "A rule",
            :Policy => "allow",
            :Protocols => {
              :Tcp => "true"
            },
            :Port => "-1",
            :DestinationPortRange => "Any",
            :DestinationIp => "10.10.1.2",
            :SourcePort => "-1",
            :SourcePortRange => "Any",
            :SourceIp => "192.0.2.2",
            :EnableLogging =>"false"
          }]
        }
      end

      def different_nat_config
        {
          :IsEnabled => "true",
          :NatRule => [{
            :RuleType => "SNAT",
            :IsEnabled => "true",
            :Id => "65538",
            :GatewayNatRule => {
              :Interface => {
                :type => "application/vnd.vmware.admin.network+xml",
                :name => "RemoteVSE",
                :href =>"https://api.vmware.example.com/api/admin/network/01234567-1234-1234-1234-012345678912"
              },
            :OriginalIp => "10.10.1.2-10.10.1.3",
            :TranslatedIp => "192.0.2.40"
            }
          }]
        }
      end

      def different_load_balancer_config
        {
          :IsEnabled=>"true",
          :Pool=>[{
            :Name=>"unit-test-pool-1",
            :Description=>"A pool that has been updated",
            :ServicePort=>[{
              :IsEnabled=>"true",
              :Protocol=>"HTTP",
              :Algorithm=>"ROUND_ROBIN",
              :Port=>"8081",
              :HealthCheckPort=>"",
              :HealthCheck=>{
                :Mode=>"HTTP",
                :Uri=>"/",
                :HealthThreshold=>"2",
                :UnhealthThreshold=>"3",
                :Interval=>"5",
                :Timeout=>"15"
              }
            }, {
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
            }, {
              :IsEnabled=>"false",
              :Protocol=>"TCP",
              :Algorithm =>"ROUND_ROBIN",
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
            :Member=>[{
              :IpAddress=>"10.0.2.55",
              :Weight=>"1",
              :ServicePort=>[{
                :Protocol=>"HTTP",
                :Port=>"",
                :HealthCheckPort=>""
              }, {
                :Protocol=>"HTTPS",
                :Port=>"",
                :HealthCheckPort=>""
              }, {
                :Protocol=>"TCP",
                :Port=>"",
                :HealthCheckPort=>""
              }]
            }, {
              :IpAddress=>"10.0.2.56",
              :Weight=>"1",
              :ServicePort=>[{
                :Protocol=>"HTTP",
                :Port=>"",
                :HealthCheckPort=>""
              }, {
                :Protocol=>"HTTPS",
                :Port=>"",
                :HealthCheckPort=>""
              }, {
                :Protocol=>"TCP",
                :Port=>"",
                :HealthCheckPort=>""
              }]
            }]
          }],
          :VirtualServer=>[{
            :IsEnabled=>"true",
            :Name=>"unit-test-vs-1",
            :Description=>"A virtual server that has been updated",
            :Interface=>{
              :type => "application/vnd.vmware.admin.network+xml",
              :name => "RemoteVSE",
              :href =>"https://api.vmware.example.com/api/admin/network/01234567-1234-1234-1234-012345678912"
            },
            :IpAddress=>"192.0.2.199",
            :ServiceProfile=>[{
              :IsEnabled=>"true",
              :Protocol=>"HTTP",
              :Port=>"8080",
              :Persistence=>{
                :Method =>""
              }
            }, {
              :IsEnabled=>"false",
              :Protocol=>"HTTPS",
              :Port=>"443",
              :Persistence=>{
                :Method=>""
              }
            }, {
              :IsEnabled=>"false",
              :Protocol=>"TCP",
              :Port=>"",
              :Persistence=>{
                :Method=>""
              }
            }],
            :Logging=>"false",
            :Pool=>"unit-test-pool-1"
          }]
        }
      end

      def same_firewall_config
        {
          :IsEnabled => "true",
          :DefaultAction => "drop",
          :LogDefaultAction => "true",
          :FirewallRule => [{
            :Id => "1",
            :IsEnabled => "true",
            :MatchOnTranslate => "false",
            :Description => "A rule",
            :Policy => "allow",
            :Protocols => {
              :Tcp => "true"
            },
            :DestinationPortRange => "Any",
            :Port => "-1",
            :DestinationIp => "10.10.1.2",
            :SourcePortRange => "Any",
            :SourcePort => "-1",
            :SourceIp => "192.0.2.2",
            :EnableLogging => "false"
            }, {
            :Id => "2",
            :IsEnabled => "true",
            :MatchOnTranslate => "false",
            :Description => "",
            :Policy => "allow",
            :Protocols => {
              :Tcp => "true"
            },
            :DestinationPortRange => "Any",
            :Port => "-1",
            :DestinationIp => "10.10.1.3-10.10.1.5",
            :SourcePortRange => "Any",
            :SourcePort => "-1",
            :SourceIp => "192.0.2.2/24",
            :EnableLogging =>"false"
          }]
        }
      end

      def same_nat_config
        {
          :IsEnabled => "true",
          :NatRule => [{
            :Id => "65537",
            :IsEnabled => "true",
            :RuleType => "DNAT",
            :GatewayNatRule => {
              :Interface => {
                :type => "application/vnd.vmware.admin.network+xml",
                :name => "ane012345",
                :href =>"https://vmware.example.com/api/admin/network/01234567-1234-1234-1234-0123456789aa"
              },
              :OriginalIp => "192.0.2.58",
              :TranslatedIp => "10.10.1.2-10.10.1.3",
              :OriginalPort => "3412",
              :TranslatedPort => "3412",
              :Protocol => "tcp"
            }
          }]
        }
      end

      def same_load_balancer_config
        {
          :IsEnabled=>"true",
          :Pool=>[{
            :Name=>"unit-test-pool-1",
            :Description=>"A pool",
            :ServicePort=>[{
              :IsEnabled=>"true",
              :Protocol=>"HTTP",
              :Algorithm=>"ROUND_ROBIN",
              :Port=>"8080",
              :HealthCheckPort=>"",
              :HealthCheck=>{
                :Mode=>"HTTP",
                :Uri=>"/",
                :HealthThreshold=>"2",
                :UnhealthThreshold=>"3",
                :Interval=>"5",
                :Timeout=>"15"
              }
            }, {
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
            }, {
              :IsEnabled=>"false",
              :Protocol=>"TCP",
              :Algorithm =>"ROUND_ROBIN",
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
            :Member=>[{
              :IpAddress=>"10.0.2.55",
              :Weight=>"1",
              :ServicePort=>[{
                :Protocol=>"HTTP",
                :Port=>"",
                :HealthCheckPort=>""
              }, {
                :Protocol=>"HTTPS",
                :Port=>"",
                :HealthCheckPort=>""
              }, {
                :Protocol=>"TCP",
                :Port=>"",
                :HealthCheckPort=>""
              }]
            }, {
              :IpAddress=>"10.0.2.56",
              :Weight=>"1",
              :ServicePort=>[{
                :Protocol=>"HTTP",
                :Port=>"",
                :HealthCheckPort=>""
              }, {
                :Protocol=>"HTTPS",
                :Port=>"",
                :HealthCheckPort=>""
              }, {
                :Protocol=>"TCP",
                :Port=>"",
                :HealthCheckPort=>""
              }]
            }]
          }],
          :VirtualServer=>[{
            :IsEnabled=>"true",
            :Name=>"unit-test-vs-1",
            :Description=>"A virtual server",
            :Interface=>{
              :type=>"application/vnd.vmware.vcloud.orgVdcNetwork+xml",
              :name=>"ane012345",
              :href=>"https://vmware.example.com/api/admin/network/01234567-1234-1234-1234-0123456789aa"
            },
            :IpAddress=>"192.0.2.88",
            :ServiceProfile=>[{
              :IsEnabled=>"true",
              :Protocol=>"HTTP",
              :Port=>"8080",
              :Persistence=>{
                :Method =>""
              }
            }, {
              :IsEnabled=>"false",
              :Protocol=>"HTTPS",
              :Port=>"443",
              :Persistence=>{
                :Method=>""
              }
            }, {
              :IsEnabled=>"false",
              :Protocol=>"TCP",
              :Port=>"",
              :Persistence=>{
                :Method=>""
              }
            }],
            :Logging=>"false",
            :Pool=>"unit-test-pool-1"
          }]
        }
      end

      def expected_firewall_config
        {
          :IsEnabled => "true",
          :DefaultAction => "drop",
          :LogDefaultAction => "true",
          :FirewallRule => [{
            :Id => "1",
            :IsEnabled => "true",
            :MatchOnTranslate => "false",
            :Description => "A rule",
            :Policy =>"allow",
            :Protocols => {
              :Tcp => "true"
            },
            :DestinationPortRange => "Any",
            :Port => "-1",
            :DestinationIp => "10.10.1.2",
            :SourcePortRange => "Any",
            :SourcePort => "-1",
            :SourceIp => "192.0.2.2",
            :EnableLogging => "false"
            },
            {
            :Id => "2",
            :IsEnabled => "true",
            :MatchOnTranslate => "false",
            :Description => "",
            :Policy => "allow",
            :Protocols => {
              :Tcp => "true"
            },
            :DestinationPortRange => "Any",
            :Port => "-1",
            :DestinationIp => "10.10.1.3-10.10.1.5",
            :SourcePortRange => "Any",
            :SourcePort => "-1",
            :SourceIp => "192.0.2.2/24",
            :EnableLogging => "false"
          }]
        }
      end

      def expected_nat_config
        {
          :IsEnabled => "true",
          :NatRule => [{
            :Id => "65537",
            :IsEnabled => "true",
            :RuleType => "DNAT",
            :GatewayNatRule => {
              :Interface => {
                :type => "application/vnd.vmware.admin.network+xml",
                :name => "ane012345",
                :href => "https://vmware.example.com/api/admin/network/01234567-1234-1234-1234-0123456789aa"
              },
              :OriginalIp => "192.0.2.58",
              :TranslatedIp => "10.10.1.2-10.10.1.3",
              :OriginalPort => "3412",
              :TranslatedPort => "3412",
              :Protocol => "tcp"
            }
          }]
        }
      end

      def expected_load_balancer_config
        {
          :IsEnabled=>"true",
          :Pool=>[{
            :Name=>"unit-test-pool-1",
            :Description=>"A pool",
            :ServicePort=>[{
              :IsEnabled=>"true",
              :Protocol=>"HTTP",
              :Algorithm=>"ROUND_ROBIN",
              :Port=>"8080",
              :HealthCheckPort=>"",
              :HealthCheck=>{
                :Mode=>"HTTP",
                :Uri=>"/",
                :HealthThreshold=>"2",
                :UnhealthThreshold=>"3",
                :Interval=>"5",
                :Timeout=>"15"
              }
            }, {
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
            }, {
              :IsEnabled=>"false",
              :Protocol=>"TCP",
              :Algorithm =>"ROUND_ROBIN",
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
            :Member=>[{
              :IpAddress=>"10.0.2.55",
              :Weight=>"1",
              :ServicePort=>[{
                :Protocol=>"HTTP",
                :Port=>"",
                :HealthCheckPort=>""
              }, {
                :Protocol=>"HTTPS",
                :Port=>"",
                :HealthCheckPort=>""
              }, {
                :Protocol=>"TCP",
                :Port=>"",
                :HealthCheckPort=>""
              }]
            }, {
              :IpAddress=>"10.0.2.56",
              :Weight=>"1",
              :ServicePort=>[{
                :Protocol=>"HTTP",
                :Port=>"",
                :HealthCheckPort=>""
              }, {
                :Protocol=>"HTTPS",
                :Port=>"",
                :HealthCheckPort=>""
              }, {
                :Protocol=>"TCP",
                :Port=>"",
                :HealthCheckPort=>""
              }]
            }]
          }],
          :VirtualServer=>[{
            :IsEnabled=>"true",
            :Name=>"unit-test-vs-1",
            :Description=>"A virtual server",
            :Interface=>{
              :type=>"application/vnd.vmware.vcloud.orgVdcNetwork+xml",
              :name=>"ane012345",
              :href=>"https://vmware.example.com/api/admin/network/01234567-1234-1234-1234-0123456789aa"
            },
            :IpAddress=>"192.0.2.88",
            :ServiceProfile=>[{
              :IsEnabled=>"true",
              :Protocol=>"HTTP",
              :Port=>"8080",
              :Persistence=>{
                :Method =>""
              }
            }, {
              :IsEnabled=>"false",
              :Protocol=>"HTTPS",
              :Port=>"443",
              :Persistence=>{
                :Method=>""
              }
            }, {
              :IsEnabled=>"false",
              :Protocol=>"TCP",
              :Port=>"",
              :Persistence=>{
                :Method=>""
              }
            }],
            :Logging=>"false",
            :Pool=>"unit-test-pool-1"
          }]
        }
      end

    end
  end
end
