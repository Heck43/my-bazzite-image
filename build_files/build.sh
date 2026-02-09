#!/usr/bin/env bash
set -euo pipefail

echo "==> Installing build dependencies (curl, tar, jq, sudo, shadow-utils)"
rpm-ostree install -y --allow-inactive curl tar jq sudo shadow-utils
rpm-ostree cleanup -m

echo "==> Creating temporary user for Millennium installer"
# На Fedora/ostree обычно home лежит в /var/home
user="millinst"
home="/var/home/${user}"

if ! id -u "${user}" >/dev/null 2>&1; then
  useradd -m -d "${home}" -s /bin/bash "${user}"
fi

echo "==> Allowing passwordless sudo for installer (temporary)"
cat >/etc/sudoers.d/90-millinst <<'EOF'
millinst ALL=(ALL) NOPASSWD:ALL
EOF
chmod 0440 /etc/sudoers.d/90-millinst

echo "==> Running official Millennium installer as non-root user"
# Важно: запуск именно НЕ от root
su - "${user}" -c 'curl -fsSL "https://steambrew.app/install.sh" | bash'

echo "==> Removing temporary sudo rule"
rm -f /etc/sudoers.d/90-millinst

echo "==> Verifying install artifacts"
# 1) Проверим что бинарь появился
if ! command -v millennium >/dev/null 2>&1; then
  echo "WARN: millennium not found in PATH after install."
  echo "Trying to locate files:"
  find /usr -maxdepth 4 -iname "*millennium*" 2>/dev/null | head -n 200 || true
  exit 1
fi

echo "==> millennium in PATH: $(command -v millennium)"
millennium --version || true

echo "==> Done"
