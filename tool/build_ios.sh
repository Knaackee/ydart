#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
YRS_SOURCE_DIR="${YRS_SOURCE_DIR:-"$(cd "$ROOT/.." && pwd)/y-crdt"}"
YFFI_DIR="$YRS_SOURCE_DIR/yffi"

if [[ ! -d "$YFFI_DIR" ]]; then
  echo "Cannot find yffi at '$YFFI_DIR'. Set YRS_SOURCE_DIR to a y-crdt checkout." >&2
  exit 1
fi

command -v cargo >/dev/null || {
  echo "Cannot find cargo. Install Rust with rustup first." >&2
  exit 1
}

rustup toolchain install nightly
rustup target add --toolchain nightly aarch64-apple-ios aarch64-apple-ios-sim x86_64-apple-ios

YRS_LIB="$YRS_SOURCE_DIR/yrs/src/lib.rs"
ORIGINAL_YRS_LIB="$(mktemp)"
cp "$YRS_LIB" "$ORIGINAL_YRS_LIB"
cleanup() {
  cp "$ORIGINAL_YRS_LIB" "$YRS_LIB"
  rm -f "$ORIGINAL_YRS_LIB"
}
trap cleanup EXIT

if grep -R "if let .*=>" "$YRS_SOURCE_DIR/yrs/src" >/dev/null; then
  if ! grep -q "feature(if_let_guard)" "$YRS_LIB"; then
    tmp="$(mktemp)"
    {
      echo "#![feature(if_let_guard)]"
      cat "$YRS_LIB"
    } > "$tmp"
    mv "$tmp" "$YRS_LIB"
  fi
fi

cargo +nightly build --release --manifest-path "$YFFI_DIR/Cargo.toml" --target aarch64-apple-ios
cargo +nightly build --release --manifest-path "$YFFI_DIR/Cargo.toml" --target aarch64-apple-ios-sim
cargo +nightly build --release --manifest-path "$YFFI_DIR/Cargo.toml" --target x86_64-apple-ios

OUT="$ROOT/ios/Frameworks"
rm -rf "$OUT/libyrs.xcframework" "$OUT/ios-simulator"
mkdir -p "$OUT/ios-simulator"

lipo -create \
  "$YRS_SOURCE_DIR/target/aarch64-apple-ios-sim/release/libyrs.a" \
  "$YRS_SOURCE_DIR/target/x86_64-apple-ios/release/libyrs.a" \
  -output "$OUT/ios-simulator/libyrs.a"

xcodebuild -create-xcframework \
  -library "$YRS_SOURCE_DIR/target/aarch64-apple-ios/release/libyrs.a" \
  -library "$OUT/ios-simulator/libyrs.a" \
  -output "$OUT/libyrs.xcframework"

echo "Created $OUT/libyrs.xcframework"
