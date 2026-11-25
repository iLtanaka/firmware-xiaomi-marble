DESTDIR ?=

.PHONY: all clean build install uninstall

all: install

build:
	@echo "Nothing to build"

install:
	@echo "Installing audio tweaks"
	install -Dm644 "$(CURDIR)/HiFi.conf" "$(DESTDIR)/usr/share/alsa/ucm2/Qualcomm/sm8450/xiaomi-marble/HiFi.conf"
	install -Dm644 "$(CURDIR)/marble.conf" "$(DESTDIR)/usr/share/alsa/ucm2/conf.d/sm8450/SM8475-Xiaomi-Marble.conf"

uninstall:
	@echo "Uninstalling audio tweaks"
	rm -f "$(DESTDIR)/usr/share/alsa/ucm2/Qualcomm/sm8450/xiaomi-marble/HiFi.conf"
	rm -f "$(DESTDIR)/usr/share/alsa/ucm2/conf.d/sm8450/SM8475-Xiaomi-Marble.conf"

clean:
	@echo "Nothing to clean"