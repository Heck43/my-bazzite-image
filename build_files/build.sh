#!/usr/bin/env bash
set -euo pipefail

echo "==> Installing build dependencies"
rpm-ostree install -y --allow-inactive curl tar jq sudo shadow-utils util-linux
rpm-ostree cleanup -m

echo "==> Debug: what is /home?"
ls -ld /home || true
stat /home || true

echo "==> Creating temporary user for Millennium installer"
mkdir -p /var/home
useradd -r -m -d /var/home/millennium -s /bin/bash millennium 2>/dev/null || true
mkdir -p /var/home/millennium
chown -R millennium:millennium /var/home/millennium

echo "==> Allowing passwordless sudo for installer (temporary)"
cat >/etc/sudoers.d/99-millennium-installer <<'EOF'
millennium ALL=(ALL) NOPASSWD:ALL
EOF
chmod 0440 /etc/sudoers.d/99-millennium-installer

echo "==> Running official Millennium installer as non-root (via setpriv)"
setpriv --reuid=millennium --regid=millennium --init-groups \
  env HOME=/var/home/millennium \
  bash -lc 'curl -fsSL https://steambrew.app/install.sh | bash'

echo "==> Cleaning up temporary sudoers"
rm -f /etc/sudoers.d/99-millennium-installer

echo "==> Verifying Millennium files exist"
test -d /usr/lib/millennium
test -d /usr/share/millennium

echo "==> Done"
