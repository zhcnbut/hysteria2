#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "${ROOT_DIR}"

check_cmd() {
    local name="$1"
    if ! command -v "${name}" >/dev/null 2>&1; then
        echo "[ERROR] Missing command: ${name}"
        return 1
    fi
}

check_cmd bash
check_cmd shellcheck
check_cmd grep

echo "[INFO] Running bash syntax checks..."
bash -n hy2.sh
bash -n install.sh

echo "[INFO] Running shellcheck..."
shellcheck -S error -x hy2.sh install.sh scripts/*.sh

echo "[INFO] Checking menu/README consistency..."
bash scripts/check-menu-sync.sh

echo "[INFO] Checking version marker consistency..."
bash scripts/check-version-sync.sh

echo "[INFO] Running smoke E2E checks..."
bash scripts/smoke-e2e.sh

echo "[OK] All checks passed."
