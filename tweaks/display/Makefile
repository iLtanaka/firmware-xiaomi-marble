DESTDIR ?=
BUILDDIR := "$(CURDIR)/.build"

.PHONY: all clean build install uninstall

all: install

build:
	@echo "Building display tweaks"
	mkdir "$(BUILDDIR)"
	gcc -Wall -Wextra -o "$(BUILDDIR)/marble-touchboost" "$(CURDIR)"/marble-touchboost.c

install:
	@echo "Installing display tweaks"
	install -Dm755 "$(CURDIR)"/50-marble-display-on.sh "$(DESTDIR)"/usr/share/mkinitfs/hooks/50-marble-display-on.sh
	install -Dm755 "$(BUILDDIR)/marble-touchboost" "$(DESTDIR)"/usr/libexec/marble-touchboost
	install -Dm644 "$(CURDIR)"/marble-touchboost.service "$(DESTDIR)"/usr/lib/systemd/system/marble-touchboost.service
	sudo ln -s ../marble-touchboost.service "$(DESTDIR)"/usr/lib/systemd/system/multi-user.target.wants/marble-touchboost.service

uninstall:
	@echo "Uninstalling display tweaks"
	rm -f "$(DESTDIR)"/usr/share/mkinitfs/hooks/50-marble-display-on.sh
	rm -f "$(DESTDIR)"/usr/libexec/marble-touchboost
	rm -f "$(DESTDIR)"/usr/lib/systemd/system/multi-user.target.wants/marble-touchboost.service
	rm -f "$(DESTDIR)"/usr/lib/systemd/system/marble-touchboost.service

clean:
	@echo "Cleaning display tweaks"
	rm -rf "$(BUILDDIR)"