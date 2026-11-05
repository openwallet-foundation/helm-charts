## [0.7.0](https://github.com/openwallet-foundation/helm-charts/compare/didcomm-mediator-credo-0.6.5...didcomm-mediator-credo-0.7.0) (2026-11-05)

### ⚠ BREAKING CHANGES

* **didcomm-mediator-credo:** environment must use the Credo 0.7 mediator's variable names (see 'Upgrading
from chart 0.6.x' in the README), deployments with a PostgreSQL wallet must set
ASKAR__DATABASE__TYPE=postgres and persistence.enabled=false, and Firebase must be enabled with
pushNotifications.firebase.enabled.

Signed-off-by: Emiliano Suñé <2395873+esune@users.noreply.github.com>

* fix(didcomm-mediator-credo): default the ingress network policy namespace selector to a map

The default was an empty list, so overriding it with labels made Helm warn that a map can't
replace a list and drop the default. An empty map keeps the same behaviour without the warning.

Signed-off-by: Emiliano Suñé <2395873+esune@users.noreply.github.com>

### Features

* **didcomm-mediator-credo:** chart updates for new major release ([#150](https://github.com/openwallet-foundation/helm-charts/issues/150)) ([c299017](https://github.com/openwallet-foundation/helm-charts/commit/c29901770e59119eb0e5343b0b489e226e41883e))
## [0.6.5](https://github.com/openwallet-foundation/helm-charts/compare/didcomm-mediator-credo-0.6.4...didcomm-mediator-credo-0.6.5) (2026-07-08)
## [0.6.4](https://github.com/openwallet-foundation/helm-charts/compare/didcomm-mediator-credo-0.6.3...didcomm-mediator-credo-0.6.4) (2026-02-25)
## [0.6.3](https://github.com/openwallet-foundation/helm-charts/compare/didcomm-mediator-credo-0.6.2...didcomm-mediator-credo-0.6.3) (2026-02-17)
## [0.6.2](https://github.com/openwallet-foundation/helm-charts/compare/didcomm-mediator-credo-0.6.1...didcomm-mediator-credo-0.6.2) (2026-02-05)
## [0.6.1](https://github.com/openwallet-foundation/helm-charts/compare/didcomm-mediator-credo-0.6.0...didcomm-mediator-credo-0.6.1) (2026-01-16)
## [0.6.0](https://github.com/openwallet-foundation/helm-charts/compare/didcomm-mediator-credo-0.5.0...didcomm-mediator-credo-0.6.0) (2026-01-08)

### Features

* Update mediator image to b17a075 ([#78](https://github.com/openwallet-foundation/helm-charts/issues/78)) ([65b7175](https://github.com/openwallet-foundation/helm-charts/commit/65b71758f7466895bd53dca2f31e7dea090092f8))
## [0.5.0](https://github.com/openwallet-foundation/helm-charts/compare/didcomm-mediator-credo-0.4.0...didcomm-mediator-credo-0.5.0) (2026-01-05)

### Features

* Update mediator version to 0c5db35 ([#73](https://github.com/openwallet-foundation/helm-charts/issues/73)) ([7135dd4](https://github.com/openwallet-foundation/helm-charts/commit/7135dd4bae13390f596f66e797db8828e2d36e2b))
## [0.4.0](https://github.com/openwallet-foundation/helm-charts/compare/didcomm-mediator-credo-0.3.3...didcomm-mediator-credo-0.4.0) (2025-12-12)

### Features

* Upgrade to multi-firebase image and update secrets ([#62](https://github.com/openwallet-foundation/helm-charts/issues/62)) ([335e7c4](https://github.com/openwallet-foundation/helm-charts/commit/335e7c469ea7b0ec3d5f49e6c1a8004bd45d9eb5))
##  (2025-10-21)

### Features

* Improved secret and label management ea7c298

##  (2025-10-08)

### Features

* add default image tag to values c267cca
* Added startup probe, tweaked delays for liveness and readiness probes 630af96
* **didcomm-mediator-credo:** Added ci values bf996bd
* **didcomm-mediator-credo:** Added didcomm-mediator-credo chart ae7f683
* **didcomm-mediator-credo:** Minor tweaks f263de4
* disable mediator ingress by default cc5e73c
* update ci settings 47ff616

##  (2025-10-07)

### Features

* **didcomm-mediator-credo:** Added ci values bf996bd
* **didcomm-mediator-credo:** Added didcomm-mediator-credo chart ae7f683
* **didcomm-mediator-credo:** Minor tweaks f263de4
