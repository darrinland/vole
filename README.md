# Vole

Vole shows what takes up space on your Mac.

Pick a folder. Vole scans every file inside it and draws the results as a sunburst chart. Each ring is one level of folders. The wider the slice, the more disk space it uses.

Vole only reads your files. It never moves, changes, or deletes anything.

## Features

- Sunburst chart of folder sizes, five levels deep.
- Sorted list of the current folder's contents, with sizes and percentages.
- Click a slice or a row to open that folder.
- Click the center of the chart, or press Backspace, to go up one level.
- Breadcrumbs to jump back to any parent folder.
- Right-click a row to reveal the item in Finder.
- Shows how many folders could not be read, with a shortcut to Full Disk Access.

## Requirements

- macOS 14 (Sonoma) or later.
- Xcode 16 or later, or a Swift 6 toolchain, to build from source.

## Build

Run the bundle script from the project folder:

```bash
./scripts/bundle.sh
```

The script builds a release binary. It then creates `Vole.app` in the project folder.

## Run

Open the app:

```bash
open Vole.app
```

Choose **Choose Folder…** to scan any folder. Choose **Scan Home** to scan your home folder.

## Full Disk Access

macOS blocks some folders, such as parts of `~/Library`, until you grant access. Without access, Vole skips those folders and shows a count.

To scan everything:

1. Open System Settings → Privacy & Security → Full Disk Access.
2. Add `Vole.app`.
3. Turn the switch on, then scan again.

## Limits

- Vole does not follow symbolic links. This stops double counting and loops.
- Sizes show allocated disk space, not the logical file size.
- Vole does not delete files. Use Finder to delete what you find.

## Project layout

```
Package.swift                 Swift package manifest
Sources/Vole/
  VoleApp.swift               App entry point and main window
  DiskModel.swift             File tree, scanner, layout, and navigation state
  SunburstView.swift          Sunburst chart drawing and hit testing
  FileListView.swift          Sorted list of folder contents
Resources/Info.plist          App bundle metadata
scripts/bundle.sh             Builds Vole.app
```

## License

See [LICENSE](LICENSE).
