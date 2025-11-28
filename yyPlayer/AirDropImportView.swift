import SwiftUI
import UniformTypeIdentifiers

struct AirDropImportView: View {
    @State private var showDocumentPicker = false
    @State private var selectedFolder: String? = nil
    @State private var folders: [String] = []
    @State private var showFolderPicker = false
    @State private var showSuccessAlert = false
    @State private var importMessage = ""
    
    var body: some View {
        ZStack {
            // Gradient background: blue at top to purple at bottom
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 0.3, green: 0.5, blue: 0.9),  // Blue
                    Color(red: 0.6, green: 0.3, blue: 0.8)    // Purple
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            VStack(spacing: 30) {
                // Large circular light blue button with white download icon
                Button(action: {}) {
                    Image(systemName: "square.and.arrow.down")
                        .font(.system(size: 50))
                        .foregroundColor(.white)
                        .frame(width: 100, height: 100)
                        .background(Color(red: 0.5, green: 0.7, blue: 1.0)) // Light blue
                        .clipShape(Circle())
                }
                .disabled(true)
                .padding(.top, 20)
                
                // Main title
                Text("Import MP3 Files")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.black)
                
                // Subtitle
                Text("Import MP3 files from Files app")
                    .font(.system(size: 16))
                    .foregroundColor(.black.opacity(0.7))
                    .multilineTextAlignment(.center)
                
                // Folder Selection Section
                VStack(alignment: .leading, spacing: 12) {
                    Text("Select Folder")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    // Select or Create Folder Button - Bright Green
                    Button(action: {
                        showFolderPicker = true
                    }) {
                        HStack {
                            Image(systemName: "folder.badge.plus")
                                .font(.system(size: 20))
                                .foregroundColor(.white)
                            Text("Select or Create Folder")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.white)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.green)
                        .cornerRadius(12)
                    }
                    
                    // Import MP3 Files Button - Gray (disabled when no folder)
                    Button(action: {
                        showDocumentPicker = true
                    }) {
                        HStack {
                            Image(systemName: "square.and.arrow.down")
                                .font(.system(size: 20))
                                .foregroundColor(.white)
                            Text("Import MP3 Files")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.white)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(selectedFolder != nil ? Color.green : Color.gray)
                        .cornerRadius(12)
                    }
                    .disabled(selectedFolder == nil)
                }
                .padding(.horizontal, 20)
                
                Spacer()
            }
            .padding(.top, 20)
        }
        .navigationTitle("Import Files")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("Import Files")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.black)
            }
        }
        .toolbarBackground(.hidden, for: .navigationBar)
        .onAppear {
            loadFolders()
        }
        .sheet(isPresented: $showFolderPicker) {
            FolderPickerView(selectedFolder: $selectedFolder, onFoldersChanged: {
                loadFolders()
            })
        }
        .sheet(isPresented: $showDocumentPicker) {
            if let folder = selectedFolder {
                DocumentPickerView(folder: folder, onImportComplete: { message in
                    print("Import complete callback called with message: \(message)")
                    importMessage = message
                    // Delay showing alert until sheet is fully dismissed
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        print("Showing alert now")
                        showSuccessAlert = true
                    }
                })
            }
        }
        .onChange(of: showDocumentPicker) { isShowing in
            if isShowing {
                // Clear previous message when starting a new import
                importMessage = ""
                showSuccessAlert = false
            } else {
                // If sheet was dismissed and we have a message, show alert
                if !importMessage.isEmpty {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        showSuccessAlert = true
                    }
                }
            }
        }
        .alert("Import Complete", isPresented: $showSuccessAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(importMessage)
        }
    }
    
    private func loadFolders() {
        folders = FileManagerHelper.shared.getFolders()
    }
}

