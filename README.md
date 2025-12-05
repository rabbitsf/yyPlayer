# yyPlayer – Beautiful Offline Media Player

`yyPlayer` is a feature-rich, offline iOS media player with a stunning UI that lets you organize, import, and play your music and video collection with ease. Supports local audio files (MP3 & M4A) and video files (MP4, MOV, M4V & 3GP) with multiple import methods including a WiFi upload server.

## ✨ Key Features

### 🎵 Media Library Management
- **Folder-based organization** – Create, rename, and delete folders to organize your music and videos
- **Beautiful gradient UI** – Modern interface with decorative music and video-themed elements throughout
- **Smart navigation** – Icons next to each file for easy identification (music notes for audio, film icons for video)
- **Swipe gestures** – Swipe left to delete folders or individual media files

### 📤 Multiple Import Methods

#### 1. **WiFi Upload Server**
Upload music and videos directly from your computer via web browser:
- Tap **Upload** button on the home screen
- Toggle the server ON to start
- View your device's IP address
- Open the provided URL in any browser on the same WiFi network
- **Create new folders** directly from the web interface
- **Drag & drop** multiple audio/video files at once
- **Real-time progress bars** show upload status for each file
- **Upload completion notifications** when finished
- **Screen stays awake** while server is running (prevents auto-lock)

#### 2. **Files App Import**
- Tap **Import** on the home screen
- Select or create a destination folder
- Browse and select audio files from the Files app
- Import multiple files at once

### 🎛️ Advanced Media Player
- **Dual player support**: Separate audio player and video player
- **Full playback controls**: Play, Pause, Next, Previous
- **Seek bar** with time display (elapsed/remaining)
- **Repeat modes**: Repeat One, Repeat All
- **Shuffle mode** for randomized playback
- **Background playback** with lock screen controls (audio)
- **Native video player** with full AVPlayer support
- **Full-screen video mode** - Tap full-screen button to watch in landscape
- **Picture-in-Picture** support for videos
- **Remembers playback position** when you pause (audio)

### 📱 Media File Management
- **Multi-select mode** – Select multiple files at once
- **Batch move** – Move selected files to different folders
- **Batch delete** – Delete multiple files with one action
- **Confirmation dialogs** to prevent accidental deletion

### 🎨 Beautiful Design
- **Gradient backgrounds** throughout the app
- **Decorative elements** – Music notes, instruments, and icons on every page
- **Content frames** – Elegant borders that contain page content
- **Smooth animations** and transitions
- **Cohesive color scheme** across all screens

## 🎼 Supported Formats
- **Audio**: `.mp3`, `.m4a`
- **Video**: `.mp4`, `.mov`, `.m4v`, `.3gp`

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

#### Importing Media via WiFi Upload
1. Tap the **Upload** button on the home screen
2. Toggle the upload server **ON**
3. Note the IP address displayed (e.g., `http://192.168.1.100:8080`)
4. On your computer, open a web browser
5. Enter the IP address in the browser
6. Select or create a destination folder
7. Drag and drop your audio/video files or click to browse
8. Wait for uploads to complete (progress bars show status)

#### Importing Media via Files App
1. Tap the **Import** button
2. Tap **Select or Create Folder**
3. Choose an existing folder or create a new one
4. Tap **Import Music Files**
5. Browse to your audio/video files in the Files app
6. Select one or more supported files (MP3, M4A, MP4, MOV, M4V, 3GP)
7. Tap **Open** to import

#### Playing Media
1. Tap a folder to view its contents
2. Tap an audio file (🎵) or video file (🎬) to start playing
3. **Audio files** open the audio player with album art visualization
4. **Video files** open the video player with embedded video display
5. Use the player controls:
   - **Play/Pause** (large center button)
   - **Previous/Next** (side buttons)
   - **Repeat One** (repeat current item)
   - **Repeat All** (loop entire folder)
   - **Shuffle** (randomize playback order)
   - **Seek bar** to jump to any position

#### Managing Media Files
1. Open a folder
2. Tap **Select** in the top right
3. Tap files to select them (green checkmark appears)
4. Choose an action:
   - **Move** – Transfer to another folder
   - **Delete** – Remove permanently (with confirmation)
5. Tap **Cancel** to exit selection mode

## 📱 App Structure

### Main Screens
- **Media Player** (Home) – View all folders, access main features
- **Folder View** – Browse audio/video files in a folder, multi-select management
- **Audio Player View** – Full-screen audio playback with all controls
- **Video Player View** – Full-screen video playback with embedded player
- **Import View** – Import from Files app
- **Upload View** – WiFi upload server controls and status

## 🔒 Privacy & Storage
- **100% offline** – No internet connection required (except for WiFi uploads)
- **Local storage only** – All media stored in app's Documents directory
- **No data collection** – Your media stays on your device
- **No tracking** – Complete privacy

## 🛠️ Technical Details
- Built with **SwiftUI** for iOS
- Uses **AVAudioPlayer** for audio playback
- Uses **AVPlayer** and **AVKit** for video playback
- **Network framework** for WiFi upload server
- **FileManager** for local file operations
- Supports **background audio** with AVAudioSession
- **Lock screen controls** via MPNowPlayingInfoCenter
- **Native video rendering** with VideoPlayer component

## 📝 Tips & Tricks
- Use **WiFi upload** for batch importing large media collections from your computer
- Organize by genre, artist, mood, or type using folders
- **Swipe left** on any folder or media file for quick delete
- Use **Shuffle** mode to discover forgotten favorites
- **Repeat One** is perfect for learning song lyrics or watching tutorial videos
- The upload server automatically turns off when you leave the Upload screen
- **Screen won't auto-lock** while upload server is running - perfect for long uploads
- Video files are automatically identified with a film icon 🎬
- Audio files show a music note icon 🎵
- **Tap full-screen button** in video player to watch in landscape mode
- **Rotate your device** to landscape for better video viewing experience

## 🐛 Troubleshooting

### WiFi Upload Not Working
- Ensure device and computer are on the **same WiFi network**
- Check that the upload server is **toggled ON**
- Verify you're entering the correct IP address
- Try disabling VPN if active
- Restart the app if connection issues persist

### Media Files Not Importing
- Verify file format is supported (MP3, M4A, MP4, MOV, M4V, 3GP)
- Check that files aren't corrupted
- Ensure sufficient storage space on device
- For video files, ensure they use codecs supported by iOS (H.264/HEVC for video, AAC for audio)

### Playback Issues
- Close and reopen the app
- Check that files imported successfully
- Verify audio isn't muted on device

## 🎯 Future Enhancements
- Playlist creation and management
- Equalizer settings for audio
- Search functionality
- Metadata editing (artist, album, artwork)
- Video quality settings
- Subtitle support for videos
- More media format support
- Chromecast/AirPlay support

## 📄 License
This project is open source. Feel free to use, modify, and distribute.

## 🙏 Acknowledgments
Built with ❤️ using Swift and SwiftUI

---

**Enjoy your music and videos! 🎵🎬**
