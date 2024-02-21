# USB console and UART console

Add `dwc_otg.lpm_enable=0 console=serial0,115200 console=tty1 modules-load=dwc2,g_serial` to `cmdline.txt`

Add to `config.txt`:

~~~
# otg_mode=1 # disable otg mode

enable_uart=1
dtoverlay=dwc2
~~~

Type in console input (or add to `firstrun.sh`):

~~~
 # systemctl enable getty@ttyGS0.service
 # shutdown -r now
~~~

Wi-Fi set:

~~~
# iwconfig wlan0 essid NETWORK_NAME key WIRELESS_KEY
~~~

# Install Home Assistant

see: https://ivan.bessarabov.ru/blog/how-to-install-home-assistant-on-raspbian-on-raspberry-pi-4

## Docker install:

~~~
# apt update && apt upgrade -y
# curl -sSL https://get.docker.com | sh
# usermod -aG docker <pi user name>
# usermod -aG docker root
# shutdown -r now
~~~

Verify:

~~~
# docker ps -a
~~~

Must be result:

~~~
CONTAINER ID   IMAGE   COMMAND  CREATED   STATUS   PORTS   NAMES
~~~

## Install Home Assistant

~~~
# apt install apparmor cifs-utils curl dbus jq libglib2.0-bin lsb-release network-manager nfs-common systemd-journal-remote udisks2 wget -y
~~~

### Install OS-Agent

~~~
# wget https://github.com/home-assistant/os-agent/releases/download/1.6.0/os-agent_1.6.0_linux_aarch64.deb
# dpkg -i os-agent_1.6.0_linux_aarch64.deb
~~~

Verify:

~~~
gdbus introspect --system --dest io.hass.os --object-path /io/hass/os
~~~

### Install Home Assistant

~~~
# wget https://github.com/home-assistant/supervised-installer/releases/latest/download/homeassistant-supervised.deb
# systemctl disable ModemManager
# systemctl stop ModemManager
# dpkg -i --ignore-depends=systemd-resolved ./homeassistant-supervised.deb
~~~
