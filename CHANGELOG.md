## 2.0.0 (2015-01-22)

   - Update vCloud Core to 1.0.0 since the API is now stable.
   - Update vcloud-tools-tester to 1.0.0 since the API is now stable.

## 1.4.0 (2014-12-03)

Features:

 - Update vCloud Core to 0.14.0 to improve speed of integration tests.
 - Update vCloud Core to 0.16.0 for `vcloud-logout` utility.

## 1.3.0 (2014-10-14)

Features:

  - Upgrade dependency on vCloud Core to 0.13.0. An error will now be raised if
    your `FOG_CREDENTIAL` environment variable does not match the information
    stored against a vCloud Director session referred to by `FOG_VCLOUD_TOKEN`,
    so as to guard against accidental changes to the wrong vCloud Director
    organization.

## 1.2.0 (2014-09-11)

Features:

  - Upgrade dependency on vCloud Core to 0.11.0 which prevents plaintext
    passwords in FOG_RC. Please use tokens via vcloud-login as per
    the documentation: http://gds-operations.github.io/vcloud-tools/usage/

## 1.1.0 (2014-08-11)

Features:

  Update to vCloud Core 0.10.0 for the following:

  - New vcloud-login tool for fetching session tokens without the need to
    store your password in a plaintext FOG_RC file.
  - Deprecate the use of :vcloud_director_password in a plaintext FOG_RC
    file. A warning will be printed to STDERR at load time. Please use
    vcloud-login instead.

## 1.0.2 (2014-07-14)

Bugfix:

  - Update the dependency on vCloud Core to version 0.6.0 to avoid dependency issues.

## 1.0.1 (2014-06-13)

Bugfixes:

  - The NAT schema incorrectly allowed 'tcp+udp' as a valid protocol which would
  lead to a HTTP 500 response from the API. The schema now accepts the correct value,
  'tcpudp'. Thanks to @abridgett for discovering and fixing this.

## 1.0.0 (2014-06-04)

Features:

  - `vcloud-edge-configure` now prints diff output. Colour is optional.
    Defaults to off when STDOUT is redirected.
  - `vcloud-edge-configure --dry-run` new argument to print the diff without
    modifying the remote edge gateway.
  - `vcloud-edge-configure --version` now only returns the version string
    and no usage information.
  - A side effect of changes to the executable means that exceptions from
    Vcloud::EdgeGateway and Vcloud::Core will now result in a stacktrace
    being returned by the CLI, which we'll retain for now until we refine
    the error messages.

API changes:

  - Vcloud::EdgeGateway::Configure returns a hash, keyed by service name, of
    HashDiff#diff arrays. It will be empty if there are no differences.
  - Vcloud::EdgeGateway::Configure#update takes a `dry_run` argument which
    defaults to false. When set to true it won't update the remote Edge GW.

Bugfixes:

  - The `vcloud-configure-edge` command has been renamed to `vcloud-edge-configure`.

## 0.5.0 (2014-05-15)

Bugfixes:

  - Don't set a load balancer healthcheck URI for healthchecks using protocols other than HTTP

## 0.4.0 (2014-05-12)

Features:

  - Allow config files to be rendered from [Mustache](http://mustache.github.io/)
    templates so that common configs can be re-used across environments with
    differences represented as variables.

## 0.3.0 (2014-05-01)

Features:

  - Depend on version 0.2.0 of vcloud-core which introduces breaking changes to namespacing

## 0.2.4 (2014-05-01)

  - Use pessimistic version dependency for vcloud-core

## 0.2.3 (2014-04-22)

Bugfixes:

  - Requires vCloud Core v0.0.12 which fixes issue with progress bar falling over when progress is not returned

Features:

  - Now uses the config loader and validator in vcloud-core rather than its own duplicate.
  - Require fog v1.21 to allow use of FOG_VCLOUD_TOKEN via ENV as an alternative to a .fog file

Documentation credits:

  - Thanks to @Azulinho who added some example configuration.

## 0.2.2 (2014-03-05)

Bugfixes:

  - Default healthcheck URI is now '/'. Previous default caused incorrect 'OPTIONS *' query [#66941992]

## 0.2.1 (2014-02-27)

Bugfixes:

  - Now handles firewall rules with 'protocol: any' correctly [#66591522]

## 0.2.0 (2014-02-21)

Features:

  - Add very basic CLI. Only configures - does not yet diff

## 0.1.0 (2014-02-20)

Features:

  - Add LoadBalancerService configuration management

## 0.0.2 (2014-02-14)

  - First release of gem
  - Supports configuration of Firewall Service and Nat Service

