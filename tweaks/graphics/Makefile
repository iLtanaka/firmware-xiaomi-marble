DESTDIR ?=

.PHONY: all clean build install uninstall

all: install

build:
	@echo "Nothing to build"

install:
	@echo "Installing graphics tweaks"
	install -Dm644 "$(CURDIR)/61-marble-gpu.rules" "$(DESTDIR)/usr/lib/udev/rules.d/61-marble-gpu.rules"
	install -Dm644 "$(CURDIR)/environment-marble.conf" "$(DESTDIR)/usr/lib/environment.d/90-xiaomi-marble.conf"

uninstall:
	@echo "Uninstalling graphics tweaks"
	rm -f "$(DESTDIR)/usr/lib/udev/rules.d/61-marble-gpu.rules"
	rm -f "$(DESTDIR)/usr/lib/environment.d/90-xiaomi-marble.conf"

clean:
	@echo "Nothing to clean"