#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
tmp_dir="$(mktemp -d)"
trap 'rm -rf "$tmp_dir"' EXIT

cp "$repo_root/build.sh" "$tmp_dir/build.sh"
chmod +x "$tmp_dir/build.sh"

cat > "$tmp_dir/pubspec.yaml" <<'YAML'
name: selene_test
version: 1.2.3+4
YAML

mkdir -p "$tmp_dir/bin"
cat > "$tmp_dir/bin/flutter" <<'SH'
#!/usr/bin/env bash
case "$1" in
  --version)
    echo "Flutter test stub"
    exit 0
    ;;
  clean)
    exit 0
    ;;
  pub)
    exit 0
    ;;
  build)
    printf '%s\n' "$@" > flutter-build-args.txt
    mkdir -p build/app/outputs/flutter-apk
    touch build/app/outputs/flutter-apk/app-arm64-v8a-release.apk
    if grep -Fxq "android-arm64,android-arm" flutter-build-args.txt; then
      touch build/app/outputs/flutter-apk/app-armeabi-v7a-release.apk
    fi
    exit 0
    ;;
  *)
    echo "unexpected flutter command: $*" >&2
    exit 99
    ;;
esac
SH
chmod +x "$tmp_dir/bin/flutter"

output="$(
  cd "$tmp_dir"
  PATH="$tmp_dir/bin:$PATH" ./build.sh --android-arm64-only 2>&1
)"

if ! grep -Fxq "android-arm64" "$tmp_dir/flutter-build-args.txt"; then
  echo "expected Android ARM64 to be the only target platform"
  cat "$tmp_dir/flutter-build-args.txt"
  exit 1
fi

if grep -Fq "android-arm64,android-arm" "$tmp_dir/flutter-build-args.txt"; then
  echo "expected ARM64-only build not to include Android ARMv7"
  cat "$tmp_dir/flutter-build-args.txt"
  exit 1
fi

if [ ! -f "$tmp_dir/dist/selene-1.2.3-armv8.apk" ]; then
  echo "expected ARM64 artifact in dist"
  echo "$output"
  exit 1
fi

if [ -e "$tmp_dir/dist/selene-1.2.3-armv7a.apk" ]; then
  echo "did not expect ARMv7 artifact in an ARM64-only build"
  exit 1
fi

if grep -q "安卓 armv7a APK 文件未找到" <<<"$output"; then
  echo "did not expect an ARMv7 warning in an ARM64-only build"
  echo "$output"
  exit 1
fi

output="$(
  cd "$tmp_dir"
  PATH="$tmp_dir/bin:$PATH" ./build.sh --android-only 2>&1
)"

if ! grep -Fxq "android-arm64,android-arm" "$tmp_dir/flutter-build-args.txt"; then
  echo "expected the existing Android-only option to keep ARM64 and ARMv7"
  cat "$tmp_dir/flutter-build-args.txt"
  exit 1
fi

if [ ! -f "$tmp_dir/dist/selene-1.2.3-armv8.apk" ] ||
   [ ! -f "$tmp_dir/dist/selene-1.2.3-armv7a.apk" ]; then
  echo "expected the existing Android-only option to keep both artifacts"
  echo "$output"
  exit 1
fi
