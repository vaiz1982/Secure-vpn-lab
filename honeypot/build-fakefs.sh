#!/bin/bash
set -e
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HONEYFS_OUT="${HERE}/honeyfs"

rm -rf "${HONEYFS_OUT}"
mkdir -p "${HONEYFS_OUT}"
cp -r "${HERE}/fake-fs/"* "${HONEYFS_OUT}/"

echo "[*] honeyfs/ содержимое подготовлено:"
find "${HONEYFS_OUT}" -type f

echo "[*] Готово. fs.pickle будет пересобран при старте контейнера honeypot."
