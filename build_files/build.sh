#!/usr/bin/env bash
set -euo pipefail

echo "==> Installing build dependencies (curl, tar, jq)"
rpm-ostree install -y --allow-inactive curl tar jq
rpm-ostree cleanup -m

echo "==> Installing Millennium via official installer"
# В CI/контейнер-сборке интерактив может мешать — даём "yes" на вопросы
yes | bash -c 'curl -fsSL https://steambrew.app/install.sh | bash'

echo "==> Fixing execute bit on bundled python (if present)"
if [[ -f /opt/python-i686-3.11.8/bin/python3.11 ]]; then
  chmod 755 /opt/python-i686-3.11.8/bin/python3.11
fi

echo "==> Verifying Millennium install paths"
ls -la /usr/bin/millennium || true
ls -la /usr/lib/millennium 2>/dev/null | head -n 50 || true
ls -la /usr/share/millennium 2>/dev/null | head -n 50 || true

echo "==> Done"
