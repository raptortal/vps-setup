#!/usr/bin/env bash
set -Eeuo pipefail

GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

read_clean() {
  local __var="$1"
  local __val=""
  IFS= read -r __val </dev/tty || __val=""
  __val="${__val//$'\r'/}"
  __val="${__val#"${__val%%[![:space:]]*}"}"
  __val="${__val%"${__val##*[![:space:]]}"}"
  printf -v "$__var" '%s' "$__val"
}

read_silent() {
  local __var="$1"
  local __val=""
  IFS= read -r -s __val </dev/tty || __val=""
  echo
  __val="${__val//$'\r'/}"
  printf -v "$__var" '%s' "$__val"
}

ask_yn() {
  local prompt="$1"
  local answer=""
  
  while true; do
    printf "%s (y/n): " "$prompt"
    read_clean answer
    
    case "${answer,,}" in
      y|yes) return 0 ;;
      n|no) return 1 ;;
      *) echo "Введите y или n" ;;
    esac
  done
}

echo -e "${GREEN}Смена пароля root${NC}"
if ask_yn "Сменить пароль root?"; then
  while true; do
    printf "Введите новый пароль для root: "
    read_silent ROOTPASS

    printf "Повторите пароль: "
    read_silent ROOTPASS2

    if [[ -z "${ROOTPASS:-}" ]]; then
      echo -e "${RED}Пароль пустой — нельзя. Попробуйте снова.${NC}"
      continue
    fi

    if [[ "$ROOTPASS" == "$ROOTPASS2" ]]; then
      echo "root:$ROOTPASS" | chpasswd
      unset ROOTPASS ROOTPASS2
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

export DEBIAN_FRONTEND=noninteractive
apt update && apt upgrade -y -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold"

echo -e "${GREEN}=== Установка утилит ===${NC}"
apt install -y speedtest-cli mtr nano htop traceroute iftop nmap curl lsof whois mc fail2ban wget

echo -e "${GREEN}=== Настройка fail2ban ===${NC}"
systemctl enable --now fail2ban

tee /etc/fail2ban/jail.local >/dev/null <<'EOF'
[sshd]
enabled = true
bantime = 60m
EOF
systemctl restart fail2ban

echo -e "${GREEN}=== Создание swap 1GB ===${NC}"
if [[ -n "$(swapon --show --noheadings 2>/dev/null | head -n1)" ]]; then
  echo "Swap уже активен, пропускаем"
else
  fallocate -l 1G /swapfile
  chmod 600 /swapfile
  mkswap /swapfile
  swapon /swapfile
  grep -qE '^\s*/swapfile\s' /etc/fstab || echo "/swapfile none swap sw 0 0" >> /etc/fstab
  echo -e "${GREEN}Swap создан и добавлен в fstab${NC}"
fi

echo -e "${GREEN}=== Установка BBR и оптимизация TCP/UDP ===${NC}"
wget -qO /tmp/bbr-custom.sh https://raw.githubusercontent.com/raptortal/vps-setup/main/bbr-custom.sh || { echo -e "${RED}Ошибка загрузки bbr-custom.sh${NC}"; exit 1; }
bash /tmp/bbr-custom.sh </dev/null

echo -e "${GREEN}=== Установка завершена ===${NC}"

while read -r -t 0.1 -n 1; do :; done </dev/tty

if ask_yn "Перезагрузить сервер сейчас?"; then
  echo "Перезагрузка..."
  reboot
else
  echo "Перезагрузка отменена. Рекомендуется перезагрузить позже командой: reboot"
fi
