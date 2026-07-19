#!/bin/bash
set -e

WG_DIR="/etc/amnezia/amneziawg"
CONF="${WG_DIR}/awg0.conf"
mkdir -p "${WG_DIR}"
cd "${WG_DIR}"

if [ ! -f server_private.key ]; then
    echo "[*] Генерирую ключи сервера..."
    awg genkey | tee server_private.key | awg pubkey > server_public.key
fi

SERVER_PRIV=$(cat server_private.key)

: "${WG_PORT:=51820}"
: "${WG_ADDRESS:=10.13.13.1/24}"
: "${WG_JC:=4}"
: "${WG_JMIN:=40}"
: "${WG_JMAX:=70}"
: "${WG_S1:=0}"
: "${WG_S2:=0}"

if [ ! -f "${CONF}" ]; then
    source /usr/local/bin/render_config.sh
    export SERVER_PRIV
    render_config > "${CONF}"
    echo "# сюда добавляются [Peer] блоки клиентов (см. add-peer.sh)" >> "${CONF}"
    echo "[*] Создан конфиг ${CONF}. Публичный ключ сервера:"
    cat server_public.key
fi

echo "[*] Поднимаю интерфейс awg0..."
awg-quick up "${CONF}" || awg-quick down "${CONF}" && awg-quick up "${CONF}"

echo "[*] AmneziaWG запущен. Логи демона:"
tail -f /dev/null
