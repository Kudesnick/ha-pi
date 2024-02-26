sudo docker exec -it homeassistant /bin/bash -c "apk add gcc musl-dev bluez-dev ; /init"
ha core update --version 2023.5.4

https://community.home-assistant.io/t/how-do-i-fix-unable-to-install-package-pybluez-0-22-error/579478/5
https://github.com/home-assistant/core/issues/89119#issuecomment-1661192703
https://github.com/home-assistant/core/pull/108513
