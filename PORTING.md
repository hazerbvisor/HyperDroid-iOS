# HyperDroid iOS Port

This branch targets a faithful iOS recreation of the existing HyperDroid PC Launcher experience.

## Porting rule

Do not redesign the HyperDroid interface.

The visual target is the existing HyperDroid Windows 11-style desktop shown by the upstream project's screenshots and shipped Android app:

- Windows 11-style centered taskbar
- matching Start menu composition and proportions
- Windows-style desktop shortcuts
- HyperDroid File Explorer / This PC layout
- HyperDroid Settings / Personalize layout
- acrylic/dark Windows 11 surfaces
- floating windows and desktop-oriented pointer behavior
- UiChrome-style web window

Platform-specific Android behavior is replaced only where iOS requires it. The replacement should preserve the original visual language instead of inventing a new one.

## iOS substitutions

A normal iOS app cannot become the actual SpringBoard launcher or enumerate all installed apps. HyperDroid for iOS therefore keeps the same desktop UI while mapping launchable entries to:

- HyperDroid built-in apps/windows
- web apps
- user-configured URL schemes and shortcuts
- Files/document-provider content where available

## XTool Mobile

Open/import the `ios-port-v1` branch in XTool Mobile and build using `xtool-mobile.json`.

The current app uses system frameworks only:

- SwiftUI
- UIKit
- Foundation
- WebKit
