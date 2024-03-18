# Установка Home Assistant на `Raspberry Pi Zero 2 W` как hass сервис

Цель - поставить Home Assistant поверх Raspbian, сохранив доступ к хост-системе. Это позволит управлять устройством на низком уровне, устанавливать дополнительные приложения и использовать ссистему не только как сервер Home Assistant но и в других целях. Как torrent-сервер, например. Все операции проводятся на Raspberry Pi zero 2W. Это самая компактная система семейства Raspbery Pi, которая потянет Home Assistant. На борту имеется Wi-Fi и BT/BLE, что позволяет сопрячь устройство как с локальной сетью, так и с BT/BLE устройствами без дополнительных аппаратных модулей. В последствии останется добавить только пару компонентов для поддержки ИК устройств и модуль для работы с ZigBee.

## Предварительные настройки образа Raspbian

1. Скачайте [raspberry pi imager](https://downloads.raspberrypi.org/imager/imager_latest.exe);
2. Выберите девайс Raspberry Pi Zero 2 W;
3. Выберите ОС `Raspberry Pi OS (other)` -> Raspberry Pi OS (Legacy, 64 bit) Lite;
4. Выберите SD-карту, на которую будете писать образ;
5. Установите дополнительные настройки: логин и пароль для основного пользователя. Для связи по SSH можно сразу добавить/сгенерировать ключ;
6. Запишите образ.

## Правка образа

После записи образа откройте раздел на SD-карточке, отформатированный в FAT32.

### Редактирование `cmdline.txt`

Добавьте следующий фрагмент в начало файла:

~~~
dwc_otg.lpm_enable=0 console=serial0,115200 console=tty1 modules-load=dwc2,g_serial
~~~

Это позволит подключаться к консоли через виртуальный COM-порт, по USB-кабелю. Это - способ взаимодействия с устройством, если не настроен доступ SSH, нет сети и т.д. 

Также добавьте в начало этого файла:

~~~
apparmor=1 security=apparmor systemd.unified_cgroup_hierarchy=false
~~~

для исправления предупреждения установщика:

~~~
[warn] Could not find /etc/default/grub or /boot/firmware/cmdline.txt failed to switch to cgroup v1
~~~

См. (https://github.com/home-assistant/supervised-installer/issues/253). Предупреждение всё равно будет появляться, но это некритично.

После всех манипуляций файл должен выглядеть примерно так:

~~~
apparmor=1 security=apparmor systemd.unified_cgroup_hierarchy=false dwc_otg.lpm_enable=0 console=serial0,115200 console=tty1 modules-load=dwc2,g_serial root=PARTUUID=8bae82fd-02 rootfstype=ext4 fsck.repair=yes rootwait quiet init=/usr/lib/raspberrypi-sys-mods/firstboot systemd.run=/boot/firstrun.sh systemd.run_success_action=reboot systemd.unit=kernel-command-line.target
~~~

Строго одна строка, без переносов!

### Редактирование `config.txt`

Закомментируйте `otg_mode=1` (замените `# otg_mode=1`) и добавьте строки:

~~~
enable_uart=1
dtoverlay=dwc2
~~~

Это позволит подключаться к консоли по USB или по UART, используя TTL переходник.

### Редактирование `firstrun.sh`

Добавьте следующий сценарий перед строкой `rm -f /boot/firstrun.sh`:

~~~
FIRST_USER_NAME=username
NETWORK_NAME=wifi_name
WIRELESS_KEY=wifi_password

# Enable USB console
# see https://forums.raspberrypi.com/viewtopic.php?t=228236
systemctl enable getty@ttyGS0.service

# Swap up to 1G
sed -i "s/CONF_SWAPSIZE.*$/CONF_SWAPSIZE=1024/" "/etc/dphys-swapfile"

# Enable BT
systemctl enable bluetooth.service
usermod -G bluetooth -a ${FIRST_USER_NAME}
# Type for scaning
# bluetoothctl
# agent on
# default-agent
# scan on

# Switch dhtcpd to NetworkManager
# see https://wiki.gentoo.org/wiki/NetworkManager
systemctl start NetworkManager.service
systemctl enable NetworkManager
systemctl enable NetworkManager-wait-online.service
nmcli device wifi connect ${NETWORK_NAME} password ${WIRELESS_KEY}

# Update system
apt update && apt upgrade -y

# docker install
curl -sSL https://get.docker.com | sh
usermod -aG docker ${FIRST_USER_NAME}
usermod -aG docker root
# Try command:
# docker ps -a
# Must be return:
# CONTAINER ID   IMAGE   COMMAND  CREATED   STATUS   PORTS   NAMES

# Home Assistant Install
#see https://github.com/home-assistant/supervised-installer

# prepare
apt install apparmor cifs-utils curl dbus jq libglib2.0-bin lsb-release network-manager nfs-common systemd-journal-remote udisks2 wget -y
# Install OS-Agent
wget https://github.com/home-assistant/os-agent/releases/download/1.6.0/os-agent_1.6.0_linux_aarch64.deb
dpkg -i os-agent_1.6.0_linux_aarch64.deb
# Try command:
# gdbus introspect --system --dest io.hass.os --object-path /io/hass/os
# Install Home Assistant
wget https://github.com/home-assistant/supervised-installer/releases/latest/download/homeassistant-supervised.deb
systemctl disable ModemManager
systemctl stop ModemManager
# Type after reload:
# MACHINE=raspberrypi2 dpkg --force-confdef --force-confold -i /homeassistant-supervised.deb

# Install smth packages
apt install mc -y
~~~

Данный скрипт произведет преднастройку системы (увеличит файл подкачки, включит BT и пр.) и скачает пакеты, необходимые для установки Home Assistant.
Укажите валидные `FIRST_USER_NAME` (имя пользователя, которое указано при настройке образа Raspbian), `NETWORK_NAME` и `WIRELESS_KEY` - логин и пароль Wi-Fi сети.

## Установка Home Assistant

1. Запишите образ `Raspberry Pi OS (Legacy, 64 bit) Lite` на SD-карту (около 4 минут на 64 GB SD-карту);
2. Отредактируйте `cmdline.txt`, `config.txt` и `firstrun.sh` согласно инструкции выше;
3. Вставьте подготовленную SD-карту в устройство;
4. Подключите устройство к ПК;
5. Подождите, пока установится ОС, Docker, OS-Agent и прочее (примерно 8 минут);
6. После всех установок, устройство перезагрузится и в ПК появится новый виртуальный COM-порт;
7. Откройте это виртуальный COM-порт в терминале (например [PuTTY](https://www.putty.org/));
8. Войдите в систему под вашим логином и паролем;
9. Переконфигурируйте Wi-Fi. Это нужно, потому что при конфигурации через скрипт `firstrun.sh` что-то работает не совсем корректно и Home Assistant не может подключиться к сети:

~~~
# nmcli device wifi connect ${NETWORK_NAME} password ${WIRELESS_KEY}
~~~

10. Наберите для установки Home Assistant:

~~~
# MACHINE=raspberrypi2 dpkg --force-confdef --force-confold -i /homeassistant-supervised.deb
~~~

11. Подождите, пока система установится и все Docker-контейнеры будут запущены (примерно 20 минут);
12. Откройте в браузере панель настроек Home Assistant `http://<Raspberry local IP>:8123/`;
13. Готово!

## Исправление компонента bluetooth_tracker

Компонент `Bluetooth tracker` использует устаревшую библиотеку PyBluez v 0.22. Из-за этого бага, если следовать [инструкции](https://www.home-assistant.io/integrations/bluetooth_tracker/), получаем в логе [ошибку](https://github.com/home-assistant/core/issues/94273). [Обсуждение бага ведется здесь](https://github.com/home-assistant/core/pull/108513).

Перегрузим bluetooth_tracker из [форка репозитория ядра](https://github.com/xz-dev/core/tree/fix/bluetooth_tracker), в котором компонент переписан под актуальные библиотеки:

~~~
$ git clone --branch fix/bluetooth_tracker --depth 1 https://github.com/xz-dev/core.git
# mkdir /usr/share/hassio/homeassistant/custom_components/
# cp -r ./core/homeassistant/components/bluetooth_tracker/ /usr/share/hassio/homeassistant/custom_components/bluetooth_tracker/
# chmod -R 755 /usr/share/hassio/homeassistant/custom_components/
# sed -i 's/"name".*/&\n  "version": "1.0.0",/' /usr/share/hassio/homeassistant/custom_components/bluetooth_tracker/manifest.json
# sed -i 's/"codeowners".*/&\n  "dependencies": ["bluetooth_adapters"],/' /usr/share/hassio/homeassistant/custom_components/bluetooth_tracker/manifest.json
$ rm -fr ./core/
~~~

Включим обнаружение BT/BLE устройств, добавив натройки в конфиг:

~~~
# tee -a /usr/share/hassio/homeassistant/configuration.yaml << END
device_tracker:
  - platform: bluetooth_tracker
    track_new_devices: true
    request_rssi: true
  - platform: bluetooth_le_tracker
    track_new_devices: true
    track_battery: true
    track_battery_interval: 3600
    interval_seconds: 13
END
~~~

Перезагрузите систему:

~~~
$ ha core restart
~~~

После этого, обнаруживаемые BT/BLE девайсы будут фиксироваться в файле `/usr/share/hassio/homeassistant/known_devices.yaml`

После того, как все необходимые устройства будут найдены, рекомендуется отключить сканирование эфира, установив `track_new_devices: false` для компонентов bluetooth_tracker и bluetooth_le_tracker. Для удобства дальнейшей работы также можно почистить файл `known_devices.yaml` от ненужных устройств.

## Подключение в качестве трекера часов Xiaomi Watch S1 Pro

> **⚠**
>
> Нерабочий метод, т.к. по всей видимости, часы не отправляют advertise пакеты с mac-адресом, в режиме коннекта. Таким образом отследить их наличие без привязки к Raspberry Pi - невозможно.

1. Откройте меню часов `Настройки` -> `Система` -> `Подключить новый телефон`;
2. В открывшемся диалоге нажмите `Ok`;
3. Наберите в консоле Raspberry Pi команду поиска BT устройств:

~~~
$ bluetoothctl devices
~~~

4. В списке устройств найдите строку вида:

~~~
Device XX:XX:XX:XX:XX:XX Xiaomi Watch S1 Pro XXXX
~~~

Здесь, XX:XX:XX:XX:XX:XX - MAC-адрес устройства, он понадобится нам в дальнейшем; XXXX - последние 4 символа MAC-адреса который отображается в приложении Mi Fitness. Последний не соответствует реальному MAC-адресу устройства и не светится в эфире. Что это за адрес - непонятно. Однако, если сделать запрос

~~~
$ bluetoothctl info XX:XX:XX:XX:XX:XX
~~~

Можно выяснить, что в поле `ServiceData Value:` последние 6 байт из 11 - это и есть MAC-адрес, отображаемый в приложении. Только байты идут в обратном порядке.

## Подключение в качестве трекера мобильного телефона Android

1. Установите компонент ble_monitor:

~~~
$ git clone --depth 1 https://github.com/custom-components/ble_monitor.git
# # mkdir /usr/share/hassio/homeassistant/custom_components/
# cp -r ./ble_monitor/custom_components/bluetooth_tracker/ /usr/share/hassio/homeassistant/custom_components/ble_monitor/
# chmod -R 755 /usr/share/hassio/homeassistant/custom_components/
~~~

2. Добавьте в `configuration.yaml` конфигурацию компонента (XX:XX:XX:XX:XX:XX - mac-адрес BLE модуля телефона):

~~~
# tee -a /usr/share/hassio/homeassistant/configuration.yaml << END
ble_monitor:
  discovery: False
  bt_auto_restart: True
  active_scan: True
  devices:
    - mac: 'XX:XX:XX:XX:XX:XX'
      name: 'Beacon_Name'
      track_device: True
      tracker_scan_interval: 5
      consider_home: 15
END
~~~

3. Откройте приложение Home Assistant на телефоне;
4. Выберите `Главное меню` -> `Настройки` -> `кМобильное приложение` -> `Передатчик BLE` -> `Включить датчик`;
5. Теперь телефон будет работать как метка iBeacon.

## Разные заметки

### [Копирование файла по SSH](https://unix.stackexchange.com/questions/106480/how-to-copy-files-from-one-machine-to-another-using-ssh)

Пример:

~~~
scp ${LOGIN}@${SERVER}:/usr/share/hassio/homeassistant/known_devices.yaml ${DEST}
~~~

### Мониторинг добавляемых в known_devices.yaml устройств в реальном времени

~~~
$ tail -f /usr/share/hassio/homeassistant/known_devices.yaml
~~~

## Используемые ссылки

- https://forums.raspberrypi.com/viewtopic.php?t=228236
- https://digitallez.blogspot.com/2018/07/raspberry-3.html
- https://afullagar.wordpress.com/2017/09/17/raspberry-pi-3-change-from-dhcpcd-to-networkmanager-configuration/
- https://ivan.bessarabov.ru/blog/how-to-install-home-assistant-on-raspbian-on-raspberry-pi-4
- https://dzen.ru/a/ZYIM3UgUSzG68jmd
- https://www.tim-kleyersburg.de/articles/home-assistant-with-docker-2023/

### Ссылки, используемые для исправления компонента bluetooth_tracker

- https://www.home-assistant.io/integrations/bluetooth_tracker/
- https://github.com/home-assistant/core/issues/94273
- https://github.com/home-assistant/core/pull/108513
- https://github.com/xz-dev/core/tree/fix/bluetooth_tracker
- https://community.home-assistant.io/t/cant-override-a-core-integration/328151
- https://developers.home-assistant.io/docs/creating_integration_manifest/
