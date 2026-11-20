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

CROSS_COMPILE=aarch64-none-linux-gnu-
ARCH=arm64

command -v dpkg-deb >/dev/null 2>&1 || {
  echo "dpkg-deb is required" >&2
  exit 1
}

WORK=$(mktemp -d)
trap 'rm -rf "$WORK"' EXIT HUP INT TERM
PKG=$WORK/package

install -d "$PKG/DEBIAN"
cat > "$PKG/DEBIAN/control" <<'EOF'
Package: marble-addons
Version: 1.0.0
Section: admin
Priority: optional
Architecture: arm64
Depends: systemd, udev, alsa-ucm-conf, iio-sensor-proxy
Maintainer: Marble Linux Maintainers <marble-linux@localhost>
Description: Device-specific addons for Xiaomi POCO F5 (marble)
EOF

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
"$CROSS_COMPILE"gcc -Wall -Wextra -o "$TWEAKS"/marble-touchboost "$TWEAKS"/marble-touchboost.c
log "Installing marble-touchboost executable"
install -Dm755 "$TWEAKS"/marble-touchboost \
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