# Marble Addons

Additional files for Linux distribution running on Xiaomi POCO F5 / Redmi Note 12 Turbo, including:
- Proprietary firmware files extracted from official stock firmware.
- Services, rules and configurations for different hardwares.

## Dependencies

These packages should be present in order to build.
```
make curl tar sha256sum meson ninja gcc ar strip ranlib valgrind json-c
```

### Debian

```sh
sudo apt update
sudo apt install build-essential curl tar coreutils meson ninja-build valgrind libjson-c-dev
```

`build-essential` provides `make`, `gcc`, `ar`, `strip`, and `ranlib`.

## Build and install

```
make build
sudo make install
```

## Note

All features should work properly after installing. For cellular, additional packages also need to be installed:

### Debian

```sh
apt-get install \
	81voltd \
	libqmi-utils \
	modemmanager \
	protection-domain-mapper \
	qcom-phone-utils \
	qrtr-tools \
	rmtfs \
	tqftpserv
```

## Credit

All thanks to [Tatsuki Tanaka](https://github.com/iLtanaka) for his great work in porting postmarketOS to Marble.

Proprietary firmware binaries copyright Qualcomm Technologies, Inc. and Xiaomi Inc.
