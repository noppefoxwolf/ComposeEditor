# Repository instructions

## Run tests

Run the iOS test suite with Xcode's package workspace and an iOS Simulator destination:

```sh
xcodebuild -workspace .swiftpm/xcode/package.xcworkspace \
  -scheme ComposeEditor-Package \
  -destination 'platform=iOS Simulator,name=iPhone 17' \
  test
```

`swift test` defaults to the macOS SDK for this iOS-only package and cannot resolve UIKit. Use `xcodebuild` for tests.

Pasteboard tests should use `UIPasteboard.withUniqueName()` and inject that board into the test text views. Reading `UIPasteboard.general` without a user paste gesture can show the system paste confirmation and stall Simulator tests.
