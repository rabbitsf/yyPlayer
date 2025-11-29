import Foundation

class FileManagerHelper {
    static let shared = FileManagerHelper()
    private let fileManager = FileManager.default
    private let basePath: String

    init() {
        basePath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first ?? ""
    }

    func getFolders() -> [String] {
        do {
            let contents = try fileManager.contentsOfDirectory(atPath: basePath)
            return contents.filter { isFolder(at: $0) }
        } catch {
            print("Failed to get folders: \(error)")
            return []
        }
    }

    func createFolder(name: String) throws {
        let folderPath = "\(basePath)/\(name)"
        if !fileManager.fileExists(atPath: folderPath) {
            try fileManager.createDirectory(atPath: folderPath, withIntermediateDirectories: true, attributes: nil)
        } else {
            throw NSError(domain: "Folder already exists", code: 1, userInfo: nil)
        }
    }

    func getSongs(in folder: String) -> [String] {
        let folderPath = getFolderPath(folder)
        do {
            let contents = try fileManager.contentsOfDirectory(atPath: folderPath)
            // Support multiple audio formats (e.g. .mp3, .m4a)
            let supportedExtensions: Set<String> = ["mp3", "m4a"]
            return contents.filter { fileName in
                let ext = (fileName as NSString).pathExtension.lowercased()
                return supportedExtensions.contains(ext)
            }
        } catch {
            print("Failed to get songs in folder \(folder): \(error)")
            return []
        }
    }

    func getFolderPath(_ folder: String) -> String {
        return "\(basePath)/\(folder)"
    }

    func deleteFolder(_ folder: String) throws {
        let folderPath = getFolderPath(folder)
        try fileManager.removeItem(atPath: folderPath) // Deletes the folder and its contents
    }

    func deleteSong(_ song: String, in folder: String) throws {
        let songPath = "\(getFolderPath(folder))/\(song)"
        try fileManager.removeItem(atPath: songPath) // Deletes the specific song
    }

    private func isFolder(at path: String) -> Bool {
        var isDir: ObjCBool = false
        fileManager.fileExists(atPath: "\(basePath)/\(path)", isDirectory: &isDir)
        return isDir.boolValue
    }
}

