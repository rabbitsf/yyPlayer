import SwiftUI
import AVKit

struct VideoPlayerView: View {
    let folderName: String
    let initialSongName: String
    @ObservedObject var videoManager: VideoManager
    @Environment(\.presentationMode) var presentationMode
    
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
                    Image(systemName: "film")
                        .font(.system(size: 45))
                        .foregroundColor(.white.opacity(0.08))
                        .position(x: geo.size.width * 0.12, y: geo.size.height * 0.12)
                    
                    Image(systemName: "play.rectangle")
                        .font(.system(size: 38))
                        .foregroundColor(.white.opacity(0.1))
                        .position(x: geo.size.width * 0.88, y: geo.size.height * 0.15)
                }
                
                Group {
                    // Middle upper decorations
                    Image(systemName: "video.circle")
                        .font(.system(size: 40))
                        .foregroundColor(.white.opacity(0.09))
                        .position(x: geo.size.width * 0.08, y: geo.size.height * 0.3)
                    
                    Image(systemName: "sparkles.tv")
                        .font(.system(size: 42))
                        .foregroundColor(.white.opacity(0.1))
                        .position(x: geo.size.width * 0.92, y: geo.size.height * 0.35)
                }
                
                Group {
                    // Bottom decorations
                    Image(systemName: "popcorn")
                        .font(.system(size: 36))
                        .foregroundColor(.white.opacity(0.09))
                        .position(x: geo.size.width * 0.1, y: geo.size.height * 0.88)
                    
                    Image(systemName: "movieclapper")
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
            
            VStack(spacing: 20) {
                // Video Title
                VStack(spacing: 8) {
                    Image(systemName: "film")
                        .font(.system(size: 50))
                        .foregroundStyle(
                            LinearGradient(
                                gradient: Gradient(colors: [Color.cyan, Color.blue, Color.purple]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .shadow(color: Color.cyan.opacity(0.5), radius: 10, x: 0, y: 5)
                    
                    Text(videoManager.currentSongTitle)
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                        .shadow(color: Color.black.opacity(0.3), radius: 5, x: 0, y: 2)
                }
                .padding(.top, 20)
                
                // Video Player
                if let player = videoManager.getPlayer() {
                    FullScreenVideoPlayer(player: player)
                        .frame(maxWidth: .infinity)
                        .frame(height: 250)
                        .cornerRadius(15)
                        .shadow(color: Color.black.opacity(0.3), radius: 10, x: 0, y: 5)
                        .padding(.horizontal, 20)
                } else {
                    Rectangle()
                        .fill(Color.black.opacity(0.3))
                        .frame(maxWidth: .infinity)
                        .frame(height: 250)
                        .cornerRadius(15)
                        .overlay(
                            Image(systemName: "play.rectangle.fill")
                                .font(.system(size: 60))
                                .foregroundColor(.white.opacity(0.5))
                        )
                        .padding(.horizontal, 20)
                }
                
                // Progress Slider
                VStack(spacing: 8) {
                    Slider(value: Binding(
                        get: { videoManager.currentTime },
                        set: { newValue in
                            videoManager.seek(to: newValue)
                        }
                    ), in: 0...max(videoManager.duration, 1))
                    .tint(
                        LinearGradient(
                            gradient: Gradient(colors: [Color.cyan, Color.blue, Color.purple]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    
                    HStack {
                        Text("\(formatTime(videoManager.currentTime))")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.8))
                        Spacer()
                        Text("\(formatTime(videoManager.duration))")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.8))
                    }
                }
                .padding(.horizontal, 30)
                
                // Playback Controls
                HStack(spacing: 30) {
                    Button(action: {
                        videoManager.previousSong()
                    }) {
                        Image(systemName: "backward.fill")
                            .font(.system(size: 30))
                            .foregroundColor(.white)
                            .frame(width: 55, height: 55)
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
                        videoManager.togglePlayPause()
                    }) {
                        Image(systemName: videoManager.isPlaying ? "pause.fill" : "play.fill")
                            .font(.system(size: 40))
                            .foregroundColor(.white)
                            .frame(width: 75, height: 75)
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
                        videoManager.nextSong()
                    }) {
                        Image(systemName: "forward.fill")
                            .font(.system(size: 30))
                            .foregroundColor(.white)
                            .frame(width: 55, height: 55)
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
                .padding(.vertical, 15)
                
                // Repeat and Shuffle Controls
                HStack(spacing: 40) {
                    Button(action: {
                        videoManager.toggleRepeatOne()
                    }) {
                        Image(systemName: "repeat.1")
                            .font(.title3)
                            .foregroundColor(.white)
                            .frame(width: 45, height: 45)
                            .background(
                                Circle()
                                    .fill(videoManager.repeatMode == .repeatOne ?
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
                            .shadow(color: videoManager.repeatMode == .repeatOne ? Color.yellow.opacity(0.4) : Color.clear, radius: 6, x: 0, y: 3)
                    }
                    
                    Button(action: {
                        videoManager.toggleRepeatAll()
                    }) {
                        Image(systemName: "repeat")
                            .font(.title3)
                            .foregroundColor(.white)
                            .frame(width: 45, height: 45)
                            .background(
                                Circle()
                                    .fill(videoManager.repeatMode == .repeatAll ?
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
                            .shadow(color: videoManager.repeatMode == .repeatAll ? Color.purple.opacity(0.4) : Color.clear, radius: 6, x: 0, y: 3)
                    }
                    
                    Button(action: {
                        videoManager.toggleShuffle()
                    }) {
                        Image(systemName: "shuffle")
                            .font(.title3)
                            .foregroundColor(.white)
                            .frame(width: 45, height: 45)
                            .background(
                                Circle()
                                    .fill(videoManager.isShuffleEnabled ?
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
                            .shadow(color: videoManager.isShuffleEnabled ? Color.blue.opacity(0.4) : Color.clear, radius: 6, x: 0, y: 3)
                    }
                }
                .padding(.vertical, 5)
                
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
                .padding(.bottom, 20)
            }
            .padding(18)
        }
        .onAppear {
            if videoManager.currentSongTitle != initialSongName {
                videoManager.stopPlayback()
                videoManager.startPlayback(folder: folderName, song: initialSongName)
            }
        }
        .onDisappear {
            // Don't stop playback when view disappears - allow background playback
        }
        .navigationBarHidden(false)
        .statusBar(hidden: false)
    }
    
    private func formatTime(_ time: Double) -> String {
        guard time.isFinite && !time.isNaN else { return "00:00" }
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}

