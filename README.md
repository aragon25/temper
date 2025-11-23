# temper

Packaged utility for interacting with temperature sensors and displaying
readings. This repository contains the code packaged as a Debian `.deb` for
easy installation on Debian/Raspbian systems.

## 📌 Features

- Read temperature from supported sensors (e.g. DS18B20)
- Simple CLI to query current temperature and history
- Optional systemd integration for periodic logging
- Packaged as a `.deb` for easy install and removal

---

## 📂 Installation

### Install via `.deb`

Download the release package and install on the device:

```bash
wget https://github.com/aragon25/temper/releases/download/v1.1-1/temper_1.1-1_all.deb
sudo apt install ./temper_1.1-1_all.deb
```

This installs the executable and any packaging-provided helpers.

---

## ⚙️ Usage

After installation, run `temper --help` (or `temper -h`) to list available
commands. Example commands:

```bash
# read current temperature
temper --read

# read sensor on bus or device node
temper --device /sys/bus/w1/devices/28-000005e2fdc3/w1_slave --read

# run once and print JSON
temper --read --format json
```

If your sensors are connected differently, adjust the device path accordingly.

---

## ⚠️ Safety

- Sensors and logging are safe, but be cautious when attaching new hardware.
- For automated tests, mock sensor device files instead of using real sensors.
