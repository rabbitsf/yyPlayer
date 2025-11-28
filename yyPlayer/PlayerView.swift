import SwiftUI

struct PlayerView: View {
    let folderName: String
    let initialSongName: String
    @ObservedObject var audioManager: AudioManager
    @Environment(\.presentationMode) var presentationMode
    @State private var currentTime: Double = 0
    @State private var duration: Double = 0

    var body: some View {
        ZStack {
            // Beautiful animated gradient background
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 0.1, green: 0.2, blue: 0.4),
                    Color(red: 0.3, green: 0.15, blue: 0.5),
                    Color(red: 0.2, green: 0.3, blue: 0.6),
                    Color(red: 0.4, green: 0.2, blue: 0.5)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 30) {
                // Song Title
                VStack(spacing: 8) {
                    Image(systemName: "music.note")
                        .font(.system(size: 60))
                        .foregroundStyle(
                            LinearGradient(
                                gradient: Gradient(colors: [Color.cyan, Color.blue, Color.purple]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .shadow(color: Color.cyan.opacity(0.5), radius: 10, x: 0, y: 5)
                    
                    Text(audioManager.currentSongTitle)
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                        .shadow(color: Color.black.opacity(0.3), radius: 5, x: 0, y: 2)
                }
                .padding(.top, 40)

                // Progress Slider
                VStack(spacing: 8) {
                    Slider(value: $currentTime, in: 0...duration, onEditingChanged: { isEditing in
                        if !isEditing {
                            audioManager.seek(to: currentTime)
                        }
                    })
                    .tint(
                        LinearGradient(
                            gradient: Gradient(colors: [Color.cyan, Color.blue, Color.purple]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    
                    HStack {
                        Text("\(formatTime(currentTime))")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.8))
                        Spacer()
                        Text("\(formatTime(duration))")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.8))
                    }
                }
                .padding(.horizontal, 30)

                // Playback Controls
                HStack(spacing: 30) {
                    Button(action: {
                        audioManager.previousSong()
                        updateSongDetails()
                    }) {
                        Image(systemName: "backward.fill")
                            .font(.system(size: 35))
                            .foregroundColor(.white)
                            .frame(width: 60, height: 60)
                            .background(
                                Circle()
                                    .fill(
                                        LinearGradient(
                                            gradient: Gradient(colors: [Color.orange, Color.pink]),
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                            )
                            .shadow(color: Color.orange.opacity(0.5), radius: 8, x: 0, y: 4)
                    }
                    
                    Button(action: {
                        audioManager.togglePlayPause()
                    }) {
                        Image(systemName: audioManager.isPlaying ? "pause.fill" : "play.fill")
                            .font(.system(size: 45))
                            .foregroundColor(.white)
                            .frame(width: 80, height: 80)
                            .background(
                                Circle()
                                    .fill(
                                        LinearGradient(
                                            gradient: Gradient(colors: [Color.cyan, Color.blue, Color.purple]),
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                            )
                            .shadow(color: Color.cyan.opacity(0.6), radius: 12, x: 0, y: 6)
                    }
                    
                    Button(action: {
                        audioManager.nextSong()
                        updateSongDetails()
                    }) {
                        Image(systemName: "forward.fill")
                            .font(.system(size: 35))
                            .foregroundColor(.white)
                            .frame(width: 60, height: 60)
                            .background(
                                Circle()
                                    .fill(
                                        LinearGradient(
                                            gradient: Gradient(colors: [Color.green, Color.cyan]),
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                            )
                            .shadow(color: Color.green.opacity(0.5), radius: 8, x: 0, y: 4)
                    }
                }
                .padding(.vertical, 20)

                // Repeat and Shuffle Controls
                HStack(spacing: 40) {
                    Button(action: {
                        audioManager.toggleRepeatOne()
                    }) {
                        Image(systemName: "repeat.1")
                            .font(.title2)
                            .foregroundColor(.white)
                            .frame(width: 50, height: 50)
                            .background(
                                Circle()
                                    .fill(audioManager.repeatMode == .repeatOne ?
                                          LinearGradient(
                                              gradient: Gradient(colors: [Color.yellow, Color.orange]),
                                              startPoint: .topLeading,
                                              endPoint: .bottomTrailing
                                          ) :
                                          LinearGradient(
                                              gradient: Gradient(colors: [Color.gray.opacity(0.3), Color.gray.opacity(0.2)]),
                                              startPoint: .topLeading,
                                              endPoint: .bottomTrailing
                                          )
                                    )
                            )
                            .shadow(color: audioManager.repeatMode == .repeatOne ? Color.yellow.opacity(0.4) : Color.clear, radius: 6, x: 0, y: 3)
                    }
                    
                    Button(action: {
                        audioManager.toggleRepeatAll()
                    }) {
                        Image(systemName: "repeat")
                            .font(.title2)
                            .foregroundColor(.white)
                            .frame(width: 50, height: 50)
                            .background(
                                Circle()
                                    .fill(audioManager.repeatMode == .repeatAll ?
                                          LinearGradient(
                                              gradient: Gradient(colors: [Color.purple, Color.pink]),
                                              startPoint: .topLeading,
                                              endPoint: .bottomTrailing
                                          ) :
                                          LinearGradient(
                                              gradient: Gradient(colors: [Color.gray.opacity(0.3), Color.gray.opacity(0.2)]),
                                              startPoint: .topLeading,
                                              endPoint: .bottomTrailing
                                          )
                                    )
                            )
                            .shadow(color: audioManager.repeatMode == .repeatAll ? Color.purple.opacity(0.4) : Color.clear, radius: 6, x: 0, y: 3)
                    }
                    
                    Button(action: {
                        audioManager.toggleShuffle()
                    }) {
                        Image(systemName: "shuffle")
                            .font(.title2)
                            .foregroundColor(.white)
                            .frame(width: 50, height: 50)
                            .background(
                                Circle()
                                    .fill(audioManager.isShuffleEnabled ?
                                          LinearGradient(
                                              gradient: Gradient(colors: [Color.blue, Color.cyan]),
                                              startPoint: .topLeading,
                                              endPoint: .bottomTrailing
                                          ) :
                                          LinearGradient(
                                              gradient: Gradient(colors: [Color.gray.opacity(0.3), Color.gray.opacity(0.2)]),
                                              startPoint: .topLeading,
                                              endPoint: .bottomTrailing
                                          )
                                    )
                            )
                            .shadow(color: audioManager.isShuffleEnabled ? Color.blue.opacity(0.4) : Color.clear, radius: 6, x: 0, y: 3)
                    }
                }
                .padding(.vertical, 10)

                Spacer()

                // Back Button
                Button(action: {
                    presentationMode.wrappedValue.dismiss()
                }) {
                    HStack {
                        Image(systemName: "arrow.left")
                        Text("Back to Folders")
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(
                        Capsule()
                            .fill(
                                LinearGradient(
                                    gradient: Gradient(colors: [Color.white.opacity(0.3), Color.white.opacity(0.1)]),
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .overlay(
                                Capsule()
                                    .stroke(Color.white.opacity(0.5), lineWidth: 1)
                            )
                    )
                    .shadow(color: Color.black.opacity(0.2), radius: 5, x: 0, y: 3)
                }
                .padding(.bottom, 30)
            }
        }
        .onAppear {
            if audioManager.currentSongTitle != initialSongName {
                audioManager.stopPlayback()
                audioManager.startPlayback(folder: folderName, song: initialSongName)
            }
            updateSongDetails()
            startUpdatingProgress()
        }
        .onChange(of: audioManager.currentSongTitle) { _ in
            updateSongDetails()
        }
    }

    private func startUpdatingProgress() {
        Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { _ in
            currentTime = audioManager.getCurrentTime()
        }
    }

    private func updateSongDetails() {
        currentTime = 0
        duration = audioManager.getDuration()
    }

    private func formatTime(_ time: Double) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}

