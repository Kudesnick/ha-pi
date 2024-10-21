#!/bin/bash

USER_NAME=username
USER_PASS=userpass
NETWORK_NAME=wifi_name
NETWORK_PASS=wifi_pass
HOSTNAME=hostname
SSH_PUB=pubkey

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
nmcli device wifi connect ${NETWORK_NAME} password ${NETWORK_PASS}
