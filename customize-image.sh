#!/bin/bash

# arguments: $RELEASE $LINUXFAMILY $BOARD $BUILD_DESKTOP
#
# This is the image customization script

# NOTE: It is copied to /tmp directory inside the image
# and executed there inside chroot environment
# so don't reference any files that are not already installed

# NOTE: If you want to transfer files between chroot and host
# userpatches/overlay directory on host is bind-mounted to /tmp/overlay in chroot
# The sd card's root path is accessible via $SDCARD variable.

RELEASE=$1
LINUXFAMILY=$2
BOARD=$3
BUILD_DESKTOP=$4

USER_NAME=username
USER_PASS=userpass
NETWORK_NAME=wifi_name
NETWORK_PASS=wifi_pass
HOSTNAME=hostname
SSH_PUB=pubkey

Usercode() {
	# Не предлагаем сменить пароль root или создать нового пользователя
	rm -f /etc/profile.d/armbian-check-first-login.sh
    rm -f /etc/profile.d/armbian-check-first-login-reboot.sh

	# Отключаем автообновления
	rm -f /etc/cron.d/armbian-truncate-logs
	rm -f /etc/cron.d/armbian-update
	rm -f /etc/cron.d/sysstat
	rm -f /etc/update-mot.d/41-armbian-config
	rm -f /etc/update-mot.d/40-armbian-updates
	rm -f /etc/cron.daily/apt-compat

	# Включаем USB консоль
	systemctl enable serial-getty@ttyGS0
	echo g_serial > /etc/modules-load.d/g_serial.conf
	sed -i 's/console=both$/console=ttyGS0/' /boot/armbianEnv.txt

	# устанавливаем пакеты
	apt update
	apt install -y mc

	# создаем пользователя
	useradd "${USER_NAME}" -p "${USER_PASS}" -m --uid 1000 -G root,adm,netdev,plugdev -s /bin/bash
	sed -i "s/--autologin root/--autologin ${USER_NAME}/" /etc/systemd/system/serial-getty@.service.d/override.conf
	# настраиваем доступ по ssh только по ключу
	# на хостмашине генерируем ключ:
	# ssh-keygen -t ed25519 -f ~/.ssh/id_ed25519_ku -q -N ""
	# sudo chmod 700 ~/.ssh
	# sudo chmod 600 ~/.ssh/*
	mkdir "/home/${USER_NAME}/.ssh"
	echo "${SSH_PUB}" >> "/home/${USER_NAME}/.ssh/key.pub"
	sed -i 's/^PermitRootLogin.*$/PermitRootLogin no\nPermitRootLogin prohibit-password\nChallengeResponseAuthentication no\nPasswordAuthentication no/' /etc/ssh/sshd_config
	systemctl enable ssh

	# настраиваем имя в сети
	hostnamectl set-hostname "${HOSTNAME}"

	# Настраиваем wifi
	# nmcli device wifi connect ${NETWORK_NAME} password ${NETWORK_PASS}
	nmcli --offline connection add type wifi ssid "${NETWORK_NAME}" wifi-sec.auth-alg open wifi-sec.key-mgmt wpa-psk wifi-sec.psk "${NETWORK_PASS}"

} # Usercode

Main() {
	Usercode
} # Main

Main "$@"
