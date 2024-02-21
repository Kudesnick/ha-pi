# USB console and UART console

see: https://gist.github.com/gbaman/50b6cca61dd1c3f88f41

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
# dpkg -i ./homeassistant-supervised.deb
~~~

### Fix raspbian bug

#### wlan0 error

see: https://raspberrypi.stackexchange.com/questions/58809/rpi-loses-its-wlan0-configuration-when-any-docker-container-is-started
see: https://raspberrypi.stackexchange.com/a/117381

If `dpkg -i ./homeassistant-supervised.deb` fixates on the message

~~~
[info] Reload systemd
[info] Restarting NetworkManager
[info] Enable systemd-resolved
[info] Restarting systemd-resolved
[info] Start nfs-utils.service
[info] Restarting docker service
ping: checkonline.home-assistant.io: Temporary failure in name resolution
[info] Waiting for checkonline.home-assistant.io - network interface might be down...
~~~

Then install `tmux` and open two tabs. In first tab call `sudo dpkg -i ./homeassistant-supervised.deb`. When you see error of network connect, call `sudo systemctl restart dhcpcd` from second tab.

#### cgroup_hierarchy error

see: https://github.com/home-assistant/supervised-installer/issues/253

add `apparmor=1 security=apparmor systemd.unified_cgroup_hierarchy=false` to `cmdline.txt`
