DESTDIR ?=

.PHONY: all clean build install uninstall

all: install

build:
	@echo "Nothing to build"

install:
	@echo "Installing misc tweaks"
	install -Dm644 "$(CURDIR)/plasma-mobile-marble.conf" "$(DESTDIR)/usr/lib/systemd/system/plasma-mobile.service.d/50-marble-sensors.conf"
	install -Dm755 "$(CURDIR)/marble-kwin-boost.sh" "$(DESTDIR)/usr/libexec/marble-kwin-boost.sh"
	install -Dm644 "$(CURDIR)/plasma-kwin_wayland-marble.conf" "$(DESTDIR)/usr/lib/systemd/user/plasma-kwin_wayland.service.d/50-marble-boost.conf"

uninstall:
	@echo "Uninstalling misc tweaks"
	rm -f "$(DESTDIR)/usr/lib/systemd/system/plasma-mobile.service.d/50-marble-sensors.conf"
	rm -f "$(DESTDIR)/usr/libexec/marble-kwin-boost.sh"
	rm -f "$(DESTDIR)/usr/lib/systemd/user/plasma-kwin_wayland.service.d/50-marble-boost.conf"

clean:
	@echo "Nothing to clean"