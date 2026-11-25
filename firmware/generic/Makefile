DESTDIR ?=

.PHONY: all clean build install uninstall

all: install

build:
	@echo "Nothing to build"

install:
	@echo "Installing generic firmware"
	install -Dm644 "$(CURDIR)/qcom/a730_sqe.fw" "$(DESTDIR)/lib/firmware/qcom/a730_sqe.fw"
	install -Dm644 "$(CURDIR)/qcom/gmu_gen70000.bin" "$(DESTDIR)/lib/firmware/qcom/gmu_gen70000.bin"
	install -Dm644 "$(CURDIR)/SM8475-Xiaomi-Marble-tplg.bin" -t "$(DESTDIR)/lib/firmware/qcom/sm8450"
	install -Dm644 "$(CURDIR)/qca/"* -t "$(DESTDIR)/lib/firmware/qca"
	install -Dm644 "$(CURDIR)/qcom/vpu/"* -t "$(DESTDIR)/lib/firmware/qcom/vpu"
	mkdir -p "$(DESTDIR)/lib/firmware/ath11k"
	cp -a "$(CURDIR)/ath11k/WCN6855" "$(DESTDIR)/lib/firmware/ath11k/"

uninstall:
	@echo "Uninstalling generic firmware"
	rm -f "$(DESTDIR)/lib/firmware/qcom/a730_sqe.fw" "$(DESTDIR)/lib/firmware/qcom/gmu_gen70000.bin"
	rm -f "$(DESTDIR)/lib/firmware/qcom/sm8450/SM8475-Xiaomi-Marble-tplg.bin"
	for f in "$(CURDIR)/qca/"*; do rm -f "$(DESTDIR)/lib/firmware/qca/$${f##*/}"; done
	for f in "$(CURDIR)/qcom/vpu/"*; do rm -f "$(DESTDIR)/lib/firmware/qcom/vpu/$${f##*/}"; done
	rm -rf "$(DESTDIR)/lib/firmware/ath11k/WCN6855"

clean:
	@echo "Nothing to clean"