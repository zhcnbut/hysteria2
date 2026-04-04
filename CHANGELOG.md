# Changelog

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
