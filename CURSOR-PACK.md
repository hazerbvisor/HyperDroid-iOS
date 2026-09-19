# Windows 11 Cursor Pack Support

HyperDroid iOS supports importing Windows `.cur` files from:

https://github.com/SullensCR/Windows-11-Hdpi-Tail-Cursor-Concept-by-jepriCreations

The cursor artwork is credited to **jepriCreations**:

- https://www.deviantart.com/jepricreations
- https://jepricreations.com

## Why the cursor files are not bundled here

The source pack's `Agreement.txt` permits personal use and modification for personal use, but explicitly says the pack files may not be redistributed. HyperDroid therefore does **not** copy those cursor binaries into this public repository or its IPA.

Instead, HyperDroid can import the cursor files locally into its own Application Support directory.

## Installing on iPad

Open HyperDroid → Settings → Bluetooth & devices → Mouse, choose **Light** or **Dark**, then tap **Install Windows 11 cursors**.

HyperDroid downloads the static `.cur` files directly from the source repository into its private Application Support directory. The files are not bundled in the IPA and are not committed to this repository.

HyperDroid parses the native Windows CUR directory, preserves cursor hotspots, and decodes the 32-bit DIB frames used by this pack. If a specialized cursor is unavailable, HyperDroid falls back to the installed arrow cursor.

Animated `.ani` busy cursors are intentionally not installed in this phase.