struct FolderPickerView: View {
    @Binding var selectedFolder: String?
    let onFoldersChanged: () -> Void
    @State private var folders: [String] = []
    @State private var showCreateFolder = false
    @State private var newFolderName = ""
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            ZStack {
                // Beautiful gradient background
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color(red: 0.2, green: 0.25, blue: 0.45),
                        Color(red: 0.35, green: 0.2, blue: 0.55),
                        Color(red: 0.3, green: 0.35, blue: 0.6)
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                List {
                    if folders.isEmpty {
                        Section {
                            Text("No folders yet. Create one to get started.")
                                .foregroundColor(.white.opacity(0.8))
                                .font(.caption)
                        }
                    } else {
                        Section("Existing Folders") {
                            ForEach(folders, id: \.self) { folder in
                                Button(action: {
                                    selectedFolder = folder
                                    dismiss()
                                }) {
                                    HStack {
                                        Image(systemName: "folder.fill")
                                            .font(.title2)
                                            .foregroundColor(.white)
                                        Text(folder)
                                            .foregroundColor(.white)
                                        Spacer()
                                        if selectedFolder == folder {
                                            Image(systemName: "checkmark.circle.fill")
                                                .foregroundStyle(
                                                    LinearGradient(
                                                        gradient: Gradient(colors: [Color.green, Color.cyan]),
                                                        startPoint: .topLeading,
                                                        endPoint: .bottomTrailing
                                                    )
                                                )
                                        }
                                    }
                                    .padding(.vertical, 4)
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
                    
                    Section {
                        Button(action: {
                            showCreateFolder = true
                        }) {
                            HStack {
                                Image(systemName: "folder.badge.plus")
                                    .font(.title3)
                                    .foregroundStyle(
                                        LinearGradient(
                                            gradient: Gradient(colors: [Color.purple, Color.blue]),
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                Text("Create New Folder")
                                    .foregroundColor(.white)
                            }
                            .padding(.vertical, 4)
                        }
                        .listRowBackground(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(
                                    LinearGradient(
                                        gradient: Gradient(colors: [Color.purple.opacity(0.3), Color.blue.opacity(0.2)]),
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(
                                            LinearGradient(
                                                gradient: Gradient(colors: [Color.purple.opacity(0.6), Color.blue.opacity(0.4)]),
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
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Select Folder")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.white)
                }
            }
            .onAppear {
                loadFolders()
            }
            .textAlert(
                isPresented: $showCreateFolder,
                title: "New Folder",
                placeholder: "Folder Name",
                text: $newFolderName
            ) { folderName in
                if let name = folderName, !name.isEmpty {
                    do {
                        try FileManagerHelper.shared.createFolder(name: name)
                        selectedFolder = name
                        loadFolders() // Reload folders after creating
                        onFoldersChanged()
                        dismiss()
                    } catch {
                        print("Failed to create folder: \(error)")
                    }
                }
            }
        }
    }
    
    private func loadFolders() {
        folders = FileManagerHelper.shared.getFolders()
    }
}

struct DocumentPickerView: UIViewControllerRepresentable {
    let folder: String
    let onImportComplete: (String) -> Void
    @Environment(\.dismiss) var dismiss
    
    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: [.mp3, .audio], asCopy: true)
        picker.delegate = context.coordinator
        picker.allowsMultipleSelection = true
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIDocumentPickerDelegate {
        let parent: DocumentPickerView
        
        init(_ parent: DocumentPickerView) {
            self.parent = parent
        }
        
        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            let folderPath = FileManagerHelper.shared.getFolderPath(parent.folder)
            let fileManager = FileManager.default
            
            // Ensure folder exists
            if !fileManager.fileExists(atPath: folderPath) {
                try? fileManager.createDirectory(atPath: folderPath, withIntermediateDirectories: true, attributes: nil)
            }
            
            var copiedCount = 0
            var errors: [String] = []
            
            for url in urls {
                // When using asCopy: true, files are automatically copied to the app's Inbox
                // The URL provided should already point to the Inbox location
                // We need to access it with security-scoped resource access
                
                let needsSecurityAccess = url.startAccessingSecurityScopedResource()
                defer {
                    if needsSecurityAccess {
                        url.stopAccessingSecurityScopedResource()
                    }
                }
                
                // Check if file exists at the provided URL
                guard fileManager.fileExists(atPath: url.path) else {
                    print("File does not exist at path: \(url.path)")
                    print("File name: \(url.lastPathComponent)")
                    errors.append(url.lastPathComponent)
                    continue
                }
                
                // Check if we can read the file
                guard fileManager.isReadableFile(atPath: url.path) else {
                    print("File is not readable: \(url.lastPathComponent)")
                    errors.append(url.lastPathComponent)
                    continue
                }
                
                let destinationURL = URL(fileURLWithPath: "\(folderPath)/\(url.lastPathComponent)")
                
                do {
                    // Remove existing file if it exists
                    if fileManager.fileExists(atPath: destinationURL.path) {
                        try fileManager.removeItem(at: destinationURL)
                    }
                    
                    // Always use moveItem - this moves the file from Inbox to destination
                    // and automatically removes it from the Inbox
                    try fileManager.moveItem(at: url, to: destinationURL)
                    copiedCount += 1
                    print("Successfully imported: \(url.lastPathComponent)")
                    
                    // Verify the file was moved (no longer in Inbox)
                    if !fileManager.fileExists(atPath: url.path) {
                        print("Confirmed: File removed from Inbox")
                    }
                } catch {
                    print("Failed to import \(url.lastPathComponent): \(error.localizedDescription)")
                    errors.append("\(url.lastPathComponent): \(error.localizedDescription)")
                }
            }
            
            // Clean up any remaining files in Inbox after import
            DispatchQueue.global(qos: .utility).async {
                let inboxURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
                    .appendingPathComponent("Inbox")
                
                if fileManager.fileExists(atPath: inboxURL.path) {
                    if let inboxFiles = try? fileManager.contentsOfDirectory(at: inboxURL, includingPropertiesForKeys: nil) {
                        for file in inboxFiles {
                            // Only remove MP3 files that were likely from this import
                            if file.pathExtension.lowercased() == "mp3" {
                                try? fileManager.removeItem(at: file)
                                print("Cleaned up Inbox file: \(file.lastPathComponent)")
                            }
                        }
                    }
                }
            }
            
            var message = ""
            if copiedCount > 0 {
                message = "Successfully imported \(copiedCount) file(s) to folder: \(self.parent.folder)"
                print(message)
            }
            if !errors.isEmpty {
                let errorMsg = "Errors importing \(errors.count) file(s): \(errors.joined(separator: ", "))"
                print(errorMsg)
                if message.isEmpty {
                    message = errorMsg
                } else {
                    message += "\n\n\(errorMsg)"
                }
            }
            
            // Always show a message, even if no files were imported
            if message.isEmpty {
                message = "No files were imported."
            }
            
            // Call the completion handler and dismiss
            DispatchQueue.main.async {
                self.parent.onImportComplete(message)
                // Dismiss the sheet first, then show alert
                self.parent.dismiss()
            }
        }
        
        func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
            parent.dismiss()
        }
    }
}

