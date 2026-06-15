# ydart

[![CI](https://github.com/Knaackee/ydart/actions/workflows/ci.yml/badge.svg)](https://github.com/Knaackee/ydart/actions/workflows/ci.yml)
[![Native mobile release](https://github.com/Knaackee/ydart/actions/workflows/native-release.yml/badge.svg)](https://github.com/Knaackee/ydart/actions/workflows/native-release.yml)

Flutter Android/iOS bindings for [yrs](https://github.com/y-crdt/y-crdt), the
Rust implementation of the Yjs CRDT protocol.

ydart is a mobile-first FFI package for collaborative, offline-first Flutter
apps. It wraps the `yffi` C API from the current upstream `y-crdt` repository.

## Status

This repository has passed the first mobile hardening smoke gate for Android
and iOS. The Dart/Flutter FFI layer is tested against the current upstream
`y-crdt/main`, including Android device/emulator integration tests and GitHub
release artifact generation.

Verified coverage:

- Android/iOS Flutter plugin structure.
- Pointer-light Dart APIs: `YMap.set` and `YArray.insertValues`.
- Native ownership notes in [doc/ffi_ownership_audit.md](doc/ffi_ownership_audit.md).
- Host unit tests for Dart value conversion, transaction handling, sync, and
  native-test harnesses.
- Example Flutter sync harness in [example/](example/).
- WebSocket relay test server in [tool/sync_relay_server.dart](tool/sync_relay_server.dart).
- Android integration tests for direct native API calls and the example app UI.
- GitHub Actions for CI and reproducible native release artifacts.

Current production-readiness status: suitable for mobile app integration testing
and internal/beta builds. Before using ydart in a high-stakes production app,
run your own soak tests with real user flows, enable native crash reporting, and
pin the exact native release artifact you ship.

Last verified smoke release:

- CI: <https://github.com/Knaackee/ydart/actions/runs/27533022293>
- Native mobile release: <https://github.com/Knaackee/ydart/actions/runs/27533472813>
- GitHub Release: <https://github.com/Knaackee/ydart/releases/tag/mobile-native-smoke>

## Supported platforms

| Platform | Status | Native artifact |
| --- | --- | --- |
| Android | Supported | `android/src/main/jniLibs/<abi>/libyrs.so` |
| iOS | Supported | `ios/Frameworks/libyrs.xcframework` |
| Windows, Linux, macOS | Not supported by this package | - |
| Web | Not supported | - |

## System requirements

Common:

- Flutter 3.24 or newer
- Dart 3.5 or newer
- Git
- Rust stable for Dart/Flutter checks
- Rust nightly for current `y-crdt/main` native builds while upstream uses
  `if let` guards
- Current `y-crdt` checkout from <https://github.com/y-crdt/y-crdt>

Android:

- Android SDK
- Android NDK r28c for the release workflow
- `cargo-ndk`
- Rust targets: `aarch64-linux-android`, `armv7-linux-androideabi`,
  `x86_64-linux-android`

iOS:

- macOS
- Xcode and command-line tools
- `cbindgen`
- Rust targets: `aarch64-apple-ios`, `aarch64-apple-ios-sim`,
  `x86_64-apple-ios`

## Build native libraries

Clone current upstream next to this repository:

```bash
git clone https://github.com/y-crdt/y-crdt.git ../y-crdt
```

Record the exact commit for reproducible builds:

```bash
git -C ../y-crdt rev-parse HEAD
```

### Android

```bash
cargo install cargo-ndk --locked
rustup toolchain install nightly
rustup target add --toolchain nightly aarch64-linux-android armv7-linux-androideabi x86_64-linux-android
```

Build and copy libraries:

```powershell
.\tool\build_android.ps1 -YrsSourceDir ..\y-crdt
```

Expected outputs:

```text
android/src/main/jniLibs/arm64-v8a/libyrs.so
android/src/main/jniLibs/armeabi-v7a/libyrs.so
android/src/main/jniLibs/x86_64/libyrs.so
```

### iOS

Run on macOS:

```bash
YRS_SOURCE_DIR=../y-crdt ./tool/build_ios.sh
```

Expected output:

```text
ios/Frameworks/libyrs.xcframework
```

## GitHub release builds

The **Native mobile release** workflow builds native artifacts from
`y-crdt/y-crdt` and uploads them to a GitHub Release.

Manual run:

```bash
gh workflow run native-release.yml -f y_crdt_ref=main -f release_tag=mobile-native-smoke
gh run list --limit 10
```

Published assets:

- `ydart-android-libyrs.zip`
- `ydart-ios-libyrs-xcframework.zip`

The Android ZIP contains:

- `android/src/main/jniLibs/arm64-v8a/libyrs.so`
- `android/src/main/jniLibs/armeabi-v7a/libyrs.so`
- `android/src/main/jniLibs/x86_64/libyrs.so`

The iOS ZIP contains:

- `libyrs.xcframework`

The workflow uses Rust nightly and temporarily enables `#![feature(if_let_guard)]`
in the CI checkout if current upstream still needs it. It does not modify this
repository or vendor a fork of `y-crdt`.

The workflows opt into GitHub's Node 24 action runtime by setting
`FORCE_JAVASCRIPT_ACTIONS_TO_NODE24=true`.

## Usage

```dart
import 'package:ydart/ydart.dart';

void main() {
  final doc = YDoc();
  final text = doc.getText('content');
  final map = doc.getMap('meta');

  doc.transact((txn) {
    text.insert(txn, 0, 'Hello from ydart!');
    map.set(txn, 'version', 1);
  });

  final other = YDoc();
  other.applyV1(doc.stateDiffV1(other.stateVectorV1()));

  doc.dispose();
  other.dispose();
}
```

## Example app and relay server

Run the mobile sync harness:

```bash
cd example
flutter run
```

Run the local relay server for transport experiments:

```bash
dart run tool/sync_relay_server.dart 8080
```

The server only relays WebSocket messages. It does not inspect or modify CRDT
updates.

## Testing

Host checks:

```bash
flutter pub get
dart format --set-exit-if-changed .
flutter analyze
dart test
cd example && flutter pub get && flutter analyze
```

Android device/emulator checks:

```bash
cd example
flutter test integration_test/native_api_test.dart -d <device-id>
flutter test integration_test/sync_harness_test.dart -d <device-id>
```

`native_api_test.dart` covers direct FFI calls for text, map, array, state-sync,
and a Yjs V1 update fixture. `sync_harness_test.dart` drives the example UI
through edit and sync flows, including the regression path that previously
crashed in `ytext_insert`.

The crash regression was reproduced on Android in the example app and fixed in
the FFI transaction/input handling layer. The GitHub CI now runs the same
regression flow on an Android emulator.

Generate a Yjs update fixture:

```bash
npm install
npm run yjs:fixture
```

Native runtime tests are skipped on desktop unless `YDART_LIBYRS_PATH` points to
a compatible development library:

```powershell
$env:YDART_LIBYRS_PATH = "C:\path\to\yrs.dll"
dart test
```

## App Store and Play Store notes

ydart bundles ordinary native libraries:

- Android includes `libyrs.so` per ABI.
- iOS vendors `libyrs.xcframework` through CocoaPods.

This model is compatible with normal Flutter release builds, provided your app
and all native dependencies comply with Apple App Store and Google Play policies.
ydart does not download executable code at runtime and does not use JIT
compilation in release apps.

## License

MIT.
