#!/bin/sh
set -eu

log() {
  printf '[marble-addons] %s\n' "$*" >&2
}

log "Building marble-addons package for arm64"

BASE=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
FIRMWARE=$BASE/firmware
TWEAKS=$BASE/tweaks
OUT=${OUT:-$BASE/marble-addons_arm64.deb}

HEXAGONRPC_VERSION=0.5.0
HEXAGONRPC_SHA256=2173985932ab68d8ac593f9954357123bdbbbe9ba5f1b17a098d9cbcec22c5d5

for tool in dpkg-deb curl tar sha256sum meson ninja \
    "${CROSS_COMPILE}gcc" "${CROSS_COMPILE}ar" "${CROSS_COMPILE}strip" "${CROSS_COMPILE}ranlib"; do
  command -v "$tool" >/dev/null 2>&1 || {
    echo "Required build tool not found: $tool" >&2
    exit 1
  }
done

if [ "$ARCH" != arm64 ]; then
  echo "Expected ARCH=arm64, got: $ARCH" >&2
  exit 1
fi

WORK=$(mktemp -d)
trap 'rm -rf "$WORK"' EXIT HUP INT TERM
PKG=$WORK/package

log "Downloading hexagonrpc $HEXAGONRPC_VERSION"
SOURCE_TARBALL=$WORK/hexagonrpc.tar.gz
curl --fail --location --silent --show-error \
  "https://github.com/linux-msm/hexagonrpc/archive/refs/tags/v$HEXAGONRPC_VERSION.tar.gz" \
  --output "$SOURCE_TARBALL"
printf '%s  %s\n' "$HEXAGONRPC_SHA256" "$SOURCE_TARBALL" | sha256sum --check --status || {
  echo "hexagonrpc source checksum verification failed" >&2
  exit 1
}

SOURCE_DIR=$WORK/hexagonrpc
BUILD_DIR=$WORK/hexagonrpc-build
STAGE=$WORK/hexagonrpc-stage
MESON_CROSS_FILE=$WORK/aarch64-cross.ini
mkdir -p "$SOURCE_DIR"
tar -xzf "$SOURCE_TARBALL" --strip-components=1 -C "$SOURCE_DIR"

cat > "$MESON_CROSS_FILE" <<EOF
[binaries]
c = '$(command -v "${CROSS_COMPILE}gcc")'
ar = '$(command -v "${CROSS_COMPILE}ar")'
strip = '$(command -v "${CROSS_COMPILE}strip")'
ranlib = '$(command -v "${CROSS_COMPILE}ranlib")'

[host_machine]
system = 'linux'
cpu_family = 'aarch64'
cpu = 'aarch64'
endian = 'little'

[properties]
needs_exe_wrapper = true
EOF

log "Cross-compiling hexagonrpc for $ARCH"
meson setup "$BUILD_DIR" "$SOURCE_DIR" \
  --cross-file "$MESON_CROSS_FILE" \
  --prefix=/usr \
  --libdir=lib \
  --buildtype=release
meson compile -C "$BUILD_DIR"
DESTDIR="$STAGE" meson install --no-rebuild -C "$BUILD_DIR"

install -d "$PKG/DEBIAN"
cat > "$PKG/DEBIAN/control" <<'EOF'
Package: marble-addons
Version: 1.0.0
Section: admin
Priority: optional
Architecture: arm64
Depends: adduser, systemd, udev, alsa-ucm-conf, iio-sensor-proxy
Maintainer: Marble Linux Maintainers <marble-linux@localhost>
Description: Device-specific addons for Xiaomi POCO F5 (marble)
 Includes hexagonrpcd for SDSP sensor access.
EOF

cat > "$PKG/DEBIAN/preinst" <<'EOF'
#!/bin/sh
set -e

if ! getent group fastrpc >/dev/null; then
	addgroup --system fastrpc
fi

if ! getent passwd fastrpc >/dev/null; then
	adduser --system --ingroup fastrpc --no-create-home \
		--home /var/lib/fastrpc --shell /usr/sbin/nologin fastrpc
fi

exit 0
EOF
chmod 755 "$PKG/DEBIAN/preinst"

