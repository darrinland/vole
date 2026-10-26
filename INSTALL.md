# Install Vole

Vole is a disk usage viewer for macOS. This guide covers installing the app from a download.

Vole is not signed with an Apple developer certificate. macOS blocks it the first time you open it. You allow it once in System Settings. The steps below show how.

## Requirements

- A Mac with macOS 14 (Sonoma) or later.

## 1. Download

1. Open the [Vole releases page](https://github.com/darrinland/vole/releases).
2. Under **v0.1.0**, click **Vole-0.1.0.zip** to download it.

## 2. Unzip and move the app

1. Open the zip file in your Downloads folder. Finder creates **Vole.app**.
2. Drag **Vole.app** into your **Applications** folder.

## 3. Open Vole the first time

1. Open **Applications** in Finder.
2. Double-click **Vole**.
3. macOS shows a message that it cannot verify the app. Click **Done**. Do not click **Move to Trash**.
4. Open **System Settings**. Go to **Privacy & Security**.
5. Scroll to the **Security** section. Find the line that says **"Vole" was blocked to protect your Mac**.
6. Click **Open Anyway**. Enter your Mac password or use Touch ID.
7. In the next dialog, click **Open**.

Vole opens. You only need to do this once.

### If there is no Open Anyway button

Some macOS versions do not show the button. Use this fallback:

1. Open **Terminal**. It is in Applications → Utilities.
2. Paste this line and press Return:

   ```bash
   xattr -dr com.apple.quarantine /Applications/Vole.app
   ```

3. Open **Vole** from Applications.

This command removes the download flag that causes the block. It does not change the app.

## 4. Allow Full Disk Access

Without this permission, macOS hides some folders from Vole. These include parts of your Library folder, Mail, and Safari data. Vole skips them and shows a count of skipped folders.

1. Open **System Settings**. Go to **Privacy & Security**.
2. Click **Full Disk Access**.
3. Click the **+** button. Enter your Mac password if asked.
4. Select **Vole** in Applications. Click **Open**.
5. Turn on the switch next to **Vole**.
6. Quit Vole and open it again.

Vole can now scan those folders.

## Update to a new version

1. Quit Vole.
2. Download the new zip. Follow step 2 to replace the old app.
3. Open Vole. If macOS blocks it again, follow step 3.

Full Disk Access stays on after an update unless macOS resets it. Check the switch if a scan still skips folders.

## Uninstall

1. Quit Vole.
2. Drag **Vole.app** from Applications to the Trash.
3. In **Full Disk Access**, select **Vole** and click **−**.

## Troubleshooting

- **"Vole is damaged and can't be opened"**: use the Terminal fallback in step 3, then open the app again.
- **Scan skips many folders**: confirm the Full Disk Access switch is on, then quit and reopen Vole.
- **Chart is empty after a scan**: the folder you chose may be empty or unreadable. Try **Scan Home**.
