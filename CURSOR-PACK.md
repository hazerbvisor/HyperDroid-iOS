# Windows 11 Cursor Pack Support

HyperDroid iOS supports importing Windows `.cur` files from:

https://github.com/SullensCR/Windows-11-Hdpi-Tail-Cursor-Concept-by-jepriCreations

The cursor artwork is credited to **jepriCreations**:

- https://www.deviantart.com/jepricreations
- https://jepricreations.com

## Why the cursor files are not bundled here

The source pack's `Agreement.txt` permits personal use and modification for personal use, but explicitly says the pack files may not be redistributed. HyperDroid therefore does **not** copy those cursor binaries into this public repository or its IPA.

Instead, HyperDroid can import the cursor files locally into its own Application Support directory.

## Importing on iPad

1. Open the cursor-pack repository in Safari.
2. Download the repository ZIP.
3. Extract it in the Files app.
4. Open HyperDroid → Settings → Bluetooth & devices → Mouse.
5. Tap **Import .cur files**.
6. Select the files from either `cursor/assets/light` or `cursor/assets/dark`.

Recommended files:

- `arrow.cur`
- `hand.cur`
- `ibeam.cur`
- `sizewe.cur`
- `sizens.cur`
- `sizenwse.cur`
- `sizenesw.cur`
- `sizeall.cur`
- `no.cur`
- `help.cur`
- `crosshair.cur`
- `uparrow.cur`
- `nwpen.cur`
- `person.cur`
- `pin.cur`

HyperDroid parses the native Windows CUR directory, preserves cursor hotspots, and decodes the 32-bit DIB frames used by this pack. If a specialized cursor was not imported, HyperDroid falls back to the imported arrow cursor.

Animated `.ani` busy cursors are intentionally not imported in this phase.
