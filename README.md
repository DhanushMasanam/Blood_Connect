# Blood_Connect

A cross-platform Flutter application to connect blood donors and recipients quickly and reliably. Blood_Connect simplifies finding nearby donors, managing donation requests, and coordinating donations across mobile and desktop platforms.

Highlights
- Cross-platform Flutter UI (Dart) with native extensions (C++/CMake, Swift) for platform-specific features
- Real-time search and matching of donors and requests
- Extensible architecture for backends, push notifications, and native modules

Languages
- Dart — 64%
- C++ — 14.8%
- CMake — 11.8%
- JavaScript — 6.1%
- Swift — 1.4%
- HTML — 0.9%
- Other — 1%

Status
- Repository: DhanushMasanam/Blood_Connect
- Branch for this change: add-readme
- Last updated: see repo commit history

Table of contents
- Features
- Tech stack
- Prerequisites
- Quick start
- Build & run (platforms)
- Native modules (C++/CMake)
- Configuration
- Testing
- Contributing
- License
- Contact / Authors
- Acknowledgements

Features
- Register as donor/recipient
- Create and manage blood requests
- Search and filter donors by blood group, location, availability
- Notifications and request status updates
- Extensible backend integration (REST / GraphQL / Firebase)
- Platform-specific native integrations (location, background tasks) via C++/Swift/CMake modules

Tech stack
- Frontend: Flutter (Dart)
- Native extensions: C++ (CMake), Swift (iOS)
- Web/JS components where applicable
- Build tooling: Flutter SDK, CMake, platform toolchains

Prerequisites
- Flutter SDK (stable)
- Android SDK / Android Studio (Android)
- Xcode (iOS/macOS on macOS)
- CMake and a C/C++ toolchain for native components
- Node.js/npm if web/JS tooling is used
- (Optional) Firebase CLI if the project uses Firebase services

Quick start — development
1. Clone the repository
   git clone https://github.com/DhanushMasanam/Blood_Connect.git
   cd Blood_Connect

2. Install Flutter packages
   flutter pub get

3. Run on a device or emulator
   flutter run

Build & run

Android
- Run:
  flutter run -d <device-id>
- Build release APK:
  flutter build apk --release

iOS
- macOS only: ensure CocoaPods
  cd ios && pod install && cd ..
- Run:
  flutter run -d <device-id>
- Build:
  flutter build ios --release
  (Open ios/Runner.xcworkspace in Xcode for signing)

Web
- Build:
  flutter build web
- Serve locally:
  flutter run -d chrome

Desktop (if enabled)
- Enable target and run:
  flutter run -d <desktop-device-id>
- Build release:
  flutter build macos|windows|linux

Native modules (C++ / CMake)
- Typical build steps (adjust paths as needed):
  mkdir -p native/build
  cd native/build
  cmake ..
  cmake --build .
- Native binaries are expected to be consumed by Flutter via platform channels or FFI — check repo for bindings.

Configuration
- Do NOT commit secrets or service credentials.
- If using Firebase:
  - Place google-services.json in android/app/
  - Place GoogleService-Info.plist in ios/Runner/
- Add environment variables or local config files as described in repo docs.

Testing
- Unit & widget tests:
  flutter test
- Integration tests:
  flutter drive --target=test_driver/app.dart
  (Adjust for repo's test setup.)

Troubleshooting
- Failed packages: flutter pub get --verbose
- CocoaPods issues: cd ios && pod repo update && pod install
- Native build issues: verify your C/C++ toolchain and CMake versions

Contributing
- Fork the repo
- Create a feature branch: git checkout -b feat/your-feature
- Commit and push; open a pull request with a clear description
- Include tests for new features and follow code style

License
- No license currently included. Recommend MIT unless you prefer another license. Tell me which license to add.

Contact / Authors
- Repository owner: DhanushMasanam
- Open issues or feature requests on GitHub

Acknowledgements
- Built with Flutter and native toolchains.
- Thanks to contributors and maintainers.

Placeholders
- [Add screenshots here]
- [Add backend or Firebase setup details if applicable]