### HEXAGONRPCD ###
log "Installing hexagonrpcd, its runtime library, and SDSP unit"
install -Dm755 "$STAGE/usr/bin/hexagonrpcd" "$PKG/usr/bin/hexagonrpcd"
install -d "$PKG/usr/lib"
for library in "$STAGE"/usr/lib/libhexagonrpc.so*; do
  [ -e "$library" ] || [ -L "$library" ] || continue
  cp -a "$library" "$PKG/usr/lib/"
done
install -Dm644 "$STAGE/usr/lib/systemd/system/hexagonrpcd-sdsp.service" \
  "$PKG/usr/lib/systemd/system/hexagonrpcd-sdsp.service"
install -d "$PKG/usr/lib/systemd/system/multi-user.target.wants"
ln -s ../hexagonrpcd-sdsp.service \
  "$PKG/usr/lib/systemd/system/multi-user.target.wants/hexagonrpcd-sdsp.service"
install -Dm644 "$TWEAKS/10-fastrpc.rules" \
  "$PKG/usr/lib/udev/rules.d/10-fastrpc.rules"

### FIRMWARE ###
log "Installing firmware"

# Adreno
log "Installing Adreno firmware"
install -Dm644 "$FIRMWARE/marble/a730_zap.mbn" \
    -t "$PKG/lib/firmware/qcom/sm8475/xiaomi/marble"
install -Dm644 "$FIRMWARE/generic/qcom/a730_sqe.fw" "$FIRMWARE"/generic/qcom/gmu_gen70000.bin \
    -t "$PKG/lib/firmware/qcom"

# ADSP
log "Installing ADSP firmware"
install -Dm644 \
    "$FIRMWARE"/marble/adsp2.* \
    "$FIRMWARE"/marble/adspr.jsn \
    "$FIRMWARE"/marble/adspua.jsn \
    "$FIRMWARE"/marble/battmgr.jsn \
    "$FIRMWARE"/marble/cdspr.jsn \
    -t "$PKG/lib/firmware/qcom/sm8475/xiaomi/marble"

# Audio
log "Installing audio firmware"
install -Dm644 "$FIRMWARE"/marble/aw88261_acf.bin -t "$PKG/lib/firmware/qcom/sm8475/xiaomi/marble"
install -Dm644 "$FIRMWARE"/generic/SM8475-Xiaomi-Marble-tplg.bin \
    -t "$PKG/lib/firmware/qcom/sm8450"

# Bluetooth
log "Installing Bluetooth firmware"
install -Dm644 "$FIRMWARE"/generic/qca/hp* -t "$PKG/lib/firmware/qca"
# btqca requests the wcn-prefixed names on WCN6855
for f in "$PKG"/lib/firmware/qca/hp*; do
    f="${f##*/}"
    log "Creating Bluetooth firmware symlink: wcn$f -> $f"
    ln -s "$f" "$PKG/lib/firmware/qca/wcn$f"
done

# HexagonFS
log "Installing HexagonFS"
mkdir -p "$PKG"/usr/share
cp -a "$FIRMWARE"/hexagonfs "$PKG"/usr/share/qcom

# Modem
log "Installing modem firmware"
install -Dm644 \
    "$FIRMWARE"/marble/modem.* \
    "$FIRMWARE"/marble/modemr.jsn \
    "$FIRMWARE"/marble/ipa_fws.* \
    -t "$PKG/lib/firmware/qcom/sm8475/xiaomi/marble"
log "Installing modem provisioning data"
cp -a "$FIRMWARE"/marble/modem_pr "$PKG/lib/firmware/qcom/sm8475/xiaomi/marble"/

# SLPI
log "Installing SLPI firmware"
install -Dm644 \
    "$FIRMWARE"/marble/slpi2.* \
    "$FIRMWARE"/marble/slpir.jsn \
    "$FIRMWARE"/marble/slpius.jsn \
    -t "$PKG/lib/firmware/qcom/sm8475/xiaomi/marble"

