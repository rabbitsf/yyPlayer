import SwiftUI

struct FolderView: View {
    let folderName: String
    @ObservedObject var audioManager: AudioManager
    @State private var songs: [String] = []

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
            
            List {
                ForEach(songs, id: \.self) { song in
                    NavigationLink(destination: PlayerView(folderName: folderName, initialSongName: song, audioManager: audioManager)) {
                        HStack {
                            Image(systemName: audioManager.currentSongTitle == song ? "music.note" : "music.note.list")
                                .font(.title3)
                                .foregroundStyle(
                                    audioManager.currentSongTitle == song ?
                                    LinearGradient(
                                        gradient: Gradient(colors: [Color.cyan, Color.blue]),
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ) :
                                    LinearGradient(
                                        gradient: Gradient(colors: [Color.gray.opacity(0.6), Color.gray.opacity(0.4)]),
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                            Text(song)
                                .foregroundColor(audioManager.currentSongTitle == song ? .cyan : .primary)
                                .font(audioManager.currentSongTitle == song ? .headline : .body)
                        }
                        .padding(.vertical, 4)
                    }
                    .listRowBackground(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(audioManager.currentSongTitle == song ? 
                                  Color.cyan.opacity(0.2) : 
                                  Color.white.opacity(0.15))
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(
                                        audioManager.currentSongTitle == song ?
                                        LinearGradient(
                                            gradient: Gradient(colors: [Color.cyan.opacity(0.6), Color.blue.opacity(0.3)]),
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        ) :
                                        LinearGradient(
                                            gradient: Gradient(colors: [Color.white.opacity(0.3), Color.clear]),
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        ),
                                        lineWidth: audioManager.currentSongTitle == song ? 2 : 1
                                    )
                            )
                            .padding(.vertical, 2)
                    )
                }
                .onDelete(perform: deleteSong)
            }
            .scrollContentBackground(.hidden)
            .navigationTitle(folderName)
            .navigationBarTitleDisplayMode(.large)
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
}

