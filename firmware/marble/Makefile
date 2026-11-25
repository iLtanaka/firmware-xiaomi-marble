DESTDIR ?=

.PHONY: all clean build install uninstall

all: install

build:
	@echo "Nothing to build"

install:
	@echo "Installing marble firmware"
	install -Dm644 "$(CURDIR)/modem."* "$(CURDIR)/modemr.jsn" "$(CURDIR)/ipa_fws."* -t "$(DESTDIR)/lib/firmware/qcom/sm8475/xiaomi/marble"
	cp -a "$(CURDIR)/modem_pr" "$(DESTDIR)/lib/firmware/qcom/sm8475/xiaomi/marble/"
	install -Dm644 "$(CURDIR)"/marble/slpi2.* "$(CURDIR)"/marble/slpir.jsn "$(CURDIR)"/marble/slpius.jsn -t "$(DESTDIR)/lib/firmware/qcom/sm8475/xiaomi/marble"

uninstall:
	@echo "Uninstalling marble firmware"
	for f in "$(CURDIR)"/*; do rm -rf "$(DESTDIR)/lib/firmware/qcom/sm8475/xiaomi/marble/$${f##*/}"; done

clean:
	@echo "Nothing to clean"