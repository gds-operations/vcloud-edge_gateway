require 'spec_helper'

module Vcloud
  module EdgeGateway
    describe EdgeGatewayConfiguration do

      context "both configurations are changed" do

        before(:each) do
          @edge_gateway_id = "1111111-7b54-43dd-9eb1-631dd337e5a7"
          @edge_gateway = double(:edge_gateway,
            :vcloud_gateway_interface_by_id => {
              Network: {
                :name => 'ane012345',
                :href => 'https://vmware.example.com/api/admin/network/01234567-1234-1234-1234-0123456789aa'
              }
            })
            Vcloud::Core::EdgeGateway.stub(:get_by_name).with(@edge_gateway_id).and_return(@edge_gateway)

          @test_config = {
            :gateway => @edge_gateway_id,
            :nat_service => test_nat_config,
            :firewall_service => test_firewall_config
          }

          @remote_config = {
            :FirewallService => different_firewall_config,
            :NatService => different_nat_config
          }
          @proposed_config = EdgeGateway::EdgeGatewayConfiguration.new(@test_config, @remote_config)
        end

        it "requires update" do
          expect(@proposed_config.update_required?).to be_true
        end

        it "proposed config contains firewall config in the form expected" do
          # bug in that if update required is not called, config is nil
          @proposed_config.update_required?

          proposed_firewall_config = @proposed_config.config[:FirewallService]
          expect(proposed_firewall_config).to eq(expected_firewall_config)
        end

        it "proposed config contains nat config in the form expected" do
          @proposed_config.update_required?

          proposed_nat_config = @proposed_config.config[:NatService]
          expect(proposed_nat_config).to eq(expected_nat_config)
        end

      end

      context "firewall config has changed and nat has not" do

        before(:each) do
          @edge_gateway_id = "1111111-7b54-43dd-9eb1-631dd337e5a7"
          @edge_gateway = double(:edge_gateway,
            :vcloud_gateway_interface_by_id => {
              Network: {
                :name => 'ane012345',
                :href => 'https://vmware.example.com/api/admin/network/01234567-1234-1234-1234-0123456789aa'
              }
            })
            Vcloud::Core::EdgeGateway.stub(:get_by_name).with(@edge_gateway_id).and_return(@edge_gateway)

          @test_config = {
            :gateway => @edge_gateway_id,
            :nat_service => test_nat_config,
            :firewall_service => test_firewall_config
          }

          @remote_config = {
            :FirewallService => different_firewall_config,
            :NatService => same_nat_config
          }

          @proposed_config = EdgeGateway::EdgeGatewayConfiguration.new(@test_config, @remote_config)
        end


        it "requires update" do
          expect(@proposed_config.update_required?).to be_true
        end

        it "proposed config contains firewall config in the form expected" do
          expect(@proposed_config.update_required?).to be_true

          proposed_firewall_config = @proposed_config.config[:FirewallService]
          expect(proposed_firewall_config).to eq(expected_firewall_config)
        end

        it "proposed config does not contain nat config" do
          expect(@proposed_config.update_required?).to be_true
          expect(@proposed_config.config.key?(:NatService)).to be_false
        end

      end

      context "firewall config has changed and nat config is absent" do

        before(:each) do
          @edge_gateway_id = "1111111-7b54-43dd-9eb1-631dd337e5a7"
          @edge_gateway = double(:edge_gateway,
            :vcloud_gateway_interface_by_id => {
              Network: {
                :name => 'ane012345',
                :href => 'https://vmware.example.com/api/admin/network/01234567-1234-1234-1234-0123456789aa'
              }
            })
            Vcloud::Core::EdgeGateway.stub(:get_by_name).with(@edge_gateway_id).and_return(@edge_gateway)

          @test_config = {
            :gateway => @edge_gateway_id,
            :firewall_service => test_firewall_config
          }

          @remote_config = {
            :FirewallService => different_firewall_config,
            :NatService => same_nat_config
          }

          @proposed_config = EdgeGateway::EdgeGatewayConfiguration.new(@test_config, @remote_config)
        end

        it "requires update" do
          expect(@proposed_config.update_required?).to be_true
        end

        it "proposed config contains firewall config in the form expected" do
          expect(@proposed_config.update_required?).to be_true

          proposed_firewall_config = @proposed_config.config[:FirewallService]
          expect(proposed_firewall_config).to eq(expected_firewall_config)
        end

        it "proposed config does not contain nat config" do
          expect(@proposed_config.update_required?).to be_true

          expect(@proposed_config.config.key?(:NatService)).to be_false
        end

      end

      context "both configs are present but haven't changed" do

        before(:each) do
          @edge_gateway_id = "1111111-7b54-43dd-9eb1-631dd337e5a7"
          @edge_gateway = double(:edge_gateway,
            :vcloud_gateway_interface_by_id => {
              Network: {
                :name => 'ane012345',
                :href => 'https://vmware.example.com/api/admin/network/01234567-1234-1234-1234-0123456789aa'
              }
            })
            Vcloud::Core::EdgeGateway.stub(:get_by_name).with(@edge_gateway_id).and_return(@edge_gateway)

          @test_config = {
            :gateway => @edge_gateway_id,
            :nat_service => test_nat_config,
            :firewall_service => test_firewall_config
          }

          @remote_config = {
            :FirewallService => same_firewall_config,
            :NatService => same_nat_config
          }

          @proposed_config = EdgeGateway::EdgeGatewayConfiguration.new(@test_config, @remote_config)
        end

        it "does not require update" do
          expect(@proposed_config.update_required?).to be_false
        end

        it "there is no proposed config" do
          expect(@proposed_config.update_required?).to be_false

          expect(@proposed_config.config.empty?).to be_true
        end

    end

    context "firewall config has not changed and nat config is absent" do
        before(:each) do
          @edge_gateway_id = "1111111-7b54-43dd-9eb1-631dd337e5a7"
          @edge_gateway = double(:edge_gateway,
            :vcloud_gateway_interface_by_id => {
              Network: {
                :name => 'ane012345',
                :href => 'https://vmware.example.com/api/admin/network/01234567-1234-1234-1234-0123456789aa'
              }
            })
            Vcloud::Core::EdgeGateway.stub(:get_by_name).with(@edge_gateway_id).and_return(@edge_gateway)

          @test_config = {
            :gateway => @edge_gateway_id,
            :firewall_service => test_firewall_config
          }

          @remote_config = {
            :FirewallService => same_firewall_config,
            :NatService => different_nat_config
          }

          @proposed_config = EdgeGateway::EdgeGatewayConfiguration.new(@test_config, @remote_config)
        end

        it "does not require update" do
          expect(@proposed_config.update_required?).to be_false
        end

        it "there is no proposed config" do
          expect(@proposed_config.update_required?).to be_false

          expect(@proposed_config.config.empty?).to be_true
        end

      end

      context "no service config is present" do

        before(:each) do
          @edge_gateway_id = "1111111-7b54-43dd-9eb1-631dd337e5a7"
          @edge_gateway = double(:edge_gateway,
            :vcloud_gateway_interface_by_id => {
              Network: {
                :name => 'ane012345',
                :href => 'https://vmware.example.com/api/admin/network/01234567-1234-1234-1234-0123456789aa'
              }
            })
            Vcloud::Core::EdgeGateway.stub(:get_by_name).with(@edge_gateway_id).and_return(@edge_gateway)

          @test_config = {
            :gateway => @edge_gateway_id,
          }

          @remote_config = {
            :FirewallService => different_firewall_config,
            :NatService => different_nat_config
          }

          @proposed_config = EdgeGateway::EdgeGatewayConfiguration.new(@test_config, @remote_config)
        end

        it "does not require update" do
          expect(@proposed_config.update_required?).to be_false
        end

        it "there is no proposed config" do
          expect(@proposed_config.update_required?).to be_false

          expect(@proposed_config.config.empty?).to be_true
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
            :network_id => "01234567-1234-1234-1234-0123456789ab",
            :rule_type => "DNAT",
            :translated_ip => "10.10.1.2-10.10.1.3",
            :translated_port => "3412",
            :original_ip => "192.0.2.58",
            :original_port => "3412",
            :protocol =>"tcp"
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
    end
  end
end
