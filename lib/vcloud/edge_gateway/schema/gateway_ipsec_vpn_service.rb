module Vcloud
  module EdgeGateway
    module Schema

      VPN_LOCAL_PEER = {
        type: Hash,
        allowed_empty: false,
        internals: {
          id: {
            type: 'string_or_number',
            required: true,
            allowed_empty: false,
          },
          name: {
            type: 'string_or_number',
            required: true,
            allowed_empty: false,
          }
        }
      }

      VPN_SUBNETS =  {
        type: Hash,
        allowed_empty: false,
        internals: {
          name: {
            type: 'string_or_number',
            required: true,
            allowed_empty: false
          },
          gateway: {
            type: 'ip_address_range',
            required: true,
            allowed_empty: false
          },
          netmask: {
            type: 'ip_address_range',
            required: true,
            allowed_empty: false
          }
        }
      }

      VPN_RULE = {
        type: Hash,
        internals: {
          enabled: {type: 'boolean', required: false},
          name: {type: 'string_or_number', required: true},
          description: {type: 'string_or_number', required: false},
          ipsec_vpn_local_peer: {
            type: Hash,
            required: true,
            allowed_empty: false,
            each_element_is: VPN_LOCAL_PEER
          },
          local_id: {type: 'string', required: true, allowed_empty: false},
          peer_id: {type: 'string', required: true, allowed_empty: false},
          peer_ip_address: {type: 'ip_address_range', required: true},
          local_ip_address: {type: 'ip_address_range', required: true, allowed_empty: false},
          peer_subnet: {
            type: Hash,
            required: true,
            allowed_empty: false,
            each_element_is: VPN_SUBNETS
          },
          shared_secret: {type: 'string', required: false, allowed_empty: true},
          shared_secret_encrypted: {type: 'boolean', required: false},
          encryption_protocol: {type: 'string', required: true, acceptable_values: 'AES'},
          mtu: {type: 'string_or_number', required: true},
          local_subnets: {
            type: Array,
            required: true,
            allowed_empty: false,
            each_element_is: VPN_SUBNETS
          },
          rule_type: {type: 'enum', required: true, acceptable_values: ['SNAT', 'DNAT'] }
        }
      }

      GATEWAY_IPSEC_VPN_SERVICE = {
        type: Hash,
        allowed_empty: true,
        required: false,
        internals: {
          enabled: {type: 'boolean', required: false},
          tunnels: {
            type: Array,
            required: false,
            allowed_empty: true,
            each_element_is: VPN_RULE
          }
        }
      }

    end
  end
end
