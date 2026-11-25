DESTDIR ?=

.PHONY: all clean build install uninstall

all: install

build:
	@echo "Nothing to build"

install:
	@echo "Installing hexagonfs firmware"
	mkdir -p "$(DESTDIR)/usr/share/qcom"
	find "$(CURDIR)" -mindepth 1 -maxdepth 1 ! -name Makefile -exec cp -a {} "$(DESTDIR)/usr/share/qcom" \;


uninstall:
	@echo "Uninstalling hexagonfs firmware"
	for f in "$(CURDIR)"/*; do \
		[ "$${f##*/}" = Makefile ] || rm -rf "$(DESTDIR)/usr/share/qcom/$${f##*/}"; \
	done

clean:
	@echo "Nothing to clean"