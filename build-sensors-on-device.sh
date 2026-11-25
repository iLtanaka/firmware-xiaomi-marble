#!/bin/sh
set -eu

log() {
  printf '[marble-sensors] %s\n' "$*" >&2
}

build_on_device() {
  if [ "$(id -u)" -ne 0 ]; then
    echo "The device build must run as root (invoke through sudo)." >&2
    exit 1
  fi

  if [ "$(dpkg --print-architecture)" != arm64 ]; then
    echo "This script builds packages for Debian arm64 devices only." >&2
    exit 1
  fi

  if [ ! -e /dev/fastrpc-sdsp ]; then
    echo "/dev/fastrpc-sdsp is missing; the SLPI must be running first." >&2
    exit 1
  fi

  if ! command -v hexagonrpcd >/dev/null 2>&1 ||
      ! systemctl cat hexagonrpcd-sdsp.service >/dev/null 2>&1; then
    echo "hexagonrpcd-sdsp.service is missing; install marble-addons first." >&2
    exit 1
  fi

  log "Installing native Debian build dependencies"
  apt-get update
  DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
    build-essential ca-certificates curl meson ninja-build pkg-config \
    libglib2.0-dev libgudev-1.0-dev libqmi-glib-dev libqrtr-glib-dev \
    libprotobuf-c-dev protobuf-c-compiler protobuf-compiler \
    libpolkit-gobject-1-dev python3-gi python3-protobuf libpython3.13-dev

  work=$(mktemp -d)
  trap 'rm -rf "$work"' EXIT HUP INT TERM
  libssc_version=0.4.4
  libssc_sha512=9240970f6a70f4900ef2d8fad337dac815ea2602b3b395943326fb086f59d24dcf59b76bdbc6014ebd3c450eaad5393465ca038c165845ffe99bf8e282a5c170
  proxy_version=3.9
  proxy_sha512=a89c842f8db2a1a36c1c7c990434bb57fd905224459170cba2ec56e79f1272acc4cac4221937704d5e9247f957d86fde716d25e2d1ccb80d88fa643b47edfda6

  log "Downloading libssc $libssc_version"
  curl --fail --location --silent --show-error \
    "https://codeberg.org/DylanVanAssche/libssc/archive/v$libssc_version.tar.gz" \
    --output "$work/libssc.tar.gz"
  printf '%s  %s\n' "$libssc_sha512" "$work/libssc.tar.gz" |
    sha512sum --check --status || {
      echo "libssc source checksum verification failed" >&2
      exit 1
    }

  log "Downloading iio-sensor-proxy $proxy_version"
  curl --fail --location --silent --show-error \
    "https://gitlab.freedesktop.org/hadess/iio-sensor-proxy/-/archive/$proxy_version/iio-sensor-proxy-$proxy_version.tar.gz" \
    --output "$work/iio-sensor-proxy.tar.gz"
  printf '%s  %s\n' "$proxy_sha512" "$work/iio-sensor-proxy.tar.gz" |
    sha512sum --check --status || {
      echo "iio-sensor-proxy source checksum verification failed" >&2
      exit 1
    }

  mkdir "$work/libssc-src" "$work/iio-sensor-proxy-src"
  tar -xzf "$work/libssc.tar.gz" --strip-components=1 -C "$work/libssc-src"
  tar -xzf "$work/iio-sensor-proxy.tar.gz" --strip-components=1 -C "$work/iio-sensor-proxy-src"

  libssc_stage=$work/libssc-stage
  proxy_build=$work/iio-sensor-proxy-build
  package=$work/package

  log "Building libssc for the phone"
  meson setup "$work/libssc-build" "$work/libssc-src" \
    --prefix=/usr \
    --libdir=lib/aarch64-linux-gnu \
    --buildtype=release
  meson compile -C "$work/libssc-build"
  DESTDIR="$libssc_stage" meson install --no-rebuild -C "$work/libssc-build"

  libssc_pc=$libssc_stage/usr/lib/aarch64-linux-gnu/pkgconfig/libssc.pc
  if [ ! -f "$libssc_pc" ]; then
    echo "libssc build did not install its pkg-config file: $libssc_pc" >&2
    exit 1
  fi
  sed -i "s|^prefix=.*|prefix=$libssc_stage/usr|" "$libssc_pc"

  log "Building iio-sensor-proxy with SSC support enabled"
  PKG_CONFIG_PATH="$libssc_stage/usr/lib/aarch64-linux-gnu/pkgconfig${PKG_CONFIG_PATH:+:$PKG_CONFIG_PATH}" \
    meson setup "$proxy_build" "$work/iio-sensor-proxy-src" \
      --prefix=/usr \
      --libdir=lib/aarch64-linux-gnu \
      --buildtype=release \
      -Dssc-support=enabled \
      -Dsystemdsystemunitdir=/usr/lib/systemd/system \
      -Dudevrulesdir=/usr/lib/udev/rules.d \
      -Dtests=false
  PKG_CONFIG_PATH="$libssc_stage/usr/lib/aarch64-linux-gnu/pkgconfig${PKG_CONFIG_PATH:+:$PKG_CONFIG_PATH}" \
    meson compile -C "$proxy_build"

  install -d "$package"
  DESTDIR="$package" meson install --no-rebuild -C "$proxy_build"

  install -d "$package/usr/lib/aarch64-linux-gnu"
  for library in "$libssc_stage"/usr/lib/aarch64-linux-gnu/libssc.so*; do
    if [ ! -e "$library" ] && [ ! -L "$library" ]; then
      echo "libssc runtime library not found in build output: $library" >&2
      exit 1
    fi
    cp -a "$library" "$package/usr/lib/aarch64-linux-gnu/"
  done

  install -Dm644 /dev/stdin "$package/usr/lib/udev/rules.d/90-marble-iio-ssc.rules" <<'EOF'
ACTION!="remove", SUBSYSTEM=="misc", KERNEL=="fastrpc-sdsp*", ENV{IIO_SENSOR_PROXY_TYPE}+="ssc-accel ssc-proximity"
EOF

  install -d "$package/DEBIAN"
  cat > "$package/DEBIAN/control" <<'EOF'
Package: iio-sensor-proxy
Version: 3.9-1marble1
Section: admin
Priority: optional
Architecture: arm64
Depends: libc6, libglib2.0-0t64, libgudev-1.0-0, libpolkit-gobject-1-0, libqmi-glib5, libprotobuf-c1
Maintainer: Marble Linux Maintainers <marble-linux@localhost>
Description: IIO sensor proxy with Qualcomm SSC support for Xiaomi marble
 Built from upstream iio-sensor-proxy with libssc support enabled.
EOF

  package_file=$work/iio-sensor-proxy_3.9-1marble1_arm64.deb
  log "Creating replacement iio-sensor-proxy Debian package"
  dpkg-deb --root-owner-group --build "$package" "$package_file"

  log "Installing SSC-enabled iio-sensor-proxy"
  dpkg --install "$package_file"
  systemctl enable hexagonrpcd-sdsp.service
  systemctl start hexagonrpcd-sdsp.service
  systemctl daemon-reload
  udevadm control --reload-rules
  udevadm trigger --action=add --subsystem-match=misc --sysname-match=fastrpc-sdsp
  udevadm settle
  systemctl restart iio-sensor-proxy.service

  log "Installed sensor proxy and refreshed the FastRPC device"
  udevadm info --query=property --name=/dev/fastrpc-sdsp |
    grep -E '^(IIO_SENSOR_PROXY_TYPE|ACCEL_MOUNT_MATRIX)='
  systemctl --no-pager --full status hexagonrpcd-sdsp.service iio-sensor-proxy.service
  for property in HasAccelerometer HasAmbientLight HasProximity HasCompass; do
    busctl get-property net.hadess.SensorProxy /net/hadess/SensorProxy \
      net.hadess.SensorProxy "$property"
  done
  log "If Plasma was already running, log out and back in so it redetects the sensors."
}

case "${1:-}" in
  --help|-h)
    printf 'Usage: sudo %s\n' "$0"
    printf 'Build and install SSC-enabled iio-sensor-proxy on this device.\n'
    exit 0
    ;;
  "")
    ;;
  *)
    printf 'Usage: sudo %s\n' "$0" >&2
    exit 2
    ;;
esac

build_on_device
