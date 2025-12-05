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
            
            // Decorative background elements
            GeometryReader { geo in
                Group {
                    // Top area decorations
                    Image(systemName: "music.quarternote.3")
                        .font(.system(size: 45))
                        .foregroundColor(.white.opacity(0.08))
                        .position(x: geo.size.width * 0.12, y: geo.size.height * 0.12)
                    
                    Image(systemName: "music.note")
                        .font(.system(size: 38))
                        .foregroundColor(.white.opacity(0.1))
                        .position(x: geo.size.width * 0.88, y: geo.size.height * 0.15)
                }
                
                Group {
                    // Middle upper decorations
                    Image(systemName: "waveform.circle")
                        .font(.system(size: 40))
                        .foregroundColor(.white.opacity(0.09))
                        .position(x: geo.size.width * 0.08, y: geo.size.height * 0.3)
                    
                    Image(systemName: "headphones.circle")
                        .font(.system(size: 42))
                        .foregroundColor(.white.opacity(0.1))
                        .position(x: geo.size.width * 0.92, y: geo.size.height * 0.35)
                }
                
                Group {
                    // Middle decorations
                    Image(systemName: "speaker.wave.2")
                        .font(.system(size: 36))
                        .foregroundColor(.white.opacity(0.08))
                        .position(x: geo.size.width * 0.1, y: geo.size.height * 0.5)
                    
                    Image(systemName: "music.note.list")
                        .font(.system(size: 34))
                        .foregroundColor(.white.opacity(0.09))
                        .position(x: geo.size.width * 0.9, y: geo.size.height * 0.55)
                }
                
                Group {
                    // Lower decorations
                    Image(systemName: "play.circle")
                        .font(.system(size: 40))
                        .foregroundColor(.white.opacity(0.07))
                        .position(x: geo.size.width * 0.12, y: geo.size.height * 0.72)
                    
                    Image(systemName: "guitars")
                        .font(.system(size: 38))
                        .foregroundColor(.white.opacity(0.08))
                        .position(x: geo.size.width * 0.88, y: geo.size.height * 0.75)
                }
                
                Group {
                    // Bottom decorations
                    Image(systemName: "pianokeys")
                        .font(.system(size: 36))
                        .foregroundColor(.white.opacity(0.09))
                        .position(x: geo.size.width * 0.1, y: geo.size.height * 0.88)
                    
                    Image(systemName: "hifispeaker.2")
                        .font(.system(size: 34))
                        .foregroundColor(.white.opacity(0.08))
                        .position(x: geo.size.width * 0.9, y: geo.size.height * 0.9)
                }
                
                // Decorative dots
                ForEach(0..<10) { i in
                    Circle()
                        .fill(Color.white.opacity(0.05 + Double(i % 3) * 0.01))
                        .frame(width: CGFloat(5 + i % 4), height: CGFloat(5 + i % 4))
                        .position(
                            x: geo.size.width * CGFloat([0.25, 0.75, 0.3, 0.7, 0.2, 0.8, 0.35, 0.65, 0.28, 0.72][i]),
                            y: geo.size.height * CGFloat([0.2, 0.25, 0.42, 0.48, 0.62, 0.68, 0.82, 0.85, 0.38, 0.58][i])
                        )
                }
            }
            
            // Content frame
            RoundedRectangle(cornerRadius: 25)
                .stroke(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color.white.opacity(0.2),
                            Color.white.opacity(0.05),
                            Color.white.opacity(0.15),
                            Color.white.opacity(0.08)
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 2
                )
                .padding(15)
            
            VStack(spacing: 30) {
                // Song Title with Equalizer
                VStack(spacing: 15) {
                    // Siri-style Waveform
                    if audioManager.isPlaying {
                        SiriWaveformView(audioLevel: audioManager.smoothedAudioLevel)
                            .padding(.top, 30)
                    } else {
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
                            .padding(.top, 40)
                    }
                    
                    Text(audioManager.currentSongTitle)
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                        .shadow(color: Color.black.opacity(0.3), radius: 5, x: 0, y: 2)
                }
                .padding(.top, 20)

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
            .padding(18)
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

