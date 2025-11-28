import SwiftUI

struct ContentView: View {
    @State private var folders: [String] = []
    @StateObject private var audioManager = AudioManager()
    @State private var showAlert = false // Show alert for adding a folder
    @State private var newFolderName = ""

    var body: some View {
        NavigationView {
            ZStack {
                // Vertical gradient from purple to blue (stronger colors)
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color(red: 0.6, green: 0.3, blue: 0.8),   // Stronger purple
                        Color(red: 0.3, green: 0.5, blue: 0.9)     // Stronger blue
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                GeometryReader { geometry in
                    VStack(spacing: 0) {
                        // Top Section - 1/3 of screen
                        VStack(spacing: 0) {
                            // Header Section with Music Icon and Title
                            VStack(spacing: 12) {
                                // Music icon with decorative elements
                                ZStack {
                                    // Decorative smaller music notes around the main icon
                                    HStack(spacing: 50) {
                                        Image(systemName: "music.note")
                                            .font(.system(size: 30))
                                            .foregroundStyle(
                                                LinearGradient(
                                                    gradient: Gradient(colors: [Color.cyan, Color.blue]),
                                                    startPoint: .topLeading,
                                                    endPoint: .bottomTrailing
                                                )
                                            )
                                            .opacity(0.7)
                                        
                                        Image(systemName: "music.note")
                                            .font(.system(size: 30))
                                            .foregroundStyle(
                                                LinearGradient(
                                                    gradient: Gradient(colors: [Color.pink, Color.purple]),
                                                    startPoint: .topLeading,
                                                    endPoint: .bottomTrailing
                                                )
                                            )
                                            .opacity(0.7)
                                    }
                                    
                                    // Main large music note icon with gradient
                                    Image(systemName: "music.note")
                                        .font(.system(size: 80))
                                        .foregroundStyle(
                                            LinearGradient(
                                                gradient: Gradient(colors: [Color.yellow, Color.orange, Color.pink]),
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            )
                                        )
                                        .shadow(color: Color.orange.opacity(0.5), radius: 10, x: 0, y: 5)
                                }
                                .padding(.vertical, 10)
                                
                                // My Music Library title
                                Text("My Music Library")
                                    .font(.system(size: 22, weight: .bold))
                                    .foregroundColor(.white)
                            }
                            .padding(.bottom, 16)
                            
                            // Action Buttons - Vertical layout (icon on top, text below)
                            HStack(spacing: 12) {
                                // Add Button - Green
                                Button(action: {
                                    showAlert = true
                                }) {
                                    VStack(spacing: 6) {
                                        Image(systemName: "folder.badge.plus")
                                            .font(.system(size: 24))
                                            .foregroundColor(.white)
                                        Text("Add")
                                            .font(.system(size: 14, weight: .semibold))
                                            .foregroundColor(.white)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 12)
                                    .background(Color.green)
                                    .cornerRadius(12)
                                }
                                
                                // Refresh Button - Orange
                                Button(action: {
                                    loadFolders()
                                }) {
                                    VStack(spacing: 6) {
                                        Image(systemName: "arrow.clockwise")
                                            .font(.system(size: 24))
                                            .foregroundColor(.white)
                                        Text("Refresh")
                                            .font(.system(size: 14, weight: .semibold))
                                            .foregroundColor(.white)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 12)
                                    .background(Color.orange)
                                    .cornerRadius(12)
                                }
                                
                                // Import Button - Red
                                NavigationLink(destination: AirDropImportView()) {
                                    VStack(spacing: 6) {
                                        Image(systemName: "square.and.arrow.down")
                                            .font(.system(size: 24))
                                            .foregroundColor(.white)
                                        Text("Import")
                                            .font(.system(size: 14, weight: .semibold))
                                            .foregroundColor(.white)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 12)
                                    .background(Color.red)
                                    .cornerRadius(12)
                                }
                            }
                            .padding(.horizontal, 20)
                            .padding(.bottom, 16)
                        }
                        .frame(height: geometry.size.height / 3)
                        
                        // Folder List with Swipe-to-Delete - 2/3 of screen
                        List {
                            ForEach(folders, id: \.self) { folder in
                                NavigationLink(destination: FolderView(folderName: folder, audioManager: audioManager)) {
                                    HStack {
                                        Image(systemName: "folder.fill")
                                            .font(.title2)
                                            .foregroundColor(.white)
                                        Text(folder)
                                            .font(.headline)
                                            .foregroundColor(.white)
                                        Spacer()
                                    }
                                    .padding(.vertical, 8)
                                }
                                .listRowBackground(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(.ultraThinMaterial)
                                        .padding(.vertical, 4)
                                )
                            }
                            .onDelete(perform: deleteFolder)
                        }
                        .scrollContentBackground(.hidden)
                    }
                }
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .principal) {
                        Text("Song Folders")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.white)
                    }
                }
                .toolbarBackground(.hidden, for: .navigationBar)
            }
            .onAppear {
                loadFolders()
            }
            .textAlert(
                isPresented: $showAlert,
                title: "New Folder",
                placeholder: "Folder Name",
                text: $newFolderName
            ) { folderName in
                if let name = folderName, !name.isEmpty {
                    addNewFolder(name: name)
                }
            }
        }
    }

    private func loadFolders() {
        folders = FileManagerHelper.shared.getFolders()
    }

    private func addNewFolder(name: String) {
        do {
            try FileManagerHelper.shared.createFolder(name: name)
            loadFolders() // Reload folder list
        } catch {
            print("Failed to create folder: \(error)")
        }
    }

    private func deleteFolder(at offsets: IndexSet) {
        for index in offsets {
            let folder = folders[index]
            do {
                try FileManagerHelper.shared.deleteFolder(folder)
                folders.remove(at: index) // Remove from the list
            } catch {
                print("Failed to delete folder: \(error)")
            }
        }
    }
}

