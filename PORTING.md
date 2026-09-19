# HyperDroid iOS Port

This branch is a native SwiftUI recreation of the public HyperDroid experience.

The upstream public repository does not contain the Android application source code; it contains the README, screenshots/assets, privacy policy, and MIT license. Because there is no Android implementation to cross-compile, this port recreates the published behavior with iOS-native APIs.

## Phase 1

Implemented:

- iPad-first desktop shell
- Start menu and taskbar
- draggable/resizable in-app windows
- File Explorer backed by the app Documents directory
- WKWebView browser window for web apps
- Settings/About windows
- touch, pointer, mouse and keyboard compatibility through SwiftUI/UIKit
- XTool Mobile build manifest

Not possible for a normal iOS app:

- becoming the iOS system/default launcher
- enumerating every installed application
- freely launching arbitrary installed applications by package identifier

Those Android-only behaviors will be replaced with user-configured shortcuts, web apps, document providers, and supported URL schemes.

## XTool Mobile

Open/import this branch in XTool Mobile and build using `xtool-mobile.json`.

The project targets iOS/iPadOS 16.0+ and uses only system frameworks:

- SwiftUI
- UIKit
- Foundation
- WebKit
