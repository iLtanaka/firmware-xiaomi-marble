FIRMWARES := generic hexagonfs marble
FIRMWARES_DIR := firmware

TWEAKS := audio display graphics sensor storage performance misc
TWEAKS_DIR := tweaks

DESTDIR ?=
CROSS_COMPILE ?=

SUBDIRS := $(addprefix $(FIRMWARES_DIR)/,$(FIRMWARES)) \
	$(addprefix $(TWEAKS_DIR)/,$(TWEAKS))

.PHONY: build install uninstall clean

build:
	@set -e; for dir in $(SUBDIRS); do \
		$(MAKE) -C "$$dir" build \
			CROSS_COMPILE="$(CROSS_COMPILE)" \
			DESTDIR="$(DESTDIR)"; \
	done

install:
	@set -e; for dir in $(SUBDIRS); do \
		$(MAKE) -C "$$dir" install \
			CROSS_COMPILE="$(CROSS_COMPILE)" \
			DESTDIR="$(DESTDIR)"; \
	done

uninstall:
	@set -e; for dir in $(SUBDIRS); do \
		$(MAKE) -C "$$dir" uninstall \
			CROSS_COMPILE="$(CROSS_COMPILE)" \
			DESTDIR="$(DESTDIR)"; \
	done

clean:
	@set -e; for dir in $(SUBDIRS); do \
		$(MAKE) -C "$$dir" clean \
			CROSS_COMPILE="$(CROSS_COMPILE)" \
			DESTDIR="$(DESTDIR)"; \
	done