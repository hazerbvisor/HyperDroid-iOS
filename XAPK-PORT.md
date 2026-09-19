# HyperDroid iOS — XAPK UI Port

Source UI: `HyperDroid - PC Launcher 2.7` XAPK (`com.binary.hyperdroid`, versionCode 21).

This branch does **not** redesign HyperDroid. The iOS hierarchy is translated from the app's compiled Android resources and keeps the original resource measurements and artwork wherever the platform permits.

## Ported source layouts

Desktop and shell:
- `res/layout/activity_main.xml`
- `res/layout-land/taskbar.xml`
- `res/layout/start_menu.xml`
- `res/layout/start_menu_item.xml`
- `res/layout/desktop_item.xml`
- `res/layout/taskbar_item.xml`
- `res/layout/ui_app_titlebar.xml`

Taskbar popups:
- `res/layout/taskbar_dialog_action_center.xml`
- `res/layout/taskbar_dialog_action_widgets.xml`
- `res/layout/taskbar_dialog_action_date.xml`
- `res/layout/taskbar_dialog_more_icons.xml`

File Explorer:
- `res/layout/explorer.xml`
- `res/layout-land/explorer_top_navigation.xml`
- `res/layout-land/explorer_side_navigation.xml`
- `res/layout/explorer_item_lg_folder.xml`
- `res/layout/explorer_item_lg_drive.xml`

Settings:
- `res/layout/settings.xml`
- `res/layout/settings_app_navigation.xml`
- `res/layout/settings_personalize.xml`

Built-in app windows:
- `res/layout/app_browser.xml` → native WKWebView content with the HyperDroid browser chrome
- `res/layout/app_image_viewer.xml`
- `res/layout/app_music_player.xml`
- `res/layout/app_notepad.xml`
- `res/layout/app_ui_installer.xml`

## Directly preserved landscape dimensions

- taskbar: 52dp
- taskbar app icon: 26dp
- Start app icon: 32dp
- Start app tile: 76×74dp
- Start app grid height: 222dp
- Start app grid horizontal padding: 28dp
- Start menu radius: 10dp
- Start menu bottom offset: 52dp
- titlebar: 38dp
- titlebar action buttons: 52dp
- Explorer side navigation: 160dp
- Explorer navigation buttons: 32dp
- Settings navigation/content split: 25% / 75%

## Assets

The application icons, File Explorer graphics, taskbar graphics, title-bar controls and other UI artwork are extracted from the supplied XAPK. Android vector resources required by the port are rasterized losslessly as tintable template images. The primary artwork is packed into an embedded atlas so the XTool build does not depend on an external asset-copy step.

## iOS platform substitutions

The UI remains HyperDroid's UI. Only Android-specific system behavior is substituted:
- Android WebView → WKWebView
- Android CalendarView → SwiftUI graphical DatePicker
- Android SeekBar → SwiftUI Slider
- Android EditText → SwiftUI TextField/TextEditor
- Android installed-app/package enumeration is not exposed by normal iOS APIs, so Start entries currently use HyperDroid's built-in desktop apps.

The Android wallpaper view is runtime/user supplied rather than a fixed APK drawable. The iOS shell therefore leaves the desktop wallpaper surface independent so a user-selected wallpaper can be wired without changing the UI hierarchy.
