# vCloud Edge Gateway

vCloud Edge Gateway is a CLI tool and Ruby library that supports automated
provisiong of a VMware vCloud Director Edge Gateway appliance. It depends on
[vCloud Core](https://rubygems.org/gems/vcloud-core) and uses
[Fog](http://fog.io) under the hood.

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

To use [mustache](http://mustache.github.io) templates so that rulesets can
be re-used between environments:

    $ vcloud-configure-edge --template-vars vars.yaml input.yaml.mustache

## Credentials

vCloud Edge Gateway is based around [fog](http://fog.io/). To use it you'll need to give it
credentials that allow it to talk to a vCloud Director environment.

1. Create a '.fog' file in your home directory.

  For example:

      test_credentials:
        vcloud_director_host: 'host.api.example.com'
        vcloud_director_username: 'username@org_name'
        vcloud_director_password: ''

2. Obtain a session token. First, curl the API:

        curl -D- -d '' \
            -H 'Accept: application/*+xml;version=5.1' -u '<username>@<org_name>' \
            https://<host.api.example.com>/api/sessions

  This will prompt for your password.

  From the headers returned, the value of the `x-vcloud-authorization` header is your
  session token, and this will be valid for 30 minutes idle - any activity will extend
  its life by another 30 minutes.

3. Specify your credentials and session token at the beginning of the command. For example:

        FOG_CREDENTIAL=test_credentials \
            FOG_VCLOUD_TOKEN=AAAABBBBBCCCCCCDDDDDDEEEEEEFFFFF= \
            vcloud-configure-edge input.yaml

  You may find it easier to export one or both of the values as environment variables.

  **NB** It is also possible to sidestep the need for the session token by saving your
  password in the fog file. This is **not recommended**.


### Configure edge gateway services

You can configure the following services on an existing edgegateway using
`vcloud-configure-edge`.

- firewall_service
- nat_service
- load_balancer_service

NB: DHCP and VPN Services are not yet supported by the Fog platform underneath.
Support for these is being considered.

The `vcloud-configure-edge` tool takes an input YAML file describing one
or more of these services and updates the edge gateway configuration to match,
obeying the following rules:

* A given service will not be reconfigured if its input configuration matches
  the live configuration - to prevent unneccessary service reloads.
* If a service is not defined in the input config, it will not be updated on
  the remote edge gateway - to permit per-service configurations.
* If more than one service is defined and have changed, then all changed
  services will be updated in the same API request.

#### firewall_service

The edge gateway firewall service offers basic inbound and outbound
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
* `source_ip` and `destination_ip` *must* be specified.
* `source_ip` and `destination_ip` can be one of:
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
the traffic should appear to come from must also be specified, as per the
`network_id` field below.

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
  Instructions are in the [finding external network
  details](#finding-external-network-details-from-vcloud-walk) section below.
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

The load balancer service comprises two sets of configurations: 'pools' and
'virtual_servers'. These are coupled together to form load balanced services:

* A virtual_server provides the front-end of a load balancer - the port and
  IP that clients connect to.
* A pool is a collection of one or more back-end nodes (IP+port combination)
  that traffic is balanced across.
* Each virtual_server entry specifies a pool that serves requests destined to
  it.
* Multiple virtual_servers can specify the same pool (to run the same service
  on different FQDNs, for example)
* virtual_servers define any 'session persistence' information, if sessions
  are required to stick to the same pool member. (Session persistence is not currently supported by this tool.)
* pools define 'member healthchecks', and so are aware of the health of their
  member nodes.

A typical load balancer configuration (for one service, mapping 192.0.2.0:80 to
port 8080 on three servers) would look something like:

```
load_balancer_service:

  pools:
  - name: 'example-pool-1'
    description: 'A pool balancing traffic across backend nodes on port 8080'
    service:
      http:
        port: 8080
    members:
    - ip_address: 10.10.10.11
    - ip_address: 10.10.10.12
    - ip_address: 10.10.10.13

  virtual_servers:
  - name: 'example-virtual-server-1'
    description: 'A virtual server connecting to example-pool-1'
    ip_address: 192.0.2.10
    network: '12345678-1234-1234-1234-123456789012' # id of external network
    pool: 'example-pool-1' # must refer to a pool name detailed above
    service_profiles:
      http:  # protocol to balance, can be tcp/http/https.
        port: '80'  # external port
```

The vCloud Director load balancer service is quite basic, but supports the following:

* Layer 7 balancing of HTTP traffic
* Balancing of HTTPS traffic (though no decryption is possible, so this is
  purely level-4 based)
* Layer 4 balancing of arbitrary TCP traffic.
* URI-based healthchecks of backend nodes
* Several balancing algorithms, such as 'round robin', and 'least connections'
* Ability to persist sessions to the same backend member node, via a variety of
  means (eg HTTP cookie value, SSL session ID, source IP hash).

`vcloud-configure-edge` supports all of the above features.

It is also worth noting that the vCloud Director load balancer *does not support*:

* In vCD 5.1, TCP and HTTPS layer-4 balancing are based on TCP port forwarding.
  There is no NAT in the mix, so the backend pools see the IP address/port of
  the edge rather than the remote host.
* There is no SSL offloading/decryption possible on the device, so traffic
  inspection of HTTPS is not feasible.

Rather unusually, each virtual server and pool combination can handle traffic
balancing for HTTP, HTTPS, and a single TCP port simultaneously. For example:

```
load_balancer_service:
  pools:
  - name: 'example-multi-protocol-pool-1'
    description: 'A pool balancing HTTP, HTTPS, and SMTP traffic'
    service:
      http: {}
      https: {}
      tcp:
        port: 25
    members:
    - ip_address: 10.10.10.14
    - ip_address: 10.10.10.15
  virtual_servers:
  - name: 'example-multi-protocol-virtual-server-1'
    description: 'A virtual server connecting to example-pool-1'
    ip_address: 192.0.2.11
    network: '12345678-1234-1234-1234-123456789012'
    pool: 'example-multi-protocol-pool-1'
    service_profiles:
      http: {}
      https: {}
      tcp:
        port: 25
```

The above is particularly useful for services that require balancing of HTTP
and HTTPS traffic together.

#### load_balancer_service pool entries in detail

Each pool entry consists of:

* a pool name, and optional description
* a 'service' section - which protocol(s) to balance, and how to balance them.
* a 'members' list - which backend nodes to use.

For example:

```
name: test-pool-1
description: Balances HTTP and HTTPS
service:
  http: {}
  https: {}
members:
- ip_address: 10.10.10.11
- ip_address: 10.10.10.12
  weight: 10
```

Here we have:

* HTTP and HTTPS traffic balanced across 10.10.10.11 and 10.10.10.12.
* member 10.10.10.11 has a default `weight` of 1
* member 10.10.10.12 has a `weight` of 10, so will receive 10x the traffic of
  10.10.10.11
* http and https services are using all defaults, which means:
  * they use standard ports (80 for HTTP, 443 for HTTPS)
  * they will use 'round robin' balancing
  * HTTP service will 'GET /' from each node to check its health
  * HTTPS service will check 'SSL hello' response to confirm its health.

Service entries are the most complex, due to the available options on
a per-service basis. The defaults we provide are suitable for most situations,
but for more infomation see below.

A more complete HTTP service entry looks like:

```
service:
  http:
    port: 8080
    algorithm: 'ROUND_ROBIN'  # can also be 'LEAST_CONNECTED', 'IP_HASH', 'URI'
    health_check:
      port: 8081            # port to check health on, if not service port above.
      uri: /healthcheck     # for HTTP, the URI to check for 200/30* response
      protocol: HTTP        # the protocol to talk to health check service: HTTP, SSL, TCP
      health_threshold:  2  # how many checks to success before reenabling member
      unhealth_threshold: 3 # how many checks to fail before disabling member
      interval: 5           # interval between checks
      timeout: 15           # how long to wait before assuming healthcheck has failed

```

See [the vCloud Director Admin Guide](http://pubs.vmware.com/vcd-51/topic/com.vmware.vcloud.admin.doc_51/GUID-C12B3954-155F-48AF-9855-E0DE026752D0.html)
for more details on configuring Pool entries.

#### load_balancer_service virtual_server entries in detail

Each virtual_server entry must consist of:

* a virtual_server name, and optional description
* a 'service_profiles' section: which protocol(s) to handle
* a `network` reference - the UUID of the network which the ip_address sits on.
* a backend `pool` to use, referenced by name

For example:

```
name: test-virtual_server-1
description: Public facing side of test-pool-1
pool: test-pool-1
ip_address: 192.0.2.55  # front-end IP address, usually external
network: 12345678-1234-1234-1234-1234567890aa # UUID of network containing ip_address
service_profiles:
  http: { port: 8080 } # override default port 80
  https: { }  # port defaults to 443
```

Limited session persistence configurations can be defined in the virtual_server
service_profiles section, if it is required that traffic 'stick' to the backend
member that it originally was destined for. The available persistence mechanisms
change based on which service is being handled:

For the 'http' service_profile, we can use Cookie based persistence:

```
  http:
    port: 8080
    persistence:
      method: COOKIE
      cookie_name: JSESSIONID # can be any cookie name string
      cookie_method: APP      # can be one of INSERT, PREFIX, or APP
```


For the 'https' service_profile, we can use SSL Session ID based persistence:

```
  https:
    port: 8443
    persistence:
      method: SSL_SESSION_ID
```

There is no persistence option for 'tcp' service_profiles.

See [the vCloud Director Admin Guide](http://pubs.vmware.com/vcd-51/topic/com.vmware.vcloud.admin.doc_51/GUID-EC5EE5F9-1A2C-4609-9347-4C3143727704.html)
for more details on configuring VirtualServer entries.

### Finding external network details from vcloud-walk

You can find the network UUID and external address allocations using [vCloud
Walker](https://rubygems.org/gems/vcloud-walker):

To do this, do:

```
export FOG_CREDENTIAL={crediental-tag-for-your-organization}
vcloud-walk edgegateways > edges.out
```

`edges.out` will contain the complete configuration of all edge gateways in
your organization. Find the edge gateway you are interested in by searching for
its name, then look for a GatewayInterface section that has an InterfaceType of
'uplink'. This should define:

* a 'href' element in a Network section. The UUID at the end of this href is
  what you need.
* an IpRange section with a StartAddress and EndAddress -- these define the
  addresses that you can use for services on this external network.

You can use [jq](http://stedolan.github.io/jq/) to make this easier:
```
cat edges.out | jq '
  .[] | select(.name == "NAME_OF_YOUR_EDGE_GATEWAY")
      | .Configuration.GatewayInterfaces.GatewayInterface[]
      | select(.InterfaceType == "uplink")
      | ( .Network.href, .SubnetParticipation )
      '
```

### Full configuration examples

You can find full configuration examples in the `examples` folder.

## The vCloud API

vCloud Tools currently use version 5.1 of the [vCloud API](http://pubs.vmware.com/vcd-51/index.jsp?topic=%2Fcom.vmware.vcloud.api.doc_51%2FGUID-F4BF9D5D-EF66-4D36-A6EB-2086703F6E37.html). Version 5.5 may work but is not currently supported. You should be able to access the 5.1 API in a 5.5 environment, and this *is* currently supported.

The default version is defined in [Fog](https://github.com/fog/fog/blob/244a049918604eadbcebd3a8eaaf433424fe4617/lib/fog/vcloud_director/compute.rb#L32).

If you want to be sure you are pinning to 5.1, or use 5.5, you can set the API version to use in your fog file, e.g.

`vcloud_director_api_version: 5.1`

## Debugging

`export EXCON_DEBUG=true` - this will print out the API requests and responses.

`export DEBUG=true` - this will show you the stack trace when there is an exception instead of just the message.

## Testing

Run the default suite of tests (e.g. lint, unit, features):

    bundle exec rake

Run the integration tests (slower and requires a real environment):

    bundle exec rake integration

You need access to a suitable vCloud Director organization to run the integration tests. See the [integration tests
README](/spec/integration/README.md) for further details.

### References

* [vCloud Director Edge Gateway documentation](http://pubs.vmware.com/vcd-51/topic/com.vmware.vcloud.admin.doc_51/GUID-ADE1DCAB-874F-45A9-9337-1E971DAC0F7D.html)

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request


[fog]: http://fog.io/
