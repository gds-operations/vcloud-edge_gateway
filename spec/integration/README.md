# Running vCloud Edge Gateway Integration Tests

## Prerequisites

- Access to a suitable vCloud Director organisation.

  **NB** It is not safe to run them against an environment that is in use
  (e.g. production, preview) as many of the tests clear down all config at
  the beginning and/or end to ensure the environment is as the tests expect.

- A config file with the settings configured.

  There is a [template file](spec/integration/vcloud_tools_testing_config.yaml.template) to
  help with this. Copy the template file to `spec/integration/vcloud_tools_testing_config.yaml`
  and update with parameters suitable for your environment.

- You need to include the set-up for your testing environment in your
  [fog file](https://github.com/gds-operations/vcloud-core#credentials).

- The tests use the [vCloud Tools Tester](http://rubygems.org/gems/vcloud-tools-tester) gem.
  You do not need to install this, `bundler` will do this for you.

## Parameters

````
default:                # This is the fog credential that refers to your testing environment, e.g. `test_credential`
  network_1:            # Primary network name
  network_1_id:         # Primary network ID
  network_1_ip:         # Primary network IP
  edge_gateway:         # Edge gateway name
  provider_network:     # Provider (external-facing) network name
  provider_network_id:  # Provider network ID
  provider_network_ip:  # Provider network IP
````

## To run the tests

  `FOG_CREDENTIAL=test_credential bundle exec integration`
