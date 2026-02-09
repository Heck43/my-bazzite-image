#!/usr/bin/env bash
set -euo pipefail

echo "==> Installing build deps"
rpm-ostree install -y --allow-inactive curl tar jq
rpm-ostree cleanup -m

ver="2.34.0"
api="https://api.github.com/repos/SteamClientHomebrew/Millennium/releases/tags/v${ver}"

tmp="/tmp/millennium"
rm -rf "$tmp"
mkdir -p "$tmp"
cd "$tmp"

echo "==> Fetching release assets via GitHub API: v${ver}"
curl -fsSL "$api" -o release.json

echo "==> Assets:"
jq -r '.assets[] | "\(.name)\t\(.browser_download_url)"' release.json

# Берём все linux x86_64 архивы (если их несколько — установим все)
mapfile -t urls < <(jq -r '.assets[]
  | select(.name|test("linux-x86_64.*\\.(tar\\.gz|tgz)$"))
  | .browser_download_url' release.json)

if [[ "${#urls[@]}" -eq 0 ]]; then
  echo "ERROR: No linux-x86_64 tarballs found in release v${ver}"
  exit 1
fi

echo "==> Downloading ${#urls[@]} tarball(s)"
i=0
for u in "${urls[@]}"; do
  i=$((i+1))
  f="asset-${i}.tar.gz"
  echo "  - $u"
  curl -fL "$u" -o "$f"
done

echo "==> Unpacking + installing payload(s)"

# /opt может быть ссылкой на /var/opt — так и надо.
mkdir -p /usr /var/opt

for f in asset-*.tar.gz; do
  echo "==> Processing $f"
  rm -rf unpack
  mkdir -p unpack
  tar -xzf "$f" -C unpack

  if [[ -d "unpack/usr" ]]; then
    echo "  - Installing ./usr -> /usr"
    cp -a unpack/usr/. /usr/
  fi

  if [[ -d "unpack/opt" ]]; then
    echo "  - Installing ./opt -> /var/opt (keeps /opt symlink semantics)"
    cp -a unpack/opt/. /var/opt/
  fi
done


echo "==> Verifying something actually installed"
# Подстрой это под реальный путь Millennium после распаковки.
# (Оставил несколько типичных проверок)
if [[ -d /usr/lib/millennium || -d /usr/share/millennium || -e /usr/bin/millennium ]]; then
  echo "==> Millennium payload seems present"
else
  echo "WARNING: Millennium payload dirs not found under /usr."
  echo "Listing probable locations:"
  find /usr -maxdepth 3 -iname '*millennium*' 2>/dev/null | head -n 200 || true
  echo "Also checking /opt:"
  find /opt -maxdepth 3 -iname '*millennium*' 2>/dev/null | head -n 200 || true

  echo "ERROR: Installed tarballs did not place Millennium payload into /usr or /opt."
  exit 1
fi

echo "==> Done"
