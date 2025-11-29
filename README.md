## yyPlayer – Offline Music Player (MP3 & M4A)

`yyPlayer` is a simple, offline iOS music player that lets you organize your songs into folders and play local audio files stored in the app’s Documents directory.

### Supported formats
- **Audio formats**: `.mp3`, `.m4a`

### Main features
- **Folder-based library**
  - Create and delete folders to organize your songs.
  - Each folder appears as a separate section in the app.

- **Import from Files app**
  - Tap **Import** on the home screen.
  - Tap **Select or Create Folder** to choose where the songs should go.
  - After selecting/creating a folder, tap **Import Music Files**.
  - Browse to your audio files in the Files app and select the `.mp3` / `.m4a` files to import.

- **Player controls**
  - Standard controls: **Play/Pause**, **Next**, **Previous**.
  - **Repeat one**, **Repeat all**, and **Shuffle** modes.
  - Seek bar with elapsed and remaining time.
  - Remembers playback position per track when you pause/stop.
  - Supports background audio playback via `AVAudioSession` and remote-control commands.

- **Manage content**
  - Swipe left on a folder to delete the folder and its contents.
  - Swipe left on a song to delete the file from that folder.

### Requirements
- **iOS**: 15.0 or later (recommended)
- **Xcode**: 15 or later

### Building and running
- Open `yyPlayer.xcodeproj` in Xcode.
- Select an iOS simulator or (recommended) a physical device.
- Press **Run** to build and launch the app.

