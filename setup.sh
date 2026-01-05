#!/bin/bash

GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${GREEN}=== Смена пароля root ===${NC}"
echo "Сменить пароль root? (y/n):"
read -r CHANGE_PASS < /dev/tty
if [ "$CHANGE_PASS" = "y" ] || [ "$CHANGE_PASS" = "Y" ]; then
    while true; do
        echo "Введите новый пароль для root:"
        read -s ROOT_PASS < /dev/tty
        echo
        echo "Повторите пароль:"
        read -s ROOT_PASS2 < /dev/tty
        echo

        if [ "$ROOT_PASS" = "$ROOT_PASS2" ]; then
            echo "root:$ROOT_PASS" | chpasswd
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

echo -e "${GREEN}=== Установка BBR и оптимизация TCP/UDP ===${NC}"
wget -O bbr-custom.sh https://raw.githubusercontent.com/raptortal/vps-setup/refs/heads/main/bbr-custom.sh && bash bbr-custom.sh

echo -e "${GREEN}=== Установка завершена ===${NC}"
echo "Перезагрузить сервер сейчас? (y/n):"
read -r REBOOT < /dev/tty
if [ "$REBOOT" = "y" ] || [ "$REBOOT" = "Y" ]; then
    echo "Перезагрузка..."
    reboot
else
    echo "Перезагрузка отменена. Рекомендуется перезагрузить позже командой: reboot"
fi
