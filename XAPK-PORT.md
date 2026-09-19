# HyperDroid iOS — XAPK UI Port

Source UI: `HyperDroid - PC Launcher 2.7` XAPK (`com.binary.hyperdroid`, versionCode 21).

This branch does **not** redesign HyperDroid. The SwiftUI hierarchy is translated from the app's compiled Android resources.

## Ported source layouts in this pass

- `res/layout/activity_main.xml`
- `res/layout-land/taskbar.xml`
- `res/layout/start_menu.xml`
- `res/layout/start_menu_item.xml`
- `res/layout/desktop_item.xml`
- `res/layout/taskbar_item.xml`
- `res/layout/explorer.xml`
- `res/layout-land/explorer_top_navigation.xml`
- `res/layout-land/explorer_side_navigation.xml`
- `res/layout/explorer_item_lg_folder.xml`
- `res/layout/explorer_item_lg_drive.xml`
- `res/layout/settings.xml`
- `res/layout/settings_app_navigation.xml`
- `res/layout/settings_personalize.xml`
- `res/layout/ui_app_titlebar.xml`

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

Original PNG/WebP resources used by these views were extracted from the supplied XAPK. Monochrome Android vector drawables used in the shell were rasterized as template PNG resources so SwiftUI can tint them according to the original light/dark resource colors.

## Next pass

Port remaining app-specific layouts/behavior (Chrome/WebView, Photos, Music, Notepad, Installer), context menus, action-center dialogs, Start search results, Settings subpages, drag/resize behavior, and imported wallpaper handling.
