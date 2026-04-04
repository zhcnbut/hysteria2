#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "${ROOT_DIR}"

fail() {
    echo "[ERROR] $1"
    exit 1
}

version="$(grep -oE 'sh_ver="v[0-9]+\.[0-9]+\.[0-9]+"' hy2.sh | head -n 1 | sed -E 's/.*"(v[0-9]+\.[0-9]+\.[0-9]+)".*/\1/')"
if [[ -z "${version}" ]]; then
    fail "Cannot extract sh_ver from hy2.sh"
fi

major_minor="$(echo "${version}" | sed -E 's/^v([0-9]+\.[0-9]+)\..*$/\1/')"
readme_marker="Hysteria2-LuoPo 管理面板 V${major_minor}"

if ! grep -Fq "${readme_marker}" README.md; then
    fail "README preview version is out of sync. Expected marker: ${readme_marker}"
fi

echo "[OK] Version markers are in sync (${version})."
