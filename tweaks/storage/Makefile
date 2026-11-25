DESTDIR ?=

.PHONY: all clean build install uninstall

all: install

build:
	@echo "Nothing to build"

install:
	@echo "Installing storage tweaks"
	install -Dm644 "$(CURDIR)/60-marble-storage.rules" "$(DESTDIR)/usr/lib/udev/rules.d/60-marble-storage.rules"

uninstall:
	@echo "Uninstalling storage tweaks"
	rm -f "$(DESTDIR)/usr/lib/udev/rules.d/60-marble-storage.rules"

clean:
	@echo "Nothing to clean"