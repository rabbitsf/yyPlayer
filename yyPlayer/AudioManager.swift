import Foundation
import AVFoundation
import MediaPlayer

enum RepeatMode {
    case none
    case repeatOne
    case repeatAll
}

class AudioManager: NSObject, ObservableObject, AVAudioPlayerDelegate {
    private var player: AVAudioPlayer?
    private var songs: [String] = []
    private var currentIndex: Int = 0
    private var folderPath: String = ""
    private var playbackPositions: [String: Double] = [:] // Tracks playback positions

    @Published var currentSongTitle: String = "" // Tracks the current song's title
    @Published var isPlaying: Bool = false
    @Published var repeatMode: RepeatMode = .none // Tracks the repeat mode
    @Published var isShuffleEnabled: Bool = false // Tracks shuffle mode
    private var shuffledIndices: [Int] = [] // Tracks shuffled order
    private var shufflePosition: Int = 0 // Current position in shuffled array
    @Published var audioLevels: [CGFloat] = Array(repeating: 0.1, count: 8) // Audio levels for equalizer
    @Published var smoothedAudioLevel: CGFloat = 0.3 // Single smoothed level for waveform
    
    func toggleRepeatOne() {
        repeatMode = repeatMode == .repeatOne ? .none : .repeatOne
    }

    func toggleRepeatAll() {
        repeatMode = repeatMode == .repeatAll ? .none : .repeatAll
    }
    
    func toggleShuffle() {
        isShuffleEnabled.toggle()
        if isShuffleEnabled {
            createShuffledIndices()
        }
    }
    
    private func createShuffledIndices() {
        guard !songs.isEmpty else { return }
        // Create array of indices excluding current song
        var indices = Array(0..<songs.count)
        indices.removeAll { $0 == currentIndex }
        indices.shuffle()
        // Insert current song at the beginning
        shuffledIndices = [currentIndex] + indices
        shufflePosition = 0
    }
    
    func stopPlaybackAndReset() {
        stopPlayback() // Stop the current playback
        currentSongTitle = "" // Reset the current song title
    }

    override init() {
        super.init()
        configureAudioSession()
        configureNowPlaying()
    }

