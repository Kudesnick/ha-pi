# radxa

## Собрать базовый образ из Armbian Build

Скачиваем и собираем:

~~~
$ git clone --depth=1 --branch=main https://github.com/armbian/build
$ cd ./build
$ ./compile.sh BOARD=radxa-zero BRANCH=current BUILD_DESKTOP=no BUILD_MINIMAL=yes KERNEL_CONFIGURE=yes RELEASE=bookworm
# очень долго ждем, затем проверяем результат
$ ls output/images/ -sh
total 1.3G
1.3G Armbian-unofficial_24.5.0-trunk_Radxa-zero_bookworm_current_6.6.29_minimal.img
4.0K Armbian-unofficial_24.5.0-trunk_Radxa-zero_bookworm_current_6.6.29_minimal.img.sha
 20K Armbian-unofficial_24.5.0-trunk_Radxa-zero_bookworm_current_6.6.29_minimal.img.txt
~~~

Альтернативный вариант - скачиваем официальный релиз:

~~~
$ wget "https://github.com/radxa-build/radxa-zero/releases/download/20220801-0213/Armbian_22.08.0-trunk_Radxa-zero_bullseye_current_5.10.134_minimal.img.xz"
$ xz -d Armbian_*_minimal.img.xz
$ ls -sh
total 1.1G
1.1G Armbian_22.08.0-trunk_Radxa-zero_bullseye_current_5.10.134_minimal.img
~~~

Официальный релиз собран инструментом [rbuild](https://github.com/radxa-repo/rbuild), который ориентирован только на производителя Radxa им же развивается (развивался ?). Сборка с его помощью напоминает сборку с помощью [pi-gen](https://github.com/RPi-Distro/pi-gen) под Raspberry Pi, но в отличие от pi-gen, rbuild конфигурируется yaml скриптами. Сборка однопоточна и уныла, хотя для освоения и кастомизации значительно проще, нежели [yocto](https://wiki.radxa.com/Yocto-layer-for-radxa-boards), например. Armbian build показался мне золотой серединой. По этому дальше все инструкции будут ориентированиы на образ, собранный с помощью этой системы сборки. По этому копируем образ из `~/output/images/` и начинаем модификацию.

## Базовая подготовка образа

Конечно, без chroot не обойтись. Для этого в системе Armbian Build есть файлик `userpatches/customize-image.sh`, но эксперименты проще проводить на реальном железе, отлаживаясь на каждой строчке. В данный файл мы запишем лишь то, что нам нужно для запуска USB-сонсоли, чтобы не шаманить с продключением UART-USB переходников. Хотя, для глубокой диагностики UART не заменим, т.к. сообщения загрузчика и старта ядра мы в USB-констли не увидим.

Добавим следующую функцию в этот файл, сразу после объявления глобальных переменных:

~~~
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

} # Usercode
~~~

Затем, в конце файла заменим вызов `Main "$@"` на `Usercode "$@"`.

Пересоберем образ:

~~~
$ ./compile.sh BOARD=radxa-zero BRANCH=current BUILD_DESKTOP=no BUILD_MINIMAL=yes KERNEL_CONFIGURE=no RELEASE=bookworm
~~~
