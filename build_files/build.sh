#!/usr/bin/env bash
set -euo pipefail

echo "==> Installing build dependencies"
rpm-ostree install -y --allow-inactive curl tar jq sudo shadow-utils util-linux
rpm-ostree cleanup -m

echo "==> Creating temporary user for Millennium installer"
# Без mailbox (чтобы не падало на /var/spool/mail)
useradd -m -s /bin/bash -U -M millennium 2>/dev/null || true
mkdir -p /home/millennium
chown -R millennium:millennium /home/millennium

echo "==> Allowing passwordless sudo for installer (temporary)"
cat >/etc/sudoers.d/99-millennium-installer <<'EOF'
millennium ALL=(ALL) NOPASSWD:ALL
EOF
chmod 0440 /etc/sudoers.d/99-millennium-installer

echo "==> Running official Millennium installer as non-root (via setpriv)"
# setpriv не использует PAM как su, поэтому часто проходит в buildah/CI
setpriv --reuid=millennium --regid=millennium --init-groups \
  env HOME=/home/millennium \
  bash -lc 'curl -fsSL https://steambrew.app/install.sh | bash'

echo "==> Cleaning up temporary sudoers"
rm -f /etc/sudoers.d/99-millennium-installer

echo "==> Verifying Millennium files exist"
test -d /usr/lib/millennium
test -d /usr/share/millennium

echo "==> Done"
