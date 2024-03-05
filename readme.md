# Install Home Assistant to Raspberry Pi zero 2W

## Previous settings of Raspbian image

1. Download [raspberry pi imager](https://downloads.raspberrypi.org/imager/imager_latest.exe)
2. Select device `Raspberry pi zero 2 w`
3. Select OS `Raspberry Pi OS (other)` -> Raspberry Pi OS (Legacy, 64 bit) Lite
4. Select mass storage device
5. Set custom settings: login and password of first user
6. Write image

## Edit image

### Edit `cmdline.txt`

add

~~~
dwc_otg.lpm_enable=0 console=serial0,115200 console=tty1 modules-load=dwc2,g_serial
~~~

then enable USB and serial console. Add

~~~
apparmor=1 security=apparmor systemd.unified_cgroup_hierarchy=false
~~~

then fix cgroup hierarchy error see (https://github.com/home-assistant/supervised-installer/issues/253). Еhe file should look like as

~~~
apparmor=1 security=apparmor systemd.unified_cgroup_hierarchy=false dwc_otg.lpm_enable=0 console=serial0,115200 console=tty1 modules-load=dwc2,g_serial root=PARTUUID=8bae82fd-02 rootfstype=ext4 fsck.repair=yes rootwait quiet init=/usr/lib/raspberrypi-sys-mods/firstboot systemd.run=/boot/firstrun.sh systemd.run_success_action=reboot systemd.unit=kernel-command-line.target
~~~

strictly in one line!

### Edit `config.txt`

Comments `otg_mode=1` (replace to `# otg_mode=1`) and append

~~~
enable_uart=1
dtoverlay=dwc2
~~~

### Edit `firstrun.sh`

Add this code before string `rm -f /boot/firstrun.sh`:

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

insert valid `FIRST_USER_NAME`, `NETWORK_NAME`, `WIRELESS_KEY`.

## Install Home Assistant

1. Write `Raspberry Pi OS (Legacy, 64 bit) Lite` image to SD-Card (few 4 min on 64 GB SD-Card);
2. Edit `cmdline.txt`, `config.txt` and `firstrun.sh`;
3. Insert SD-Card with Raspberry Pi OS image to device;
4. Connect device to PC;
5. Wait to install OS, Docker, OS-Agent and other (few 8 minutes);
6. At the end of the installation a virtual COM port should appear in the system;
7. Open this virtual COM port as console terminal;
8. Log in to system;
9. Type:

~~~
# MACHINE=raspberrypi2 dpkg --force-confdef --force-confold -i /homeassistant-supervised.deb
~~~

10. Wait for install complete and all docker containers to start (few 20 min);
11. Reconfigure Wi-Fi:

~~~
# nmcli device wifi connect ${NETWORK_NAME} password ${WIRELESS_KEY}
~~~

12. Open in browser `http://<Raspberry local IP>:8123/`.

## Bluetooth tracker patch

The Bluetooth tracker component has a dependency on the outdated PyBluez v 0.22 library. Therefore, when you try to start it according to the [instructions](https://www.home-assistant.io/integrations/bluetooth_tracker/), an [error](https://github.com/home-assistant/core/issues/94273) will be recorded in the log. To fix it, you need to [patch the component files using](https://github.com/home-assistant/core/pull/108513).

override bluetooth_tracker as a custom component from the [forked repository](https://github.com/xz-dev/core/tree/fix/bluetooth_tracker):

~~~
$ git clone --branch fix/bluetooth_tracker --depth 1 https://github.com/xz-dev/core.git
# mkdir /usr/share/hassio/homeassistant/custom_components/
# cp -r ./core/homeassistant/components/bluetooth_tracker/ /usr/share/hassio/homeassistant/custom_components/bluetooth_tracker/
$ rm -fr ./core/
~~~

~~~
# tee -a /usr/share/hassio/homeassistant/configuration.yaml << END
device_tracker:
  - platform: bluetooth_tracker
    request_rssi: true
  - platform: bluetooth_le_tracker
    track_new_devices: true
    track_battery: true
    track_battery_interval: 3600
    interval_seconds: 13
END
~~~

Restart system:

~~~
# shutdown -r now
~~~

After this, detected Bluetooth devices will begin to appear in the file `/usr/share/hassio/homeassistant/known_devices.yaml`

## Miscellaneous notes

### [Copy file from SSH](https://unix.stackexchange.com/questions/106480/how-to-copy-files-from-one-machine-to-another-using-ssh)

~~~
scp ${LOGIN}@${SERVER}:/usr/share/hassio/homeassistant/known_devices.yaml ${DEST}
~~~

## Links used

- https://forums.raspberrypi.com/viewtopic.php?t=228236
- https://digitallez.blogspot.com/2018/07/raspberry-3.html
- https://afullagar.wordpress.com/2017/09/17/raspberry-pi-3-change-from-dhcpcd-to-networkmanager-configuration/
- https://ivan.bessarabov.ru/blog/how-to-install-home-assistant-on-raspbian-on-raspberry-pi-4
- https://dzen.ru/a/ZYIM3UgUSzG68jmd
- https://www.tim-kleyersburg.de/articles/home-assistant-with-docker-2023/

### BT tracker patching

- https://www.home-assistant.io/integrations/bluetooth_tracker/
- https://github.com/home-assistant/core/issues/94273
- https://github.com/home-assistant/core/pull/108513
- https://github.com/xz-dev/core/tree/fix/bluetooth_tracker
