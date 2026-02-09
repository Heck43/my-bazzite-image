#!/usr/bin/env bash
set -euo pipefail

echo "==> Installing build dependencies (curl, tar, jq)"
rpm-ostree install -y --allow-inactive curl tar jq
rpm-ostree cleanup -m

tmp="/tmp/millennium"
rm -rf "$tmp"
mkdir -p "$tmp"
cd "$tmp"

echo "==> Installing Millennium into the image"

ver="2.34.0"
url="https://github.com/SteamClientHomebrew/Millennium/releases/download/v${ver}/millennium-v${ver}-linux-x86_64.tar.gz"

echo "==> Downloading: $url"
curl -fsSL "$url" -o millennium.tar.gz

echo "==> Inspecting archive..."
# Покажем верхушку, чтобы было понятно что внутри в логах CI
tar -tzf millennium.tar.gz | head -n 50 || true

# КРИТИЧНО: убедимся что это не "только python" архив
# Ищем признаки настоящего Millennium в /usr
if ! tar -tzf millennium.tar.gz | grep -qE '(^\./)?usr/(lib|share)/.*millennium|(^\./)?usr/lib/millennium(/|$)'; then
  echo "ERROR: This tarball does NOT appear to contain Millennium payload under ./usr."
  echo "It looks like it may only contain the bundled python runtime (./opt/python-i686-3.11.8)."
  echo "Refusing to install."
  exit 1
fi

echo "==> Unpacking"
tar -xzf millennium.tar.gz

# Архив обычно начинается с ./
# Ставим /usr часть
if [[ -d "./usr" ]]; then
  echo "==> Copying ./usr -> /usr"
  cp -a ./usr/. /usr/
else
  echo "WARN: Archive has no ./usr directory"
fi

# Ставим /opt часть (если есть)
if [[ -d "./opt" ]]; then
  echo "==> Copying ./opt -> /opt"
  mkdir -p /opt
  cp -a ./opt/. /opt/

  # фикс прав: бинарники в /opt должны быть исполняемыми
  if [[ -f "/opt/python-i686-3.11.8/bin/python3.11" ]]; then
    chmod 755 /opt/python-i686-3.11.8/bin/python3.11 || true
  fi

  # на всякий случай: всё, что похоже на бинарники, делаем executable
  find /opt -type f -maxdepth 5 -name "python*" -exec chmod 755 {} \; 2>/dev/null || true
else
  echo "WARN: Archive has no ./opt directory"
fi

rm -rf "$tmp"

echo "==> Done: Millennium installed"
