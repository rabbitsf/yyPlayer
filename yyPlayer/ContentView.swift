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
                
                // Decorative background elements
                GeometryReader { geo in
                    decorativeIcons(geo: geo)
                    decorativeDots(geo: geo)
                }
                
                GeometryReader { geometry in
                    ZStack {
                        // Decorative frame
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        Color.white.opacity(0.3),
                                        Color.white.opacity(0.1),
                                        Color.white.opacity(0.2)
                                    ]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 2
                            )
                            .padding(12)
                        
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
                                
                                // My Media Library title
                                Text("My Media Library")
                                    .font(.system(size: 22, weight: .bold))
                                    .foregroundColor(.white)
                            }
                            .padding(.bottom, 16)
                            
                            // Action Buttons - All in one row
                            HStack(spacing: 8) {
                                // Add Button - Green
                                Button(action: {
                                    showAlert = true
                                }) {
                                    VStack(spacing: 4) {
                                        Image(systemName: "folder.badge.plus")
                                            .font(.system(size: 20))
                                            .foregroundColor(.white)
                                        Text("Add")
                                            .font(.system(size: 12, weight: .semibold))
                                            .foregroundColor(.white)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 10)
                                    .background(Color.green)
                                    .cornerRadius(10)
                                }
                                
                                // Refresh Button - Orange
                                Button(action: {
                                    loadFolders()
                                }) {
                                    VStack(spacing: 4) {
                                        Image(systemName: "arrow.clockwise")
                                            .font(.system(size: 20))
                                            .foregroundColor(.white)
                                        Text("Refresh")
                                            .font(.system(size: 12, weight: .semibold))
                                            .foregroundColor(.white)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 10)
                                    .background(Color.orange)
                                    .cornerRadius(10)
                                }
                                
                                // Import Button - Red
                                NavigationLink(destination: AirDropImportView()) {
                                    VStack(spacing: 4) {
                                        Image(systemName: "square.and.arrow.down")
                                            .font(.system(size: 20))
                                            .foregroundColor(.white)
                                        Text("Import")
                                            .font(.system(size: 12, weight: .semibold))
                                            .foregroundColor(.white)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 10)
                                    .background(Color.red)
                                    .cornerRadius(10)
                                }
                                
                                // Upload Button - Purple
                                NavigationLink(destination: UploadView()) {
                                    VStack(spacing: 4) {
                                        Image(systemName: "arrow.up.circle.fill")
                                            .font(.system(size: 20))
                                            .foregroundColor(.white)
                                        Text("Upload")
                                            .font(.system(size: 12, weight: .semibold))
                                            .foregroundColor(.white)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 10)
                                    .background(
                                        LinearGradient(
                                            gradient: Gradient(colors: [Color.purple, Color.indigo]),
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .cornerRadius(10)
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
                                    HStack(spacing: 12) {
                                        Image(systemName: "folder.fill")
                                            .font(.title2)
                                            .foregroundColor(.white)
                                        Text(folder)
                                            .font(.headline)
                                            .foregroundColor(.white)
                                        Spacer()
                                        Image(systemName: "music.note")
                                            .font(.system(size: 16))
                                            .foregroundColor(.white.opacity(0.7))
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
                        .clipShape(RoundedRectangle(cornerRadius: 18))
                        }
                        .padding(14)
                    }
                }
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .principal) {
                        Text("Media Player")
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
    
    // MARK: - Decorative Elements
    @ViewBuilder
    private func decorativeIcons(geo: GeometryProxy) -> some View {
        Group {
            Image(systemName: "music.note")
                .font(.system(size: 40))
                .foregroundColor(.white.opacity(0.15))
                .position(x: geo.size.width * 0.15, y: geo.size.height * 0.12)
            
            Image(systemName: "guitars")
                .font(.system(size: 35))
                .foregroundColor(.white.opacity(0.12))
                .position(x: geo.size.width * 0.85, y: geo.size.height * 0.15)
        }
        
        Group {
            Image(systemName: "music.note.list")
                .font(.system(size: 30))
                .foregroundColor(.white.opacity(0.1))
                .position(x: geo.size.width * 0.1, y: geo.size.height * 0.45)
            
            Image(systemName: "pianokeys")
                .font(.system(size: 35))
                .foregroundColor(.white.opacity(0.12))
                .position(x: geo.size.width * 0.9, y: geo.size.height * 0.5)
        }
        
        Group {
            Image(systemName: "mic.fill")
                .font(.system(size: 28))
                .foregroundColor(.white.opacity(0.1))
                .position(x: geo.size.width * 0.12, y: geo.size.height * 0.75)
            
            Image(systemName: "music.quarternote.3")
                .font(.system(size: 32))
                .foregroundColor(.white.opacity(0.13))
                .position(x: geo.size.width * 0.88, y: geo.size.height * 0.8)
        }
    }
    
    @ViewBuilder
    private func decorativeDots(geo: GeometryProxy) -> some View {
        Circle()
            .fill(Color.white.opacity(0.08))
            .frame(width: 8, height: 8)
            .position(x: geo.size.width * 0.25, y: geo.size.height * 0.2)
        
        Circle()
            .fill(Color.white.opacity(0.06))
            .frame(width: 6, height: 6)
            .position(x: geo.size.width * 0.75, y: geo.size.height * 0.35)
        
        Circle()
            .fill(Color.white.opacity(0.07))
            .frame(width: 7, height: 7)
            .position(x: geo.size.width * 0.2, y: geo.size.height * 0.6)
        
        Circle()
            .fill(Color.white.opacity(0.08))
            .frame(width: 8, height: 8)
            .position(x: geo.size.width * 0.8, y: geo.size.height * 0.65)
    }
}

