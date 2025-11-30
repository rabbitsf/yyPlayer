# yyPlayer – Beautiful Offline Music Player

`yyPlayer` is a feature-rich, offline iOS music player with a stunning UI that lets you organize, import, and play your music collection with ease. Supports local audio files (MP3 & M4A) with multiple import methods including a WiFi upload server.

## ✨ Key Features

### 🎵 Music Library Management
- **Folder-based organization** – Create, rename, and delete folders to organize your music
- **Beautiful gradient UI** – Modern interface with decorative music-themed elements throughout
- **Smart navigation** – Music icons next to each folder for easy identification
- **Swipe gestures** – Swipe left to delete folders or individual songs

### 📤 Multiple Import Methods

#### 1. **WiFi Upload Server** (NEW!)
Upload music directly from your computer via web browser:
- Tap **Upload** button on the home screen
- Toggle the server ON to start
- View your device's IP address
- Open the provided URL in any browser on the same WiFi network
- **Create new folders** directly from the web interface
- **Drag & drop** multiple MP3/M4A files at once
- **Real-time progress bars** show upload status for each file
- **Upload completion notifications** when finished

#### 2. **Files App Import**
- Tap **Import** on the home screen
- Select or create a destination folder
- Browse and select audio files from the Files app
- Import multiple files at once

### 🎛️ Advanced Music Player
- **Full playback controls**: Play, Pause, Next, Previous
- **Seek bar** with time display (elapsed/remaining)
- **Repeat modes**: Repeat One, Repeat All
- **Shuffle mode** for randomized playback
- **Background playback** with lock screen controls
- **Remembers playback position** when you pause

### 📱 Song Management (NEW!)
- **Multi-select mode** – Select multiple songs at once
- **Batch move** – Move selected songs to different folders
- **Batch delete** – Delete multiple songs with one action
- **Confirmation dialogs** to prevent accidental deletion

### 🎨 Beautiful Design
- **Gradient backgrounds** throughout the app
- **Decorative elements** – Music notes, instruments, and icons on every page
- **Content frames** – Elegant borders that contain page content
- **Smooth animations** and transitions
- **Cohesive color scheme** across all screens

## 🎼 Supported Formats
- **Audio**: `.mp3`, `.m4a`

## 📋 Requirements
- **iOS**: 15.0 or later
- **Xcode**: 15 or later (for development)
- **WiFi network**: Required for WiFi upload feature (device and computer must be on same network)

## 🚀 Getting Started

### Installation
1. Open `yyPlayer.xcodeproj` in Xcode
2. Select an iOS simulator or physical device (recommended for full features)
3. Press **Run** to build and launch the app

### Quick Start Guide

#### Creating Your First Folder
1. Launch the app
2. Tap the **Add** button
3. Enter a folder name
4. Tap OK

#### Importing Music via WiFi Upload
1. Tap the **Upload** button on the home screen
2. Toggle the upload server **ON**
3. Note the IP address displayed (e.g., `http://192.168.1.100:8080`)
4. On your computer, open a web browser
5. Enter the IP address in the browser
6. Select or create a destination folder
7. Drag and drop your music files or click to browse
8. Wait for uploads to complete (progress bars show status)

#### Importing Music via Files App
1. Tap the **Import** button
2. Tap **Select or Create Folder**
3. Choose an existing folder or create a new one
4. Tap **Import Music Files**
5. Browse to your audio files in the Files app
6. Select one or more `.mp3` or `.m4a` files
7. Tap **Open** to import

#### Playing Music
1. Tap a folder to view its songs
2. Tap a song to start playing
3. Use the player controls:
   - **Play/Pause** (large center button)
   - **Previous/Next** (side buttons)
   - **Repeat One** (repeat current song)
   - **Repeat All** (loop entire folder)
   - **Shuffle** (randomize playback order)
   - **Seek bar** to jump to any position

#### Managing Songs
1. Open a folder
2. Tap **Select** in the top right
3. Tap songs to select them (green checkmark appears)
4. Choose an action:
   - **Move** – Transfer to another folder
   - **Delete** – Remove permanently (with confirmation)
5. Tap **Cancel** to exit selection mode

## 📱 App Structure

### Main Screens
- **Music Player** (Home) – View all folders, access main features
- **Folder View** – Browse songs in a folder, multi-select management
- **Player View** – Full-screen playback with all controls
- **Import View** – Import from Files app
- **Upload View** – WiFi upload server controls and status

## 🔒 Privacy & Storage
- **100% offline** – No internet connection required (except for WiFi uploads)
- **Local storage only** – All music stored in app's Documents directory
- **No data collection** – Your music stays on your device
- **No tracking** – Complete privacy

## 🛠️ Technical Details
- Built with **SwiftUI** for iOS
- Uses **AVAudioPlayer** for playback
- **Network framework** for WiFi upload server
- **FileManager** for local file operations
- Supports **background audio** with AVAudioSession
- **Lock screen controls** via MPNowPlayingInfoCenter

## 📝 Tips & Tricks
- Use **WiFi upload** for batch importing large music collections from your computer
- Organize by genre, artist, or mood using folders
- **Swipe left** on any folder or song for quick delete
- Use **Shuffle** mode to discover forgotten favorites
- **Repeat One** is perfect for learning song lyrics
- The upload server automatically turns off when you leave the Upload screen

## 🐛 Troubleshooting

### WiFi Upload Not Working
- Ensure device and computer are on the **same WiFi network**
- Check that the upload server is **toggled ON**
- Verify you're entering the correct IP address
- Try disabling VPN if active
- Restart the app if connection issues persist

### Songs Not Importing
- Verify file format is `.mp3` or `.m4a`
- Check that files aren't corrupted
- Ensure sufficient storage space on device

### Playback Issues
- Close and reopen the app
- Check that files imported successfully
- Verify audio isn't muted on device

## 🎯 Future Enhancements
- Playlist creation and management
- Equalizer settings
- Search functionality
- Metadata editing (artist, album, artwork)
- More audio format support

## 📄 License
This project is open source. Feel free to use, modify, and distribute.

## 🙏 Acknowledgments
Built with ❤️ using Swift and SwiftUI

---

**Enjoy your music! 🎵**
