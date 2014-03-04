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


###Configure edge gateway services

You can configure following services on an existing edgegateway using
``vcloud-configure-edge``.

- FirewallService
- NatService
- LoadBalancerService

###How to configure:

###Examples:

### Debug output

Set environment variable DEBUG=true and/or EXCON_DEBUG=true to see Fog debug info.
