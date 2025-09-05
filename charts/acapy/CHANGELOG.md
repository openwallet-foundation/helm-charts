##  (2025-09-05)

### Features

* render the ingress hostname as template, to allow other charts to specify templated hostnames. ([77cd136](https://github.com/i5okie/owf-helm-charts/commit/77cd13646fb7dec9dcf383efd1432fb6a8db5212))
* set plugin-config path if plugin-config is provided ([ede863c](https://github.com/i5okie/owf-helm-charts/commit/ede863cb3d9fed8ef95f95f0e74827094f0984c1))

### Bug Fixes

* replace missing plugin-config path ([f8c1587](https://github.com/i5okie/owf-helm-charts/commit/f8c15870f9717bcc40702ef434eeb159b2bd7c90))
##  (2025-08-28)

### Features

* set plugin-config path if plugin-config is provided ([ede863c](https://github.com/i5okie/owf-helm-charts/commit/ede863cb3d9fed8ef95f95f0e74827094f0984c1))

### Bug Fixes

* replace missing plugin-config path ([f8c1587](https://github.com/i5okie/owf-helm-charts/commit/f8c15870f9717bcc40702ef434eeb159b2bd7c90))
##  (2025-08-27)

### Features

* rewrite NOTES with relevant information ([c7a2708](https://github.com/i5okie/owf-helm-charts/commit/c7a2708fb3785e1fe878f471aa0a4506ce9be21b))

### Bug Fixes

* admin ingress must point to admin service port ([707ae11](https://github.com/i5okie/owf-helm-charts/commit/707ae11a28fb3b86547254ec6c7281e21efd628a))
##  (2025-08-26)

### Bug Fixes

* correct network policy rendering ([052095b](https://github.com/i5okie/owf-helm-charts/commit/052095b025f90bd5a675e9b414b4e50e9b61f582))
##  (2025-08-22)

### Bug Fixes

* refactor argfile to fix expected formatting ([1f92b9f](https://github.com/i5okie/owf-helm-charts/commit/1f92b9f23a389bbed76697676effe7eb22a132fb))
##  (2025-08-20)

### Features

* move non-secret settings into the argfile ([ab4ad0a](https://github.com/i5okie/owf-helm-charts/commit/ab4ad0aa7fe0f81764d8a148d172f6e91a03d887))
* refactor agent url and websockets url rendering ([2b3be8b](https://github.com/i5okie/owf-helm-charts/commit/2b3be8b3d1a8256d82dc957455dd970bbad6c08e))
* refactor scheme and url setting ([ffa3e23](https://github.com/i5okie/owf-helm-charts/commit/ffa3e23c3ba12be7f63e5ac96f5b0c458cc54f05))
##  (2025-08-15)

### Bug Fixes

* incorrect indentation ([241e03f](https://github.com/i5okie/owf-helm-charts/commit/241e03f52e2e841d94a9051518b1288604cf30b2))
##  (2025-08-15)

### Bug Fixes

* incorrect indentation ([241e03f](https://github.com/i5okie/owf-helm-charts/commit/241e03f52e2e841d94a9051518b1288604cf30b2))
##  (2025-08-14)

### Features

* Add multitenancyConfiguration ([907647e](https://github.com/i5okie/owf-helm-charts/commit/907647e3b0ef5eb550d44f2bae8272cf77bb01fd))
* update image rendering ([05daaef](https://github.com/i5okie/owf-helm-charts/commit/05daaef949e6895ffba858697a581d0187b6ea64))

### Bug Fixes

* fix syntax ([da05514](https://github.com/i5okie/owf-helm-charts/commit/da05514f4c1700129222c6de5d571d526ff8fdd3))
##  (2025-07-28)

### Bug Fixes

* **acapy:** refactor image definition to use dedicated helper function and clean up whitespace ([73fc7da](https://github.com/i5okie/owf-helm-charts/commit/73fc7daa3e64ccb462363705006ab72b229c1f9b))
* **acapy:** update common dependency version to 2.31.3 and increment chart version to 0.1.1 ([c2749e9](https://github.com/i5okie/owf-helm-charts/commit/c2749e9b57c3d2ed3450a66ab40b4972db02fe82))
* **acapy:** update database secret name definition for improved flexibility ([c6a7fce](https://github.com/i5okie/owf-helm-charts/commit/c6a7fceb56ae280543d3231b7af925ce90ae291d))
##  (2025-06-17)

* Add maintainers list to acapy chart 6575f2d
* Add sample ledgers.yml config 93c60ed
* Change default storage type to ReadWriteOnce 558bab1
* Create Acapy Helm Chart (#3599) 56b5393, closes #3599
* Initial acapy changelog 4b93f7d
* Update acapy readme/values f7dc5e6
* Update images and tags to version 1.3.0 (#3708) 5ab784e, closes #3708
* Updated acapy changelog 91c339a
* Updated initial acapy changelog 85e892d



