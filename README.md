# firmware-xiaomi-marble

Proprietary firmware files extracted from official stock firmware of the **Xiaomi Poco F5 / Redmi Note 12 Turbo** (`xiaomi-marble`, Qualcomm Snapdragon 7+ Gen 2 / SM7475).

Used by postmarketOS (`firmware-xiaomi-marble` aport) and other mainline Linux distributions.

---

## Contents

* `marble/`: Device-specific signed firmware images (ADSP, SLPI, Modem, Adreno Zap shader, IPA firmware, amplifier profiles).
* `generic/`: Generic Qualcomm firmware (Adreno SQE/GMU, WCN6855 Wi-Fi ath11k board files and Bluetooth NVM, Iris VPU firmware).
* `hexagonfs/`: Sensor registry and calibration data for `hexagonrpcd`.

---

## License

Proprietary firmware binaries copyright Qualcomm Technologies, Inc. and Xiaomi Inc.
For device redistribution only.
