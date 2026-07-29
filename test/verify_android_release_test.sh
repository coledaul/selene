#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
tmp_dir="$(mktemp -d)"
trap 'rm -rf "$tmp_dir"' EXIT

certificate="2431909a1b7bd4f4132c771a5bab387866dd2e6be6d57d0f2cd9e4d677e4e0b6"
mkdir -p "$tmp_dir/sdk/build-tools/99.0.0" "$tmp_dir/dist"
touch "$tmp_dir/dist/selene-test-armv7a.apk" "$tmp_dir/dist/selene-test-armv8.apk"

cat > "$tmp_dir/sdk/build-tools/99.0.0/apksigner" <<EOF
#!/usr/bin/env bash
echo "  Signer #1 certificate SHA-256 digest: $certificate"
EOF
chmod +x "$tmp_dir/sdk/build-tools/99.0.0/apksigner"

ANDROID_SDK_ROOT="$tmp_dir/sdk" \
  ANDROID_SIGNING_CERT_SHA256="$certificate" \
  bash "$repo_root/scripts/verify_android_release.sh" "$tmp_dir/dist"/*.apk

set +e
ANDROID_SDK_ROOT="$tmp_dir/sdk" \
  ANDROID_SIGNING_CERT_SHA256="$(printf '0%.0s' {1..64})" \
  bash "$repo_root/scripts/verify_android_release.sh" "$tmp_dir/dist"/*.apk >/dev/null 2>&1
status=$?
set -e

if [ "$status" -eq 0 ]; then
  echo "certificate verification must reject an unexpected signer" >&2
  exit 1
fi
