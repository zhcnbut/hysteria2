# Changelog

## v1.3.0 - 2026-04-05

- Added non-privileged smoke E2E checks and wired them into `verify`, lint, and release workflows.
- Added a library-only entry mode (`HY2_LIB_ONLY=1`) to make `hy2.sh` testable without entering the interactive menu.
- Hardened config/meta writes with atomic file replacement and explicit write-failure handling.
- Improved startup failure diagnosis with categorized hints (permission denied, port in use, ACME failure, parse error).
- Upgraded one-click diagnostics output to structured `结论 + 建议 + 命令` format with de-duplication.

## v1.2.1 - 2026-04-04

- Fixed Linux permission issue where `hysteria-server` could not read `/etc/hysteria/config.yaml`.
- Applied dynamic permission strategy based on real systemd service user.
- Added safer rollback behavior and better startup failure diagnostics.
- Synced menu consistency checks with the latest plain-text menu labels.

## v1.2.0 - 2026-04-04

- Added one-click environment diagnostics and report export/review.
- Added manual backup and restore menu.
- Added full Sing-box profile template output.
- Added self-signed SNI preset domain options.
- Standardized script structure, installer checks, and release quality gates.
