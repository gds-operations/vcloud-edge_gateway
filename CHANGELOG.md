## Current (unreleased)

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

