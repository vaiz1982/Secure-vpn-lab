#!/bin/bash
# create_tree.sh — создаёт только структуру папок/файлов проекта amneziawg-docker
# (без содержимого — файлы создаются пустыми, дерево нужно, чтобы потом
# наполнить их вручную или скриптом create_project.sh с base64-архивом).
set -e

ROOT="amneziawg-docker"

DIRS=(
  "$ROOT/scripts"
  "$ROOT/tests"
  "$ROOT/honeypot/etc"
  "$ROOT/honeypot/fake-fs/opt"
  "$ROOT/honeypot/fake-fs/root/deploy_keys"
  "$ROOT/monitoring/conf.d"
  "$ROOT/.github/workflows"
  "$ROOT/ansible/inventory"
  "$ROOT/ansible/roles/hardening/tasks"
  "$ROOT/ansible/roles/hardening/handlers"
  "$ROOT/ansible/roles/hardening/defaults"
  "$ROOT/ansible/roles/hardening/templates"
  "$ROOT/ansible/roles/deploy/tasks"
  "$ROOT/ansible/roles/deploy/defaults"
  "$ROOT/ansible/roles/deploy/templates"
)

FILES=(
  "$ROOT/Dockerfile"
  "$ROOT/docker-compose.yml"
  "$ROOT/.gitignore"
  "$ROOT/scripts/entrypoint.sh"
  "$ROOT/scripts/render_config.sh"
  "$ROOT/tests/test_render_config.bats"
  "$ROOT/honeypot/build-fakefs.sh"
  "$ROOT/honeypot/etc/cowrie.cfg"
  "$ROOT/honeypot/etc/userdb.txt"
  "$ROOT/honeypot/fake-fs/opt/credentials.txt"
  "$ROOT/honeypot/fake-fs/root/.bash_history"
  "$ROOT/honeypot/fake-fs/root/notes.txt"
  "$ROOT/honeypot/fake-fs/root/deploy_keys/backup_key"
  "$ROOT/monitoring/conf.d/hosts.cfg"
  "$ROOT/monitoring/conf.d/services.cfg"
  "$ROOT/.github/workflows/ci.yml"
  "$ROOT/ansible/site.yml"
  "$ROOT/ansible/vault.yml.example"
  "$ROOT/ansible/inventory/hosts.ini"
  "$ROOT/ansible/roles/hardening/defaults/main.yml"
  "$ROOT/ansible/roles/hardening/tasks/main.yml"
  "$ROOT/ansible/roles/hardening/handlers/main.yml"
  "$ROOT/ansible/roles/hardening/templates/jail.local.j2"
  "$ROOT/ansible/roles/deploy/defaults/main.yml"
  "$ROOT/ansible/roles/deploy/tasks/main.yml"
  "$ROOT/ansible/roles/deploy/templates/env.j2"
  "$ROOT/ansible/roles/deploy/templates/services.cfg.j2"
)

echo "[*] Создаю директории..."
for d in "${DIRS[@]}"; do
  mkdir -p "$d"
done

echo "[*] Создаю пустые файлы..."
for f in "${FILES[@]}"; do
  touch "$f"
done

chmod +x "$ROOT/scripts/entrypoint.sh" "$ROOT/scripts/render_config.sh" "$ROOT/honeypot/build-fakefs.sh" 2>/dev/null || true

echo "[*] Готово. Структура:"
find "$ROOT" -type f | sort
