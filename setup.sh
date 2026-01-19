#!/bin/bash

GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${GREEN}Смена пароля root${NC}"
echo "Сменить пароль root? (y/n)"
read -r CHANGEPASS < /dev/tty

# чистим пробелы и \r, берём первый символ
CHANGEPASS=$(printf '%s' "$CHANGEPASS" | tr -d '\r' | xargs)
CHANGEPASS=${CHANGEPASS:0:1}

if [[ "$CHANGEPASS" == [yY] ]]; then
  while true; do
    echo "Введите новый пароль для root"
    read -r -s ROOTPASS < /dev/tty
    echo
    echo "Повторите пароль"
    read -r -s ROOTPASS2 < /dev/tty
    echo

    if [[ "$ROOTPASS" == "$ROOTPASS2" ]]; then
      echo "root:$ROOTPASS" | chpasswd
      echo -e "${GREEN}Пароль изменён${NC}"
      break
    else
      echo -e "${RED}Пароли не совпадают, попробуйте снова${NC}"
    fi
  done
else
  echo "Смена пароля пропущена"
fi

echo -e "${GREEN}=== Обновление системы ===${NC}"
apt update && apt upgrade -y

echo -e "${GREEN}=== Установка утилит ===${NC}"
apt install -y speedtest-cli mtr nano htop traceroute iftop nmap curl lsof whois mc fail2ban

echo -e "${GREEN}=== Настройка fail2ban ===${NC}"
systemctl enable --now fail2ban


echo -e "${GREEN}=== Создание swap (1GB) ===${NC}"
if [ "$(swapon --show | wc -l)" -gt 0 ]; then
    echo "Swap уже активен, пропускаем"
else
    fallocate -l 1G /swapfile
    chmod 600 /swapfile
    mkswap /swapfile
    swapon /swapfile
    if ! grep -q "/swapfile" /etc/fstab; then
        echo "/swapfile none swap sw 0 0" >> /etc/fstab
    fi
    echo -e "${GREEN}Swap создан и добавлен в fstab${NC}"
fi


echo -e "${GREEN}=== Установка BBR и оптимизация TCP/UDP ===${NC}"
wget -O bbr-custom.sh https://raw.githubusercontent.com/raptortal/vps-setup/refs/heads/main/bbr-custom.sh && bash bbr-custom.sh

echo -e "${GREEN}=== Установка завершена ===${NC}"



echo "Перезагрузить сервер сейчас? (y/n):"
read -r REBOOT < /dev/tty

REBOOT=$(printf '%s' "$REBOOT" | tr -d '\r' | xargs)
REBOOT=${REBOOT:0:1}

if [[ "$REBOOT" == [yY] ]]; then
  echo "Перезагрузка..."
  reboot
else
  echo "Перезагрузка отменена. Рекомендуется перезагрузить позже командой: reboot"
fi
