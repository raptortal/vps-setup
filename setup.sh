#!/bin/bash

GREEN='\033[0;32m'
NC='\033[0m'


echo -e "${GREEN}=== Смена пароля root ===${NC}"
echo "Введите новый пароль для root:"
read -s ROOT_PASS < /dev/tty
echo
echo "root:$ROOT_PASS" | chpasswd
echo "Пароль изменён"

echo -e "${GREEN}=== Подготовка системы ===${NC}"
apt update && apt install -y wget curl

echo -e "${GREEN}=== Обновление системы ===${NC}"
apt update && apt upgrade -y

echo -e "${GREEN}=== Установка утилит ===${NC}"
apt install -y speedtest-cli mtr nano htop traceroute iftop nmap fail2ban

echo -e "${GREEN}=== Настройка fail2ban ===${NC}"
systemctl enable --now fail2ban

echo -e "${GREEN}=== Установка BBR и оптимизация TCP/UDP ===${NC}"
wget -O bbr-custom.sh https://raw.githubusercontent.com/raptortal/vps-setup/refs/heads/main/bbr-custom.sh && bash bbr-custom.sh
