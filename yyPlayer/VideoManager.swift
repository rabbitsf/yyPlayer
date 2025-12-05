import Foundation
import AVFoundation
import AVKit
import MediaPlayer

class VideoManager: NSObject, ObservableObject {
    private var player: AVPlayer?
    private var playerItem: AVPlayerItem?
    private var timeObserver: Any?
    private var songs: [String] = []
    private var currentIndex: Int = 0
    private var folderPath: String = ""
    
    @Published var currentSongTitle: String = ""
    @Published var isPlaying: Bool = false
    @Published var repeatMode: RepeatMode = .none
    @Published var isShuffleEnabled: Bool = false
    @Published var currentTime: Double = 0
    @Published var duration: Double = 0
    
    private var shuffledIndices: [Int] = []
    private var shufflePosition: Int = 0
    
    func getPlayer() -> AVPlayer? {
        return player
    }
    
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
        var indices = Array(0..<songs.count)
        indices.removeAll { $0 == currentIndex }
        indices.shuffle()
        shuffledIndices = [currentIndex] + indices
        shufflePosition = 0
    }
    
    func stopPlaybackAndReset() {
        stopPlayback()
        currentSongTitle = ""
    }
    
    override init() {
        super.init()
        configureAudioSession()
        configureNowPlaying()
    }
    
    private func configureAudioSession() {
        do {
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.playback, mode: .moviePlayback, options: [])
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
        songs = FileManagerHelper.shared.getVideos(in: folder)
        
        if let index = songs.firstIndex(of: song) {
            currentIndex = index
            currentSongTitle = song
            if isShuffleEnabled {
                createShuffledIndices()
            }
            playSong()
        }
    }
    
    private func playSong() {
        let songPath = "\(folderPath)/\(songs[currentIndex])"
        let url = URL(fileURLWithPath: songPath)
        
        // Remove old observer
        if let observer = timeObserver {
            player?.removeTimeObserver(observer)
            timeObserver = nil
        }
        
        // Remove notification observers
        NotificationCenter.default.removeObserver(self)
        
        playerItem = AVPlayerItem(url: url)
        player = AVPlayer(playerItem: playerItem)
        
        // Add periodic time observer
        let interval = CMTime(seconds: 0.5, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
        timeObserver = player?.addPeriodicTimeObserver(forInterval: interval, queue: .main) { [weak self] time in
            guard let self = self else { return }
            self.currentTime = time.seconds
            if let duration = self.playerItem?.duration.seconds, duration.isFinite {
                self.duration = duration
            }
        }
        
        // Add notification for when video finishes
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(playerDidFinishPlaying),
            name: .AVPlayerItemDidPlayToEndTime,
            object: playerItem
        )
        
        player?.play()
        isPlaying = true
        updateNowPlayingInfo()
    }
    
    @objc private func playerDidFinishPlaying() {
        if repeatMode == .repeatOne {
            player?.seek(to: .zero)
            player?.play()
        } else {
            nextSong()
        }
    }
    
    func togglePlayPause() {
        guard let player = player else { return }
        if isPlaying {
            player.pause()
            isPlaying = false
        } else {
            player.play()
            isPlaying = true
        }
        updateNowPlayingInfo()
    }
    
    func stopPlayback() {
        if let observer = timeObserver {
            player?.removeTimeObserver(observer)
            timeObserver = nil
        }
        NotificationCenter.default.removeObserver(self)
        player?.pause()
        player = nil
        playerItem = nil
        isPlaying = false
    }
    
    func nextSong() {
        if isShuffleEnabled {
            if shufflePosition < shuffledIndices.count - 1 {
                shufflePosition += 1
                currentIndex = shuffledIndices[shufflePosition]
            } else if repeatMode == .repeatAll {
                createShuffledIndices()
                shufflePosition = 0
                currentIndex = shuffledIndices[shufflePosition]
            } else {
                stopPlayback()
                return
            }
        } else {
            if currentIndex < songs.count - 1 {
                currentIndex += 1
            } else if repeatMode == .repeatAll {
                currentIndex = 0
            } else {
                stopPlayback()
                return
            }
        }
        
        currentSongTitle = songs[currentIndex]
        playSong()
    }
    
    func previousSong() {
        if isShuffleEnabled {
            if shufflePosition > 0 {
                shufflePosition -= 1
                currentIndex = shuffledIndices[shufflePosition]
            } else if repeatMode == .repeatAll {
                shufflePosition = shuffledIndices.count - 1
                currentIndex = shuffledIndices[shufflePosition]
            } else {
                stopPlayback()
                return
            }
        } else {
            if currentIndex > 0 {
                currentIndex -= 1
            } else if repeatMode == .repeatAll {
                currentIndex = songs.count - 1
            } else {
                stopPlayback()
                return
            }
        }
        
        currentSongTitle = songs[currentIndex]
        playSong()
    }
    
    func seek(to time: Double) {
        let cmTime = CMTime(seconds: time, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
        player?.seek(to: cmTime)
        updateNowPlayingInfo()
    }
    
    private func updateNowPlayingInfo() {
        guard let player = player else { return }
        let nowPlayingInfoCenter = MPNowPlayingInfoCenter.default()
        
        var nowPlayingInfo: [String: Any] = [
            MPMediaItemPropertyTitle: songs[currentIndex],
            MPNowPlayingInfoPropertyElapsedPlaybackTime: currentTime,
            MPMediaItemPropertyPlaybackDuration: duration,
            MPNowPlayingInfoPropertyPlaybackRate: isPlaying ? 1.0 : 0.0
        ]
        
        if let artworkImage = UIImage(systemName: "film") {
            nowPlayingInfo[MPMediaItemPropertyArtwork] = MPMediaItemArtwork(boundsSize: artworkImage.size) { _ in
                return artworkImage
            }
        }
        
        nowPlayingInfoCenter.nowPlayingInfo = nowPlayingInfo
    }
    
    deinit {
        if let observer = timeObserver {
            player?.removeTimeObserver(observer)
        }
        NotificationCenter.default.removeObserver(self)
    }
}

