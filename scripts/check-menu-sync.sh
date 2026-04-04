#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "${ROOT_DIR}"

fail() {
    echo "[ERROR] $1"
    exit 1
}

assert_contains() {
    local file="$1"
    local pattern="$2"
    local label="$3"
    if ! grep -Fq "${pattern}" "${file}"; then
        fail "${label} (missing: ${pattern})"
    fi
}

assert_contains "hy2.sh" "=> 请选择操作 [0-10]:" "hy2.sh menu range mismatch"
assert_contains "hy2.sh" "(7) [?] 查看常用指令速查" "hy2.sh menu item 7 missing"
assert_contains "hy2.sh" "(8) [S] 查看 Sing-box 完整模板" "hy2.sh menu item 8 missing"
assert_contains "hy2.sh" "(9) [D] 一键环境诊断" "hy2.sh menu item 9 missing"
assert_contains "hy2.sh" "(10) [R] 查看最近诊断报告" "hy2.sh menu item 10 missing"

assert_contains "README.md" "➡️ 请选择操作 [0-10]:" "README menu range mismatch"
assert_contains "README.md" "(7) ❓ 查看常用指令速查" "README menu item 7 missing"
assert_contains "README.md" "(8) 🧩 查看 Sing-box 完整模板" "README menu item 8 missing"
assert_contains "README.md" "(9) 🩺 一键环境诊断" "README menu item 9 missing"
assert_contains "README.md" "(10) 📄 查看最近诊断报告" "README menu item 10 missing"

echo "[OK] Menu and README preview are in sync."
