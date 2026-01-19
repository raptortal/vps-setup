#!/usr/bin/env bash
set -Eeuo pipefail

GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

# читаем ввод именно с терминала, даже если скрипт запущен как: wget -O- ... | bash
TTY_IN="/dev/tty"

read_tty() {
  # usage: read_tty varname
  local __var="$1"
  local __val=""
  if [[ -r "$TTY_IN" ]]; then
    IFS= read -r __val < "$TTY_IN" || __val=""
  else
    # если совсем нет tty (редко при ssh), пробуем stdin
    IFS= read -r __val || __val=""
  fi
  printf -v "$__var" '%s' "$__val"
}

read_tty_silent() {
  # usage: read_tty_silent varname
  local __var="$1"
  local __val=""
  if [[ -r "$TTY_IN" ]]; then
    IFS= read -r -s __val < "$TTY_IN" || __val=""
    echo
  else
    IFS= read -r -s __val || __val=""
    echo
  fi
  printf -v "$__var" '%s' "$__val"
}

ask_yn() {
  # usage: ask_yn "Вопрос"
  local prompt="$1"
  local ans=""
  while true; do
    echo -n "$prompt (y/n): "
    read_tty ans
    ans=$(printf '%s' "$ans" | tr -d '\r' | xargs)
    ans=${ans:0:1}
    case "$ans" in
      y|Y) return 0 ;;
      n|N) return 1 ;;
      *) echo "Введите y или n" ;;
    esac
  done
}

echo -e "${GREEN}Смена пароля root${NC}"
if ask_yn "Сменить пароль root?"; then
  while true; do
    echo "Введите новый пароль для root"
    read_tty_silent ROOTPASS

    echo "Повторите пароль"
    read_tty_silent ROOTPASS2

    if [[ -z "${ROOTPASS:-}" ]]; then
      echo -e "${RED}Пароль пустой — нельзя. Попробуйте снова.${NC}"
      continue
    fi

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

echo -e "${GREEN}=== Создание swap 1GB ===${NC}"
if [ "$(swapon --show | wc -l)" -gt 0 ]; then
  echo "Swap уже активен, пропускаем"
else
  fallocate -l 1G /swapfile
  chmod 600 /swapfile
  mkswap /swapfile
  swapon /swapfile
  grep -q "/swapfile" /etc/fstab || echo "/swapfile none swap sw 0 0" >> /etc/fstab
  echo -e "${GREEN}Swap создан и добавлен в fstab${NC}"
fi

echo -e "${GREEN}=== Установка BBR и оптимизация TCP/UDP ===${NC}"
wget -O bbr-custom.sh https://raw.githubusercontent.com/raptortal/vps-setup/refs/heads/main/bbr-custom.sh
bash bbr-custom.sh

echo -e "${GREEN}=== Установка завершена ===${NC}"

if ask_yn "Перезагрузить сервер сейчас?"; then
  echo "Перезагрузка..."
  reboot
else
  echo "Перезагрузка отменена. Рекомендуется перезагрузить позже командой: reboot"
fi
