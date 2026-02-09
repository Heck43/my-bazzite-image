#!/usr/bin/env bash
set -euo pipefail

echo "==> Installing build dependencies (curl, tar, jq)"
rpm-ostree install -y curl tar jq
rpm-ostree cleanup -m

tmp="/tmp/millennium"
rm -rf "$tmp"
mkdir -p "$tmp"
cd "$tmp"

echo "==> Installing Millennium into the image"

# (Можно оставить фикс-версию, как у тебя)
ver="2.34.0"
url="https://github.com/SteamClientHomebrew/Millennium/releases/download/v${ver}/millennium-v${ver}-linux-x86_64.tar.gz"

echo "==> Downloading: $url"
curl -fsSL "$url" -o millennium.tar.gz

echo "==> Unpacking"
tar -xzf millennium.tar.gz

# ВАЖНО: структура архива начинается с ./
# Проверяем наличие ./opt
if [[ ! -d "./opt" ]]; then
  echo "ERROR: Archive does not contain ./opt directory"
  echo "Top-level contents:"
  ls -la
  exit 1
fi

echo "==> Copying ./opt -> /opt"
mkdir -p /opt
cp -a ./opt/. /opt/

echo "==> Verifying /opt/python-i686-3.11.8 exists"
if [[ ! -d "/opt/python-i686-3.11.8" ]]; then
  echo "ERROR: /opt/python-i686-3.11.8 was not installed"
  exit 1
fi

rm -rf "$tmp"

echo "==> Millennium installed"