# Venus
log "Installing Venus firmware"
install -Dm644 "$FIRMWARE"/generic/qcom/vpu/* -t "$PKG/lib/firmware/qcom/vpu"

# Wlan
log "Installing WLAN firmware"
mkdir -p "$PKG"/lib/firmware/ath11k
cp -a "$FIRMWARE"/generic/ath11k/WCN6855 "$PKG"/lib/firmware/ath11k/

### TWEAKS ###
log "Installing tweaks"

log "Installing display-on initramfs hook"
install -Dm755 "$TWEAKS"/50-marble-display-on.sh \
    "$PKG"/usr/share/mkinitfs/hooks/50-marble-display-on.sh

log "Installing ALSA HiFi configuration"
install -Dm644 "$TWEAKS"/alsa-ucm-conf/HiFi.conf \
    "$PKG"/usr/share/alsa/ucm2/Qualcomm/sm8450/xiaomi-marble/HiFi.conf

log "Installing ALSA machine configuration"
install -Dm644 "$TWEAKS"/alsa-ucm-conf/marble.conf \
    "$PKG"/usr/share/alsa/ucm2/conf.d/sm8450/SM8475-Xiaomi-Marble.conf

log "Installing libssc udev rules"
install -Dm644 "$TWEAKS"/81-libssc-xiaomi-marble.rules \
    "$PKG"/usr/lib/udev/rules.d/81-libssc-xiaomi-marble.rules

log "Installing hexagonrpcd service override"
install -Dm644 "$TWEAKS"/hexagonrpcd-sdsp-marble.conf \
    "$PKG"/usr/lib/systemd/system/hexagonrpcd-sdsp.service.d/50-marble.conf

log "Installing IIO sensor proxy service override"
install -Dm644 "$TWEAKS"/iio-sensor-proxy-marble.conf \
    "$PKG"/usr/lib/systemd/system/iio-sensor-proxy.service.d/50-marble.conf

log "Installing environment configuration"
install -Dm644 "$TWEAKS"/environment-marble.conf \
    "$PKG"/usr/lib/environment.d/90-xiaomi-marble.conf

log "Installing hardware tuning executable"
install -Dm755 "$TWEAKS"/marble-hardware-tuning.sh \
    "$PKG"/usr/libexec/marble-hardware-tuning.sh

log "Installing hardware tuning service"
install -Dm644 "$TWEAKS"/marble-hardware-tuning.service \
    "$PKG"/usr/lib/systemd/system/marble-hardware-tuning.service

log "Enabling hardware tuning service"
install -d "$PKG"/usr/lib/systemd/system/multi-user.target.wants
ln -s ../marble-hardware-tuning.service \
    "$PKG"/usr/lib/systemd/system/multi-user.target.wants/marble-hardware-tuning.service

log "Installing storage udev rules"
install -Dm644 "$TWEAKS"/60-marble-storage.rules \
    "$PKG"/usr/lib/udev/rules.d/60-marble-storage.rules

log "Installing GPU udev rules"
install -Dm644 "$TWEAKS"/61-marble-gpu.rules \
    "$PKG"/usr/lib/udev/rules.d/61-marble-gpu.rules

log "Cross-compiling marble-touchboost"
"${CROSS_COMPILE}gcc" -Wall -Wextra -o "$WORK/marble-touchboost" "$TWEAKS"/marble-touchboost.c
log "Installing marble-touchboost executable"
install -Dm755 "$WORK/marble-touchboost" \
    "$PKG"/usr/libexec/marble-touchboost
log "Installing marble-touchboost service"
install -Dm644 "$TWEAKS"/marble-touchboost.service \
    "$PKG"/usr/lib/systemd/system/marble-touchboost.service
log "Enabling marble-touchboost service"
ln -s ../marble-touchboost.service \
    "$PKG"/usr/lib/systemd/system/multi-user.target.wants/marble-touchboost.service
    
log "Installing VM sysctl configuration"
install -Dm644 "$TWEAKS"/99-marble-vm.conf \
    "$PKG"/usr/lib/sysctl.d/99-marble-vm.conf

log "Building package: $OUT"
dpkg-deb --root-owner-group --build "$PKG" "$OUT"
log "Wrote $OUT"