# Previous settings of Raspbian image

1. Download [raspberry pi imager](https://downloads.raspberrypi.org/imager/imager_latest.exe)
2. Select device `Raspberry pi zero 2 w`
3. Select OS `Raspberry Pi OS (other)` -> Raspberry Pi OS (Legacy, 64 bit) Lite
4. Select mass storage device
5. Set custom settings: login and password of first user
6. Write image

# Edit image

## Edit `cmdline.txt`

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

## Edit `config.txt`

Comments `otg_mode=1` (replace to `# otg_mode=1`) and append

~~~
enable_uart=1
dtoverlay=dwc2
~~~

## Edit `firstrun.sh`

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
# Type after login:
# dpkg -i /homeassistant-supervised.deb
~~~

insert valid `FIRST_USER_NAME`, `NETWORK_NAME`, `WIRELESS_KEY`.

# Install Home Assistant

1. Insert SD-Card with Raspberry Pi OS image to device;
2. Connect device to PC;
3. Wait to install OS, Docker, OS-Agent and other;
4. At the end of the installation a virtual COM port should appear in the system;
5. Open this virtual COM port as console terminal;
6. Log in to system;
7. Type `sudo dpkg -i /homeassistant-supervised.deb`;
8. Select machine type `Raspberrypi2`;
9. Wait for install complete.
