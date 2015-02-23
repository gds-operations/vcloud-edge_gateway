require 'spec_helper'

module Vcloud
  describe 'static_routing_service_schema_validations' do
    context 'source and destination ips' do
      it 'should error if network or next_hop IPs are invalid' do
        config = {
          static_routes: [
            {
              name: 'Some Name',
              network: '10.10.10.10/256',
              next_hop: '192.1',
              apply_on: 'interface'
            }
          ]
        }
        validator = Vcloud::Core::ConfigValidator.validate(:base, config, Vcloud::EdgeGateway::Schema::STATIC_ROUTING_SERVICE)
        expect(validator.valid?).to be_false
        expect(validator.errors).to eq([
                                        "network: 10.10.10.10/256 is not a valid IP address range. Valid values can be IP address, CIDR, IP range, 'Any','internal' and 'external'.",
                                        "next_hop: 192.1 is not a valid ip_address",
                                       ])
      end

      it 'should validate OK if source_ip/destination_ip are valid IPs' do
        config = {
          static_routes: [
            {
              name: 'Some Name',
              network: '10.10.10.0/24',
              next_hop: '192.168.0.1',
              apply_on: 'interface'
            }
          ]
        }
        validator = Vcloud::Core::ConfigValidator.validate(:base, config, Vcloud::EdgeGateway::Schema::STATIC_ROUTING_SERVICE)
        expect(validator.valid?).to be_true
      end
    end
  end
end
