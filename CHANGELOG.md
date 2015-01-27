# Changelog

## 1.3.0

* Enhancements
  * Add support for AWS VPC

## 1.2.0

* Enhancements
  * Added `HolePunch.apply` to apply security groups to EC2.
  * Added `HolePunch.defined?` to test if a list of security groups are defined in a SecurityGroups file.
  * Added `HolePunch.select_undefined` to return a list of desired security groups not defined in a SecurityGroups file.

## 1.1.0

* Enhancements
  * Added `service` declaration for specifying a composite of security groups.
  * `holepunch` CLI can now output the groups for a service
  * Added `HolePunch.service_groups` API call for querying the groups of a service.

## 1.0.1

* Bug Fixes
  * Option parser was incorrectly looking for `--region` instead of `--aws-region`

## 1.0.0

* Initial release
