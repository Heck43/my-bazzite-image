#!/usr/bin/env bash
set -euo pipefail

echo "==> Installing build dependencies (curl, tar, jq)"
rpm-ostree install -y curl tar jq
rpm-ostree cleanup -m

echo "==> Installing Millennium into the image"
tmp="/tmp/millennium"
rm -rf "$tmp"
mkdir -p "$tmp"

# Get latest stable (non-prerelease) tag from GitHub releases
tag="$(
  curl -fsSL https://api.github.com/repos/SteamClientHomebrew/Millennium/releases \
  | jq -r '[.[] | select(.prerelease==false)][0].tag_name'
)"

if [[ -z "${tag}" || "${tag}" == "null" ]]; then
  echo "ERROR: Could not determine Millennium release tag"
  exit 1
fi

ver="${tag#v}"
url="https://github.com/SteamClientHomebrew/Millennium/releases/download/${tag}/millennium-v${ver}-linux-x86_64.tar.gz"

echo "==> Downloading: $url"
curl -fsSL "$url" -o "$tmp/millennium.tar.gz"

echo "==> Unpacking"
tar -xzf "$tmp/millennium.tar.gz" -C "$tmp"

# The archive contains a 'files/' tree with usr/ and opt/
# IMPORTANT: copy CONTENTS of opt (opt/.) to avoid:
# "cp: cannot overwrite non-directory '/opt' with directory ..."
if [[ -d "$tmp/files/usr" ]]; then
  echo "==> Copying into /usr"
  cp -a "$tmp/files/usr/." /usr/
fi

if [[ -d "$tmp/files/opt" ]]; then
  echo "==> Copying into /opt"
  mkdir -p /opt
  cp -a "$tmp/files/opt/." /opt/
fi

rm -rf "$tmp"
echo "==> Millennium installed"
