#!/bin/sh
set -eu

BASE=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
FIRMWARE=$BASE/firmware
TWEAKS=$BASE/tweaks
OUT=${OUT:-$BASE/marble-addons-plasma_arm64.deb}

command -v dpkg-deb >/dev/null 2>&1 || {
  echo "dpkg-deb is required" >&2
  exit 1
}

WORK=$(mktemp -d)
trap 'rm -rf "$WORK"' EXIT HUP INT TERM
PKG=$WORK/package

install -d "$PKG/DEBIAN"
cat > "$PKG/DEBIAN/control" <<'EOF'
Package: marble-addons-plasma
Version: 1.0.0
Section: admin
Priority: optional
Architecture: arm64
Depends: systemd
Maintainer: Marble Linux Maintainers <marble-linux@localhost>
Description: Xiaomi POCO F5 (marble) specific tweaks for Plasma Mobile
EOF

install -Dm644 "$TWEAKS"/plasma-mobile-marble.conf \
    "$PKG"/usr/lib/systemd/system/plasma-mobile.service.d/50-marble-sensors.conf
install -Dm755 "$TWEAKS"/marble-kwin-boost.sh \
    "$PKG"/usr/libexec/marble-kwin-boost.sh
install -Dm644 "$TWEAKS"/plasma-kwin_wayland-marble.conf \
    "$PKG"/usr/lib/systemd/user/plasma-kwin_wayland.service.d/50-marble-boost.conf

dpkg-deb --root-owner-group --build "$PKG" "$OUT"
echo "wrote $OUT"