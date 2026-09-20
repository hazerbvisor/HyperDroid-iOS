# HyperDroid virtual File Explorer

HyperDroid's File Explorer now uses a provider-backed Windows virtual filesystem instead of static placeholder folders.

## Standalone HyperDroid

The standalone app maps:

```text
C:\
```

to:

```text
Documents/HyperDroidVFS/drive_c/
```

and prepares a minimal Windows-style layout:

```text
drive_c/
├── Program Files/
├── Program Files (x86)/
├── windows/
│   └── temp/
└── users/
    └── winpad/
        ├── Desktop/
        ├── Documents/
        ├── Downloads/
        ├── Music/
        ├── Pictures/
        └── Videos/
```

The Explorer can browse folders, navigate Back/Forward/Up, search the current folder, create folders, rename items, delete items, share files, and display real free/total storage rather than fake capacity values.

## WinPad integration

When HyperDroid is embedded as WinPad's desktop shell, configure the active Wine bottle before presenting the desktop:

```swift
HDFileSystemBridge.useVirtualDriveC(
    at: bottle.driveCURL,
    displayName: "Local Disk"
)
```

For WinPad this means:

```text
Explorer C:\
    ↓
HDFileSystemProvider
    ↓
WinPad Bottles/<active bottle>/drive_c/
```

The HyperDroid shell does not need to know about Wine internals, BottleManager, or WinPad's native runtime. It only receives the active `drive_c` URL.

This is intentionally the same layout WinPad already uses for its Wine-style prefix, so files installed by a Windows installer will appear in Explorer immediately.

## Safety

Windows virtual paths are normalized before mapping. `..` traversal and paths outside the configured `drive_c` root are rejected.
