#!/usr/bin/env bash
set -euo pipefail

if [[ "$(uname -s)" != Darwin ]]; then
  echo "This test requires macOS and Xcode command line tools." >&2
  exit 1
fi

project_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
package_config="$project_dir/.dart_tool/package_config.json"
if [[ ! -f "$package_config" ]]; then
  echo "Run flutter pub get before the native keychain test." >&2
  exit 1
fi

plugin_dir="$(ruby -rjson -ruri -e '
  config_path = File.expand_path(ARGV.fetch(0))
  config = JSON.parse(File.read(config_path))
  package = config.fetch("packages").find { |entry| entry["name"] == "flutter_secure_storage_darwin" }
  abort "flutter_secure_storage_darwin is missing from package_config" unless package
  uri = URI.parse(package.fetch("rootUri"))
  path = URI::DEFAULT_PARSER.unescape(uri.path)
  puts uri.scheme == "file" ? path : File.expand_path(path, File.dirname(config_path))
' "$package_config")"
native_source="$plugin_dir/darwin/flutter_secure_storage_darwin/Sources/flutter_secure_storage_darwin/FlutterSecureStorage.swift"
test_dir="$(mktemp -d "${TMPDIR:-/tmp}/selene-keychain-test.XXXXXX")"
trap 'rm -f "$test_dir/keychain-test"; rmdir "$test_dir"' EXIT

xcrun swiftc "$native_source" "$project_dir/test/native/macos_keychain_test.swift" -o "$test_dir/keychain-test"
"$test_dir/keychain-test"
