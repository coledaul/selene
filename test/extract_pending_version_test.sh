#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
extractor="$repo_root/scripts/extract_pending_version.sh"

if [ ! -f "$extractor" ]; then
  echo "missing pending version extractor"
  exit 1
fi

temp_dir="$(mktemp -d)"
trap 'rm -rf "$temp_dir"' EXIT

fixture="$temp_dir/CHANGELOG.md"

cat >"$fixture" <<'EOF'
# 更新日志

## [2.1.0] - 未发布

- 待发布变化。

## [2.0.0] - 2026-08-01

- 已发布变化。
EOF

version="$(bash "$extractor" "$fixture")"
if [ "$version" != "2.1.0" ]; then
  echo "pending version extractor returned $version; expected 2.1.0"
  exit 1
fi

cat >"$fixture" <<'EOF'
# 更新日志

## [2.2.0] - 未发布

## [2.1.0] - 2026-08-02

- 已发布变化。
EOF

version="$(bash "$extractor" "$fixture")"
if [ "$version" != "2.2.0" ]; then
  echo "empty pending sections must remain valid; got $version"
  exit 1
fi

cat >"$fixture" <<'EOF'
# 更新日志

## [2.0.0] - 2026-08-01

## [2.1.0] - 未发布
EOF

if bash "$extractor" "$fixture" >/dev/null 2>&1; then
  echo "pending version must be the first changelog version section"
  exit 1
fi

cat >"$fixture" <<'EOF'
# 更新日志

## [2.1.0] - 未发布

## [2.2.0] - 未发布
EOF

if bash "$extractor" "$fixture" >/dev/null 2>&1; then
  echo "duplicate pending versions must fail"
  exit 1
fi

cat >"$fixture" <<'EOF'
# 更新日志

## [2.1] - 未发布
EOF

if bash "$extractor" "$fixture" >/dev/null 2>&1; then
  echo "non-semantic pending versions must fail"
  exit 1
fi

repository_version="$(bash "$extractor" "$repo_root/CHANGELOG.md")"
if [[ ! "$repository_version" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]] ||
  ! grep -Fxq "## [$repository_version] - 未发布" "$repo_root/CHANGELOG.md"; then
  echo "repository pending version could not be validated: $repository_version"
  exit 1
fi
