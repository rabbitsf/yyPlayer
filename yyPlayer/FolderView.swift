import SwiftUI

struct FolderView: View {
    let folderName: String
    @ObservedObject var audioManager: AudioManager
    @State private var songs: [String] = []
    @State private var isSelectionMode = false
    @State private var selectedSongs: Set<String> = []
    @State private var showMovePicker = false
    @State private var showDeleteConfirmation = false
    
    private func isCurrentSong(_ song: String) -> Bool {
        audioManager.currentSongTitle == song
    }

    var body: some View {
        ZStack {
            // Beautiful gradient background
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 0.15, green: 0.25, blue: 0.45),
                    Color(red: 0.3, green: 0.2, blue: 0.5),
                    Color(red: 0.25, green: 0.35, blue: 0.6)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            // Decorative background elements
            GeometryReader { geo in
                Group {
                    // Top area decorations
                    Image(systemName: "music.note")
                        .font(.system(size: 40))
                        .foregroundColor(.white.opacity(0.1))
                        .position(x: geo.size.width * 0.15, y: geo.size.height * 0.1)
                    
                    Image(systemName: "music.quarternote.3")
                        .font(.system(size: 35))
                        .foregroundColor(.white.opacity(0.12))
                        .position(x: geo.size.width * 0.85, y: geo.size.height * 0.12)
                }
                
                Group {
                    // Middle decorations
                    Image(systemName: "waveform")
                        .font(.system(size: 32))
                        .foregroundColor(.white.opacity(0.08))
                        .position(x: geo.size.width * 0.1, y: geo.size.height * 0.35)
                    
                    Image(systemName: "music.note.list")
                        .font(.system(size: 30))
                        .foregroundColor(.white.opacity(0.09))
                        .position(x: geo.size.width * 0.9, y: geo.size.height * 0.4)
                }
                
                Group {
                    // Lower middle decorations
                    Image(systemName: "hifispeaker")
                        .font(.system(size: 36))
                        .foregroundColor(.white.opacity(0.11))
                        .position(x: geo.size.width * 0.12, y: geo.size.height * 0.6)
                    
                    Image(systemName: "headphones")
                        .font(.system(size: 34))
                        .foregroundColor(.white.opacity(0.1))
                        .position(x: geo.size.width * 0.88, y: geo.size.height * 0.65)
                }
                
                Group {
                    // Bottom decorations
                    Image(systemName: "play.circle")
                        .font(.system(size: 38))
                        .foregroundColor(.white.opacity(0.09))
                        .position(x: geo.size.width * 0.15, y: geo.size.height * 0.85)
                    
                    Image(systemName: "music.mic")
                        .font(.system(size: 32))
                        .foregroundColor(.white.opacity(0.08))
                        .position(x: geo.size.width * 0.85, y: geo.size.height * 0.88)
                }
                
                // Decorative dots
                ForEach(0..<8) { i in
                    Circle()
                        .fill(Color.white.opacity(0.06))
                        .frame(width: CGFloat(6 + i % 3), height: CGFloat(6 + i % 3))
                        .position(
                            x: geo.size.width * CGFloat([0.3, 0.7, 0.25, 0.75, 0.2, 0.8, 0.35, 0.65][i]),
                            y: geo.size.height * CGFloat([0.18, 0.24, 0.48, 0.52, 0.72, 0.78, 0.3, 0.55][i])
                        )
                }
            }
            
            // Content frame
            RoundedRectangle(cornerRadius: 20)
                .stroke(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color.white.opacity(0.25),
                            Color.white.opacity(0.08),
                            Color.white.opacity(0.15)
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 2
                )
                .padding(12)
            
            List {
                ForEach(songs, id: \.self) { song in
                    if isSelectionMode {
                        selectionModeRow(for: song)
                    } else {
                        normalModeRow(for: song)
                    }
                }
                .onDelete(perform: deleteSong)
            }
            .scrollContentBackground(.hidden)
            .clipShape(RoundedRectangle(cornerRadius: 18))
            .padding(14)
            .navigationTitle(folderName)
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        isSelectionMode.toggle()
                        if !isSelectionMode {
                            selectedSongs.removeAll()
                        }
                    }) {
                        Text(isSelectionMode ? "Cancel" : "Select")
                            .foregroundColor(.white)
                    }
                }
            }
            .safeAreaInset(edge: .bottom) {
                if isSelectionMode && !selectedSongs.isEmpty {
                    HStack(spacing: 15) {
                        Button(action: {
                            showMovePicker = true
                        }) {
                            Label("Move", systemImage: "folder")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(
                                    LinearGradient(
                                        gradient: Gradient(colors: [Color.blue, Color.cyan]),
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .cornerRadius(12)
                        }
                        
                        Button(action: {
                            showDeleteConfirmation = true
                        }) {
                            Label("Delete", systemImage: "trash")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(
                                    LinearGradient(
                                        gradient: Gradient(colors: [Color.red, Color.orange]),
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .cornerRadius(12)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(.ultraThinMaterial)
                }
            }
        }
        .sheet(isPresented: $showMovePicker) {
            MoveToFolderView(
                currentFolder: folderName,
                songsToMove: Array(selectedSongs),
                onComplete: {
                    selectedSongs.removeAll()
                    isSelectionMode = false
                    loadSongs()
                }
            )
        }
        .alert("Delete Songs", isPresented: $showDeleteConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                deleteSelectedSongs()
            }
        } message: {
            Text("Are you sure you want to delete \(selectedSongs.count) song(s)?")
        }
        .onAppear {
            loadSongs()
        }
    }

    private func loadSongs() {
        songs = FileManagerHelper.shared.getSongs(in: folderName)
    }

    private func deleteSong(at offsets: IndexSet) {
        for index in offsets {
            let song = songs[index]
            do {
                try FileManagerHelper.shared.deleteSong(song, in: folderName)
                songs.remove(at: index) // Remove from the list
            } catch {
                print("Failed to delete song: \(error)")
            }
        }
    }
    
    private func deleteSelectedSongs() {
        for song in selectedSongs {
            do {
                try FileManagerHelper.shared.deleteSong(song, in: folderName)
            } catch {
                print("Failed to delete song: \(error)")
            }
        }
        selectedSongs.removeAll()
        isSelectionMode = false
        loadSongs()
    }
    
    // MARK: - Helper Views
    @ViewBuilder
    private func selectionModeRow(for song: String) -> some View {
        Button(action: {
            if selectedSongs.contains(song) {
                selectedSongs.remove(song)
            } else {
                selectedSongs.insert(song)
            }
        }) {
            HStack(spacing: 12) {
                Image(systemName: selectedSongs.contains(song) ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundColor(selectedSongs.contains(song) ? .green : .gray)
                
                songIcon(for: song)
                songTitle(for: song)
                Spacer()
            }
            .padding(.vertical, 4)
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
        .listRowBackground(rowBackground(for: song))
    }
    
    @ViewBuilder
    private func normalModeRow(for song: String) -> some View {
        NavigationLink(destination: PlayerView(folderName: folderName, initialSongName: song, audioManager: audioManager)) {
            HStack {
                songIcon(for: song)
                songTitle(for: song)
            }
            .padding(.vertical, 4)
        }
        .listRowBackground(rowBackground(for: song))
    }
    
    @ViewBuilder
    private func songIcon(for song: String) -> some View {
        let isCurrent = isCurrentSong(song)
        let iconName = isCurrent ? "music.note" : "music.note.list"
        
        Image(systemName: iconName)
            .font(.title3)
            .foregroundStyle(isCurrent ? currentSongGradient : inactiveSongGradient)
    }
    
    @ViewBuilder
    private func songTitle(for song: String) -> some View {
        let isCurrent = isCurrentSong(song)
        
        Text(song)
            .foregroundColor(isCurrent ? .cyan : .primary)
            .font(isCurrent ? .headline : .body)
    }
    
    @ViewBuilder
    private func rowBackground(for song: String) -> some View {
        let isCurrent = isCurrentSong(song)
        
        RoundedRectangle(cornerRadius: 10)
            .fill(isCurrent ? Color.cyan.opacity(0.2) : Color.white.opacity(0.15))
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(isCurrent ? currentSongStroke : inactiveStroke, lineWidth: isCurrent ? 2 : 1)
            )
            .padding(.vertical, 2)
    }
    
    private var currentSongGradient: LinearGradient {
        LinearGradient(
            gradient: Gradient(colors: [Color.cyan, Color.blue]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    private var inactiveSongGradient: LinearGradient {
        LinearGradient(
            gradient: Gradient(colors: [Color.gray.opacity(0.6), Color.gray.opacity(0.4)]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    private var currentSongStroke: LinearGradient {
        LinearGradient(
            gradient: Gradient(colors: [Color.cyan.opacity(0.6), Color.blue.opacity(0.3)]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    private var inactiveStroke: LinearGradient {
        LinearGradient(
            gradient: Gradient(colors: [Color.white.opacity(0.3), Color.clear]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

// MARK: - Move To Folder View
struct MoveToFolderView: View {
    let currentFolder: String
    let songsToMove: [String]
    let onComplete: () -> Void
    
    @State private var folders: [String] = []
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            ZStack {
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color(red: 0.2, green: 0.3, blue: 0.5),
                        Color(red: 0.35, green: 0.25, blue: 0.6),
                        Color(red: 0.3, green: 0.4, blue: 0.65)
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                List {
                    Section(header: Text("Select Destination Folder").foregroundColor(.white.opacity(0.8))) {
                        ForEach(folders.filter { $0 != currentFolder }, id: \.self) { folder in
                            Button(action: {
                                moveSongs(to: folder)
                            }) {
                                HStack {
                                    Image(systemName: "folder.fill")
                                        .font(.title3)
                                        .foregroundColor(.cyan)
                                    Text(folder)
                                        .foregroundColor(.white)
                                        .font(.body)
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .font(.caption)
                                        .foregroundColor(.white.opacity(0.5))
                                }
                                .padding(.vertical, 8)
                            }
                            .listRowBackground(
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(Color.white.opacity(0.15))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 10)
                                            .stroke(
                                                LinearGradient(
                                                    gradient: Gradient(colors: [Color.white.opacity(0.3), Color.clear]),
                                                    startPoint: .topLeading,
                                                    endPoint: .bottomTrailing
                                                ),
                                                lineWidth: 1
                                            )
                                    )
                                    .padding(.vertical, 2)
                            )
                        }
                    }
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Move \(songsToMove.count) Song(s)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.white)
                }
            }
        }
        .onAppear {
            loadFolders()
        }
    }
    
    private func loadFolders() {
        folders = FileManagerHelper.shared.getFolders()
    }
    
    private func moveSongs(to targetFolder: String) {
        let fileManager = FileManager.default
        let sourceFolderPath = FileManagerHelper.shared.getFolderPath(currentFolder)
        let targetFolderPath = FileManagerHelper.shared.getFolderPath(targetFolder)
        
        var movedCount = 0
        for song in songsToMove {
            let sourceURL = URL(fileURLWithPath: "\(sourceFolderPath)/\(song)")
            let targetURL = URL(fileURLWithPath: "\(targetFolderPath)/\(song)")
            
            do {
                // If file exists at destination, remove it first
                if fileManager.fileExists(atPath: targetURL.path) {
                    try fileManager.removeItem(at: targetURL)
                }
                try fileManager.moveItem(at: sourceURL, to: targetURL)
                movedCount += 1
                print("Moved: \(song) to \(targetFolder)")
            } catch {
                print("Failed to move \(song): \(error)")
            }
        }
        
        print("Successfully moved \(movedCount) of \(songsToMove.count) songs")
        
        dismiss()
        onComplete()
    }
}



