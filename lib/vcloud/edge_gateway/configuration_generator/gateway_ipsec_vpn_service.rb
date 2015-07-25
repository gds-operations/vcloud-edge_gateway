module Vcloud
  module EdgeGateway
    module ConfigurationGenerator

      class GatewayIpsecVpnService
        def initialize input_config
          @input_config = input_config
        end

        def generate_fog_config
          if @input_config
            gateway_ipsec_vpn_service = {}
            gateway_ipsec_vpn_service[:IsEnabled] = @input_config.key?(:enabled) ? @input_config[:enabled].to_s : 'true'
            gateway_ipsec_vpn_service[:Tunnel] = populate_vpn_tunnels
            gateway_ipsec_vpn_service
          end
        end

        def populate_vpn_tunnels
          tunnels = @input_config[:tunnels]
          tunnels.collect do |tunnel|
            new_tunnel = populate_tunnel(tunnel)
            new_tunnel
          end
        end

        def populate_tunnel(tunnel)
          vpn_tunnel = {}
          vpn_tunnel[:Name] = tunnel[:name]
          vpn_tunnel[:Description] = tunnel[:description]
          vpn_tunnel[:IpsecVpnLocalPeer] = {
            :Id => tunnel[:ipsec_vpn_local_peer][:id],
            :Name => tunnel[:ipsec_vpn_local_peer][:name]
          }
          vpn_tunnel[:PeerIpAddress] = tunnel[:peer_ip_address]
          vpn_tunnel[:PeerId] = tunnel[:peer_id]
          vpn_tunnel[:LocalIpAddress] = tunnel[:local_ip_address]
          vpn_tunnel[:LocalId] = tunnel[:local_id]
          vpn_tunnel[:PeerSubnet] = {
            :Name => tunnel[:peer_subnet][:name],
            :Gateway => tunnel[:peer_subnet][:gateway],
            :Netmask => tunnel[:peer_subnet][:netmask]
          }
          vpn_tunnel[:SharedSecret] = tunnel[:shared_secret]
          vpn_tunnel[:SharedSecretEncrypted] = tunnel[:shared_secret_encrypted] if tunnel.key?(:shared_secret_encrypted)
          vpn_tunnel[:EncryptionProtocol] = tunnel[:encryption_protocol]
          vpn_tunnel[:Mtu] = tunnel[:mtu]
          vpn_tunnel[:IsEnabled] = tunnel[:enabled]
          tunnel[:local_subnets].each do |subnet|
            vpn_tunnel[:LocalSubnet] = [{
             :Name => subnet[:name],
             :Gateway => subnet[:gateway],
             :Netmask => subnet[:netmask]
            }]
          end
          vpn_tunnel
        end

      end
    end
  end
end