    private func configureAudioSession() {
        do {
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.playback, mode: .default, options: [])
            try audioSession.setActive(true)
        } catch {
            print("Failed to configure audio session: \(error)")
        }
    }

    private func configureNowPlaying() {
        let commandCenter = MPRemoteCommandCenter.shared()
        commandCenter.playCommand.addTarget { [weak self] _ in
            self?.togglePlayPause()
            return .success
        }
        commandCenter.pauseCommand.addTarget { [weak self] _ in
            self?.togglePlayPause()
            return .success
        }
        commandCenter.nextTrackCommand.addTarget { [weak self] _ in
            self?.nextSong()
            return .success
        }
        commandCenter.previousTrackCommand.addTarget { [weak self] _ in
            self?.previousSong()
            return .success
        }
    }

    func startPlayback(folder: String, song: String) {
        folderPath = FileManagerHelper.shared.getFolderPath(folder)
        songs = FileManagerHelper.shared.getSongs(in: folder)
        
        if let index = songs.firstIndex(of: song) {
            currentIndex = index
            currentSongTitle = song // Update the current song title
            if isShuffleEnabled {
                createShuffledIndices()
            }
            playSong(from: playbackPositions[song] ?? 0) // Resume from the last position or start fresh
        }
    }

    private func playSong(from position: Double = 0) {
        let songPath = "\(folderPath)/\(songs[currentIndex])"
        let url = URL(fileURLWithPath: songPath)
        do {
            player = try AVAudioPlayer(contentsOf: url)
            player?.delegate = self
            player?.currentTime = position // Resume from the saved position
            
            // Enable metering for equalizer
            player?.isMeteringEnabled = true
            
            player?.play()
            isPlaying = true
            updateNowPlayingInfo()
            startMeteringTimer()
        } catch {
            print("Failed to play song: \(error)")
        }
    }

    func togglePlayPause() {
        guard let player = player else { return }
        if player.isPlaying {
            player.pause()
            saveCurrentPlaybackPosition() // Save the current position when paused
            isPlaying = false
        } else {
            player.play()
            isPlaying = true
        }
        updateNowPlayingInfo()
    }

    func stopPlayback() {
        saveCurrentPlaybackPosition() // Save the position before stopping
        player?.stop()
        isPlaying = false
        audioLevels = Array(repeating: 0.1, count: 8) // Reset levels
        smoothedAudioLevel = 0.3 // Reset smoothed level
    }
    
    private func startMeteringTimer() {
        Timer.scheduledTimer(withTimeInterval: 0.02, repeats: true) { [weak self] timer in
            guard let self = self, let player = self.player, self.isPlaying else {
                timer.invalidate()
                return
            }
            
            player.updateMeters()
            
            // Use ONLY peak power for maximum dramatic effect - no averaging!
            let peakPower0 = player.peakPower(forChannel: 0)
            let peakPower1 = player.numberOfChannels > 1 ? player.peakPower(forChannel: 1) : peakPower0
            let maxPeak = max(peakPower0, peakPower1)
            
            // Much more aggressive sensitivity range (-30 to 0 dB for extreme response)
            let normalizedLevel = max(0.0, min(1.0, (maxPeak + 30) / 30))
            
            // More aggressive power curve for explosive movement
            let boostedLevel = pow(normalizedLevel, 0.5)
            
            // Create varied bar heights with HUGE variance and NO smoothing
            DispatchQueue.main.async {
                self.audioLevels = (0..<8).map { index in
                    // Extreme variance between bars
                    let variance = CGFloat.random(in: 0.3...1.7)
                    let baseLevel = CGFloat(boostedLevel) * variance
                    // NO smoothing - instant reaction!
                    return max(0.2, min(1.0, baseLevel))
                }
                
                // Smooth single level for waveform - much heavier smoothing
                let targetLevel = CGFloat(boostedLevel) * 0.8 + 0.2 // Range 0.2-1.0
                self.smoothedAudioLevel = self.smoothedAudioLevel * 0.85 + targetLevel * 0.15 // Heavy smoothing
            }
        }
    }

    func nextSong() {
        saveCurrentPlaybackPosition()
        
        if isShuffleEnabled {
            // Use shuffle logic
            if shufflePosition < shuffledIndices.count - 1 {
                shufflePosition += 1
                currentIndex = shuffledIndices[shufflePosition]
            } else if repeatMode == .repeatAll {
                // Reshuffle and start from beginning
                createShuffledIndices()
                shufflePosition = 0
                currentIndex = shuffledIndices[shufflePosition]
            } else {
                stopPlayback()
                return
            }
        } else {
            // Use normal sequential logic
            if currentIndex < songs.count - 1 {
                currentIndex += 1
            } else if repeatMode == .repeatAll {
                currentIndex = 0 // Loop back to the first song
            } else {
                stopPlayback()
                return
            }
        }
        
        currentSongTitle = songs[currentIndex] // Update the current song title
        playSong()
    }

    func previousSong() {
        saveCurrentPlaybackPosition()
        
        if isShuffleEnabled {
            // Use shuffle logic
            if shufflePosition > 0 {
                shufflePosition -= 1
                currentIndex = shuffledIndices[shufflePosition]
            } else if repeatMode == .repeatAll {
                // Go to the end of shuffled array
                shufflePosition = shuffledIndices.count - 1
                currentIndex = shuffledIndices[shufflePosition]
            } else {
                stopPlayback()
                return
            }
        } else {
            // Use normal sequential logic
            if currentIndex > 0 {
                currentIndex -= 1
            } else if repeatMode == .repeatAll {
                currentIndex = songs.count - 1 // Loop back to the last song
            } else {
                stopPlayback()
                return
            }
        }
        
        currentSongTitle = songs[currentIndex] // Update the current song title
        playSong()
    }

    private func saveCurrentPlaybackPosition() {
        guard let player = player else { return }
        playbackPositions[songs[currentIndex]] = player.currentTime
    }

    func getDuration() -> Double {
        return player?.duration ?? 0
    }

    func getCurrentTime() -> Double {
        return player?.currentTime ?? 0
    }

    func seek(to time: Double) {
        player?.currentTime = time
        if isPlaying {
            player?.play()
        }
        updateNowPlayingInfo()
    }

    private func updateNowPlayingInfo() {
        guard let player = player else { return }
        let nowPlayingInfoCenter = MPNowPlayingInfoCenter.default()
        
        var nowPlayingInfo: [String: Any] = [
            MPMediaItemPropertyTitle: songs[currentIndex],
            MPNowPlayingInfoPropertyElapsedPlaybackTime: player.currentTime,
            MPMediaItemPropertyPlaybackDuration: player.duration,
            MPNowPlayingInfoPropertyPlaybackRate: player.isPlaying ? 1.0 : 0.0
        ]

        if let artworkImage = UIImage(systemName: "music.note") {
            nowPlayingInfo[MPMediaItemPropertyArtwork] = MPMediaItemArtwork(boundsSize: artworkImage.size) { _ in
                return artworkImage
            }
        }

        nowPlayingInfoCenter.nowPlayingInfo = nowPlayingInfo
    }

    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        if repeatMode == .repeatOne {
            playSong() // Replay the same song
        } else {
            nextSong() // Play the next song or loop if in repeatAll
        }
    }
}

