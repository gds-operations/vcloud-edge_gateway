require 'spec_helper'

module Vcloud
  describe "vpn service schema validation" do
    context "validate vpn tunnel" do
      it "validate ok if only mandatory fields are provided" do
        vpn_tunnel = {
          name: 'badger',
          rule_type: 'DNAT',
          ipsec_vpn_local_peer: {
            id: '1223-123UDH-66666',
            name: 'hamster'
          },
          local_id: '202UB-9602-UB630',
          peer_id: '1223-123UDH-XXXXX',
          peer_ip_address: '172.16.3.73',
          local_ip_address: '10.10.0.1',
          peer_subnets: [{
            name: '192.168.0.0/21',
            gateway: '192.168.0.0',
            netmask: '255.0.0.0'
          }],
          encryption_protocol: 'AES',
          mtu: 9800,
          local_subnets: [{
            name: 'expelliarmus',
            gateway: '192.168.90.254',
            netmask: '255.255.255.0'
          }]
        }
        validator = Vcloud::Core::ConfigValidator.validate(:base, vpn_tunnel, Vcloud::EdgeGateway::Schema::VPN_RULE)
        expect(validator.valid?).to be true
        expect(validator.errors).to be_empty

      end

      context "mandatory field validation" do
        before(:each) do
          @vpn_tunnel = {
            name: 'badger',
            rule_type: 'DNAT',
            ipsec_vpn_local_peer: {
              id: '1223-123UDH-66666',
              name: 'hamster'
            },
            local_id: '202UB-9602-UB630',
            peer_id: '1223-123UDH-XXXXX',
            peer_ip_address: '172.16.3.73',
            local_ip_address: '10.10.0.1',
            peer_subnets: [{
              name: '192.168.0.0/21',
              gateway: '192.168.0.0',
              netmask: '255.0.0.0'
            }],
            encryption_protocol: 'AES',
            mtu: 9800,
            local_subnets: [{
              name: 'expelliarmus',
              gateway: '192.168.90.254',
              netmask: '255.255.255.0'
            }]
          }
        end
        mandatory_fields = [:name, :rule_type, :ipsec_vpn_local_peer, :local_id,
                            :peer_id, :peer_ip_address, :local_ip_address,
                            :peer_subnets, :encryption_protocol, :mtu, :local_subnets]
        mandatory_fields.each do |mandatory_field|
          it "should error since mandatory field #{mandatory_field} is missing" do
            @vpn_tunnel.delete(mandatory_field)
            validator = Vcloud::Core::ConfigValidator.validate(:base, @vpn_tunnel, Vcloud::EdgeGateway::Schema::VPN_RULE)
            expect(validator.valid?).to be false
            expect(validator.errors).to eq(["base: missing '#{mandatory_field}' parameter"])
          end
        end
      end

      it "should accept optional fields: original_port, translated_port and protocol as input" do
         vpn_tunnel = {
           name: 'badger',
           rule_type: 'DNAT',
           ipsec_vpn_local_peer: {
             id: '1223-123UDH-66666',
             name: 'hamster'
           },
           local_id: '202UB-9602-UB630',
           peer_id: '1223-123UDH-XXXXX',
           peer_ip_address: '172.16.3.73',
           local_ip_address: '10.10.0.1',
           peer_subnets: [{
             name: '192.168.0.0/21',
             gateway: '192.168.0.0',
             netmask: '255.0.0.0'
           }],
           encryption_protocol: 'AES',
           mtu: 9800,
           local_subnets: [{
             name: 'expelliarmus',
             gateway: '192.168.90.254',
             netmask: '255.255.255.0'
           }],
          description: 'foobarbaz'
         }
        validator = Vcloud::Core::ConfigValidator.validate(:base, vpn_tunnel, Vcloud::EdgeGateway::Schema::VPN_RULE)
        expect(validator.valid?).to be true
        expect(validator.errors).to be_empty
      end
    end

  end
end
