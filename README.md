# vCloud Edge Gateway Configuration Tool

vCloud Edge Gateway is a tool and Ruby library that supports automated
provisiong of a VMware vCloud Director Edge Gateway appliance. It depends on
[vCloud Core](https://github.com/alphagov/vcloud-core) and uses
[Fog](https://fog.io) under the hood

## Installation

Add this line to your application's Gemfile:

    gem 'vcloud-edge_gateway'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install vcloud-edge_gateway

## Usage

To configure an Edge Gateway:

    $ vcloud-configure-edge input.yaml


## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request


### Configure edge gateway services

You can configure following services on an existing edgegateway using
`vcloud-configure-edge`.

- firewall_service
- nat_service
- load_balancer_service

The `vcloud-configure-edge` tool takes an input YAML file describing one
or more of these services, and intelligently updates the edge gateway
configuration to match.

Specifically:

* A given service will not be reconfigured if its input configuration matches
  the live configuration.
* If a service is not defined in the input config, it will not be updated on
  the remote edge gateway
* If more than one service is defined and have changed, then all changed
  services will be updated in the same API request.

#### firewall_service

The edge gateway firewall service offers basic inbound and outbound stateful
IPv4 firewall rules, applied on top of a default policy.

We default to the global firewall policy being 'drop', and each individual
rule to be 'allow'. Rules are applied in order, with the last match winning.

Each rule has the following form:

```
 - description: "Description of your rule"
   destination_port_range: "53"  # defaults to 'Any'
   destination_ip: "192.0.2.15"
   source_ip: "Any"
   source_port_range: "1024-65535"  # defaults to 'Any'
   protocol: 'udp' # defaults to 'tcp'
   policy: 'allow'  # defaults to 'drop'
```

Rule fields have the following behaviour

* `policy` defaults to 'allow', can also be 'drop'.
* `protocol` defaults to 'tcp'. Can be 'icmp', 'udp', 'tcp+udp' or 'any'
* `source_port_range` and `destination_port_range` can be `Any` (default),
  a single port number (eg '443'), or a port range such as '10000-20000'
* `source_ip` and `destination_ip` have no default. They can be one of:
  * `Any` to match any address.
  * `external`, or `internal` to refer to addresses on the respective 'sides'
   of the edge gateway.
  * A single IP address, such as `192.0.2.44`
  * A CIDR range, eg `192.0.2.0/24`
  * A hyphened range, such as `192.0.2.50-192.0.2.60`

#### nat_service

The edge gateway NAT service offers simple stateful Source-NAT and
Destination-NAT rules.

SNAT rules take a source IP address range and 'Translated IP address'. The translated
address is generally the public address that you wish traffic to appear to be
coming from. SNAT rules are typically used to enable outbound connectivity from
a private address range behind the edge. The UUID of the external network that
the traffic should appear to come from must also be specified, eg:

A SNAT rule has the following form:

```
 - rule_type: 'SNAT'
   network_id: '12345678-1234-1234-1234-1234567890bb' # id of EdgeGateway external network
   original_ip: "10.10.10.0/24"  # internal IP range
   translated_ip: "192.0.2.100
```

* `original_ip` can be a single IP address, a CIDR range, or a hyphenated
  IP range.
* `network_id` must be the UUID of the network on which the `translated_ip` sits.
   This can be found using the `vcloud-walk edgegateways` tool.
* `translated_ip` must be an available address on the network specified by
   `network_id`


DNAT rules translate packets addressed to a particular destination IP (and
typically port) and translate it to an internal address - they are usually
defined to allow external hosts to connect to services on hosts with private IP
addresses.

A DNAT rule has the following form, and translates packets going to the
`original_ip` (and `original_port`) to the `translated_ip` and
`translated_port` values.

```
- rule_type: 'DNAT'
  network_id: '12345678-1234-1234-1234-1234567890bb' # id of EdgeGateway external network
  original_ip: "192.0.2.98" # Useable address on external network
  original_port: "22"       # external port
  translated_ip: "10.10.10.10"  # internal address to DNAT to
  translated_port: "22"
```

* `network_id` specifies the UUID of the external network that packets are
  translated from.
* `original_ip` is an IP address on the external network above.

#### load_balancer_service


### Debug output

Set environment variable DEBUG=true and/or EXCON_DEBUG=true to see Fog debug info.

### References

* [vCloud Director Edge Gateway documentation](http://pubs.vmware.com/vcd-51/topic/com.vmware.vcloud.admin.doc_51/GUID-ADE1DCAB-874F-45A9-9337-1E971DAC0F7D.html)
