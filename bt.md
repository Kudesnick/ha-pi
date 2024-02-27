# Bluetooth

add to `/usr/share/hassio/homeassistant/configuration.yaml`:

~~~
device_tracker:
  - platform: bluetooth_tracker
~~~

# dbus broker

see: https://www.home-assistant.io/integrations/bluetooth/
see: https://github.com/bus1/dbus-broker/wiki

~~~
# apt install bluez dbus-broker -y
# systemctl enable dbus-broker.service
# systemctl --global enable dbus-broker.service
~~~

# Smth notes

sudo docker exec -it homeassistant /bin/bash -c "apk add gcc musl-dev bluez-dev ; /init"
ha core update --version 2023.5.4

https://community.home-assistant.io/t/how-do-i-fix-unable-to-install-package-pybluez-0-22-error/579478/5
https://github.com/home-assistant/core/issues/89119#issuecomment-1661192703


# Fix bluetooth tracker

see: https://github.com/home-assistant/core/pull/108513

~~~
$ wget https://raw.githubusercontent.com/xz-dev/core/fix/bluetooth_tracker/homeassistant/components/bluetooth_tracker/device_tracker.py
$ wget https://raw.githubusercontent.com/xz-dev/core/fix/bluetooth_tracker/homeassistant/components/bluetooth_tracker/manifest.json

# docker cp device_tracker.py homeassistant:/usr/src/homeassistant/homeassistant/components/bluetooth_tracker/
# docker cp manifest.json homeassistant:/usr/src/homeassistant/homeassistant/components/bluetooth_tracker/
~~~
