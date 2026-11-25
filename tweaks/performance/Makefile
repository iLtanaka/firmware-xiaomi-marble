DESTDIR ?=

.PHONY: all clean build install uninstall

all: install

build:
	@echo "Nothing to build"

install:
	@echo "Installing performance tweaks"
	install -Dm644 "$(CURDIR)/99-marble-vm.conf" "$(DESTDIR)/usr/lib/sysctl.d/99-marble-vm.conf"
	install -Dm755 "$(CURDIR)/marble-hardware-tuning.sh" "$(DESTDIR)/usr/libexec/marble-hardware-tuning.sh"
	install -Dm644 "$(CURDIR)/marble-hardware-tuning.service" "$(DESTDIR)/usr/lib/systemd/system/marble-hardware-tuning.service"
	install -d "$(DESTDIR)/usr/lib/systemd/system/multi-user.target.wants"
	ln -sfn ../marble-hardware-tuning.service "$(DESTDIR)/usr/lib/systemd/system/multi-user.target.wants/marble-hardware-tuning.service"

uninstall:
	@echo "Uninstalling performance tweaks"
	rm -f "$(DESTDIR)/usr/lib/sysctl.d/99-marble-vm.conf"
	rm -f "$(DESTDIR)/usr/libexec/marble-hardware-tuning.sh"
	rm -f "$(DESTDIR)/usr/lib/systemd/system/multi-user.target.wants/marble-hardware-tuning.service"
	rm -f "$(DESTDIR)/usr/lib/systemd/system/marble-hardware-tuning.service"

clean:
	@echo "Nothing to clean"