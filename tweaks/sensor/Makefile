HEXAGONRPC_VERSION := 0.5.0
HEXAGONRPC_SHA256  := 2173985932ab68d8ac593f9954357123bdbbbe9ba5f1b17a098d9cbcec22c5d5
HEXAGONRPC_URL     := https://github.com/linux-msm/hexagonrpc/archive/refs/tags/v$(HEXAGONRPC_VERSION).tar.gz

DESTDIR            ?=

BUILD_ROOT         := $(CURDIR)/.work/hexagonrpc-$(HEXAGONRPC_VERSION)
SRC_DIR            := $(BUILD_ROOT)/src
MESON_BUILD_DIR    := $(BUILD_ROOT)/meson-build
SOURCE_TARBALL     := $(BUILD_ROOT)/hexagonrpc.tar.gz
MESON_CROSS_FILE   := $(BUILD_ROOT)/aarch64-cross.ini

REQUIRED_TOOLS := curl tar sha256sum meson ninja \
	gcc ar strip ranlib

.PHONY: all clean build install check-tools fetch extract uninstall

all: build

check-tools:
	@for tool in $(REQUIRED_TOOLS); do \
		command -v "$$tool" >/dev/null 2>&1 || { \
			printf 'Required build tool not found: %s\n' "$$tool" >&2; \
			exit 1; \
		}; \
	done

fetch: check-tools $(SOURCE_TARBALL)

$(SOURCE_TARBALL):
	@mkdir -p "$(BUILD_ROOT)"
	@echo "Downloading hexagonrpc $(HEXAGONRPC_VERSION)"
	@curl --fail --location --silent --show-error \
		"$(HEXAGONRPC_URL)" \
		--output "$(SOURCE_TARBALL).tmp"
	@printf '%s  %s\n' "$(HEXAGONRPC_SHA256)" "$(SOURCE_TARBALL).tmp" | sha256sum --check --status || { \
		$(call log,"Source checksum verification failed"); \
		rm -f "$(SOURCE_TARBALL).tmp"; \
		exit 1; \
	}
	@mv "$(SOURCE_TARBALL).tmp" "$(SOURCE_TARBALL)"

extract: fetch $(SRC_DIR)/.extracted

$(SRC_DIR)/.extracted: $(SOURCE_TARBALL)
	@echo "Extracting source tarball"
	@mkdir -p "$(SRC_DIR)"
	@tar -xzf "$(SOURCE_TARBALL)" --strip-components=1 -C "$(SRC_DIR)"
	@touch "$@"

$(MESON_CROSS_FILE): check-tools
	@mkdir -p "$(BUILD_ROOT)"
	@gcc=$$(command -v "gcc"); \
	ar=$$(command -v "ar"); \
	strip=$$(command -v "strip"); \
	ranlib=$$(command -v "ranlib"); \
	pkg_config=$$(command -v "pkg-config"); \
	cmake=$$(command -v cmake); \
	printf '%s\n' \
		'[binaries]' \
		"c = '$$gcc'" \
		"ar = '$$ar'" \
		"strip = '$$strip'" \
		"ranlib = '$$ranlib'" \
		"pkg-config = '$$pkg_config'" \
		"cmake = '$$cmake'" \
		'' \
		'[host_machine]' \
		"system = 'linux'" \
		"cpu_family = 'aarch64'" \
		"cpu = 'aarch64'" \
		"endian = 'little'" \
		'' \
		'[properties]' \
		'needs_exe_wrapper = true' \
		> "$(MESON_CROSS_FILE)"

build: extract $(MESON_CROSS_FILE)
	@echo "Configuring and building hexagonrpc $(HEXAGONRPC_VERSION)"
	@if [ ! -f "$(MESON_BUILD_DIR)/build.ninja" ]; then \
		meson setup "$(MESON_BUILD_DIR)" "$(SRC_DIR)" \
			--cross-file "$(MESON_CROSS_FILE)" \
			--prefix /usr \
			--libdir=lib \
			--buildtype=release; \
	else \
		meson setup --reconfigure "$(MESON_BUILD_DIR)" "$(SRC_DIR)" \
			--cross-file "$(MESON_CROSS_FILE)" \
			--prefix /usr \
			--libdir=lib \
			--buildtype=release; \
	fi
	@ninja -C "$(MESON_BUILD_DIR)"

install: build
	@echo "Installing hexagonrpc $(HEXAGONRPC_VERSION)"
	@DESTDIR="$(DESTDIR)" ninja -C "$(MESON_BUILD_DIR)" install
	install -d "$(DESTDIR)/usr/lib/systemd/system/multi-user.target.wants"
	ln -sfn "../hexagonrpcd-sdsp.service" "$(DESTDIR)/usr/lib/systemd/system/multi-user.target.wants/hexagonrpcd-sdsp.service"
	install -Dm644 "$(CURDIR)/10-fastrpc.rules" "$(DESTDIR)/usr/lib/udev/rules.d/10-fastrpc.rules"
	install -Dm644 "$(CURDIR)/81-libssc-xiaomi-marble.rules" "$(DESTDIR)/usr/lib/udev/rules.d/81-libssc-xiaomi-marble.rules"
	install -Dm644 "$(CURDIR)/hexagonrpcd-sdsp-marble.conf" "$(DESTDIR)/usr/lib/systemd/system/hexagonrpcd-sdsp.service.d/50-marble.conf"
	install -Dm644 "$(CURDIR)/iio-sensor-proxy-marble.conf" "$(DESTDIR)/usr/lib/systemd/system/iio-sensor-proxy.service.d/50-marble.conf"

uninstall:
	@echo "Uninstalling hexagonrpc $(HEXAGONRPC_VERSION)"
	@if [ -f "$(MESON_BUILD_DIR)/install_manifest.txt" ]; then \
		while IFS= read -r f; do \
			rm -f "$(DESTDIR)$$f"; \
		done < "$(MESON_BUILD_DIR)/install_manifest.txt"; \
	fi
	rm -f "$(DESTDIR)/usr/lib/systemd/system/multi-user.target.wants/hexagonrpcd-sdsp.service"
	rm -f "$(DESTDIR)/usr/lib/udev/rules.d/10-fastrpc.rules"
	rm -f "$(DESTDIR)/usr/lib/udev/rules.d/81-libssc-xiaomi-marble.rules"
	rm -f "$(DESTDIR)/usr/lib/systemd/system/hexagonrpcd-sdsp.service.d/50-marble.conf"
	rm -f "$(DESTDIR)/usr/lib/systemd/system/iio-sensor-proxy.service.d/50-marble.conf"
	-rmdir "$(DESTDIR)/usr/lib/systemd/system/hexagonrpcd-sdsp.service.d" 2>/dev/null || true
	-rmdir "$(DESTDIR)/usr/lib/systemd/system/iio-sensor-proxy.service.d" 2>/dev/null || true
	-rmdir "$(DESTDIR)/usr/lib/systemd/system/multi-user.target.wants" 2>/dev/null || true

clean:
	@echo "Cleaning build artifacts"
	@rm -rf "$(BUILD_ROOT)"