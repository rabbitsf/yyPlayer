import Foundation
import Network
import Combine

class SimpleUploadServer: ObservableObject {
    static let shared = SimpleUploadServer()
    
    @Published var isServerRunning = false
    @Published var uploadStatus: [String: String] = [:]
    
    private var listener: NWListener?
    private let port: UInt16 = 8080
    
    private init() {}
    
    func startServer() {
        guard !isServerRunning else { return }
        
        do {
            let parameters = NWParameters.tcp
            parameters.allowLocalEndpointReuse = true
            
            listener = try NWListener(using: parameters, on: NWEndpoint.Port(rawValue: port)!)
            
            listener?.newConnectionHandler = { [weak self] connection in
                self?.handleConnection(connection)
            }
            
            listener?.stateUpdateHandler = { [weak self] state in
                DispatchQueue.main.async {
                    switch state {
                    case .ready:
                        self?.isServerRunning = true
                        print("Simple upload server started on port \(self?.port ?? 8080)")
                    case .failed(let error):
                        print("Server failed: \(error)")
                        self?.isServerRunning = false
                    case .cancelled:
                        self?.isServerRunning = false
                    default:
                        break
                    }
                }
            }
            
            listener?.start(queue: .global(qos: .userInitiated))
        } catch {
            print("Failed to start server: \(error)")
        }
    }
    
    func stopServer() {
        listener?.cancel()
        listener = nil
        isServerRunning = false
    }
    
    private var connectionBuffers: [ObjectIdentifier: Data] = [:]
    
    private func handleConnection(_ connection: NWConnection) {
        let connectionId = ObjectIdentifier(connection)
        connectionBuffers[connectionId] = Data()
        
        connection.stateUpdateHandler = { [weak self] state in
            switch state {
            case .ready:
                self?.receiveRequest(on: connection)
            case .failed, .cancelled:
                self?.connectionBuffers.removeValue(forKey: connectionId)
            default:
                break
            }
        }
        
        connection.start(queue: .global(qos: .userInitiated))
    }
    
    private func receiveRequest(on connection: NWConnection) {
        let connectionId = ObjectIdentifier(connection)
        connection.receive(minimumIncompleteLength: 1, maximumLength: 100 * 1024 * 1024) { [weak self] data, context, isComplete, error in
            guard let self = self else { return }
            
            if let data = data {
                if self.connectionBuffers[connectionId] == nil {
                    self.connectionBuffers[connectionId] = Data()
                }
                self.connectionBuffers[connectionId]?.append(data)
            }
            
            let buffer = self.connectionBuffers[connectionId] ?? Data()
            
            if isComplete || error != nil {
                self.processRequest(data: buffer, connection: connection)
                self.connectionBuffers.removeValue(forKey: connectionId)
            } else {
                self.receiveRequest(on: connection)
            }
        }
    }
    
    private func processRequest(data: Data, connection: NWConnection) {
        guard let requestString = String(data: data.prefix(min(1000, data.count)), encoding: .utf8) else {
            sendResponse(connection: connection, statusCode: 400, body: "Invalid request")
            return
        }
        
        let lines = requestString.components(separatedBy: "\r\n")
        guard let firstLine = lines.first else {
            sendResponse(connection: connection, statusCode: 400, body: "Invalid request")
            return
        }
        
        let parts = firstLine.components(separatedBy: " ")
        guard parts.count >= 2 else {
            sendResponse(connection: connection, statusCode: 400, body: "Invalid request")
            return
        }
        
        let method = parts[0]
        let path = parts[1]
        
        if method == "GET" {
            if path == "/" {
                sendUploadPage(connection: connection)
            } else {
                sendResponse(connection: connection, statusCode: 404, body: "Not Found")
            }
        } else if method == "POST" && path == "/upload" {
            handleUpload(data: data, connection: connection)
        } else {
            sendResponse(connection: connection, statusCode: 405, body: "Method Not Allowed")
        }
    }
    
    private func handleUpload(data: Data, connection: NWConnection) {
        // Simple approach: Look for Content-Disposition headers to extract filename and folder
        guard let requestString = String(data: data.prefix(min(5000, data.count)), encoding: .utf8) else {
            sendResponse(connection: connection, statusCode: 400, body: "Invalid encoding")
            return
        }
        
        // Extract boundary
        var boundary: String?
        for line in requestString.components(separatedBy: "\r\n") {
            if line.lowercased().contains("content-type:") && line.contains("boundary=") {
                let parts = line.components(separatedBy: "boundary=")
                if parts.count > 1 {
                    var b = parts[1].trimmingCharacters(in: .whitespacesAndNewlines)
                    if b.hasPrefix("\"") && b.hasSuffix("\"") {
                        b = String(b.dropFirst().dropLast())
                    }
                    if b.hasSuffix(";") {
                        b = String(b.dropLast())
                    }
                    boundary = "--" + b
                    break
                }
            }
        }
        
        guard let boundary = boundary else {
            sendResponse(connection: connection, statusCode: 400, body: "No boundary found")
            return
        }
        
        // Find body start in Data directly
        let doubleCRLF = "\r\n\r\n".data(using: .utf8)!
        guard let bodyStartRange = data.range(of: doubleCRLF) else {
            sendResponse(connection: connection, statusCode: 400, body: "No body found")
            return
        }
        
        let bodyData = data[bodyStartRange.upperBound...]
        
        // Parse using boundary
        let boundaryData = boundary.data(using: .utf8)!
        let parts = splitByBoundary(data: bodyData, boundary: boundaryData)
        
        var folder: String?
        var files: [(name: String, data: Data)] = []
        
        for part in parts {
            if let (name, value) = extractFormField(part) {
                if name == "folder" {
                    folder = value
                }
            } else if let (filename, fileData) = extractFile(part) {
                files.append((filename, fileData))
            }
        }
        
        guard let targetFolder = folder else {
            sendResponse(connection: connection, statusCode: 400, body: "No folder specified")
            return
        }
        
        var uploaded = 0
        for (filename, fileData) in files {
            let lowercased = filename.lowercased()
            // Only accept supported audio formats
            if !(lowercased.hasSuffix(".mp3") || lowercased.hasSuffix(".m4a")) {
                continue
            }
            
            let folderPath = FileManagerHelper.shared.getFolderPath(targetFolder)
            let filePath = "\(folderPath)/\(filename)"
            
            let fileManager = FileManager.default
            if !fileManager.fileExists(atPath: folderPath) {
                try? fileManager.createDirectory(atPath: folderPath, withIntermediateDirectories: true, attributes: nil)
            }
            
            do {
                try fileData.write(to: URL(fileURLWithPath: filePath))
                uploaded += 1
                DispatchQueue.main.async {
                    self.uploadStatus[filename] = "Uploaded"
                }
            } catch {
                print("Failed to save \(filename): \(error)")
            }
        }
        
        sendResponse(connection: connection, statusCode: 200, body: "\(uploaded) file(s) uploaded")
    }
    
    private func splitByBoundary(data: Data, boundary: Data) -> [Data] {
        var parts: [Data] = []
        var start = data.startIndex
        
        while let range = data.range(of: boundary, options: [], in: start..<data.endIndex) {
            if start < range.lowerBound {
                parts.append(data[start..<range.lowerBound])
            }
            start = range.upperBound
        }
        
        if start < data.endIndex {
            parts.append(data[start...])
        }
        
        return parts
    }
    
    private func extractFormField(_ data: Data) -> (String, String)? {
        let doubleCRLF = "\r\n\r\n".data(using: .utf8)!
        guard let headerEnd = data.range(of: doubleCRLF),
              let headers = String(data: data[..<headerEnd.lowerBound], encoding: .utf8) else {
            return nil
        }
        
        if headers.contains("name=\"folder\"") && !headers.contains("filename=") {
            let body = data[headerEnd.upperBound...]
            let cleanBody = body.suffix(2) == "\r\n".data(using: .utf8) ? body.dropLast(2) : body
            if let value = String(data: cleanBody, encoding: .utf8) {
                return ("folder", value.trimmingCharacters(in: .whitespacesAndNewlines))
            }
        }
        
        return nil
    }
    
    private func extractFile(_ data: Data) -> (String, Data)? {
        let doubleCRLF = "\r\n\r\n".data(using: .utf8)!
        guard let headerEnd = data.range(of: doubleCRLF),
              let headers = String(data: data[..<headerEnd.lowerBound], encoding: .utf8) else {
            return nil
        }
        
        guard headers.contains("filename=") else { return nil }
        
        var filename: String?
        if let filenameRange = headers.range(of: "filename=\"") {
            let after = String(headers[filenameRange.upperBound...])
            if let endRange = after.range(of: "\"") {
                filename = String(after[..<endRange.lowerBound])
            }
        }
        
        guard let filename = filename else { return nil }
        
        var fileData = data[headerEnd.upperBound...]
        
        // Remove trailing \r\n
        if fileData.count >= 2 && fileData.suffix(2) == "\r\n".data(using: .utf8) {
            fileData = fileData.dropLast(2)
        }
        
        return (filename, fileData)
    }
    
    private func sendUploadPage(connection: NWConnection) {
        let folders = FileManagerHelper.shared.getFolders()
        let foldersOptions = folders.map { "<option value=\"\($0)\">\($0)</option>" }.joined()
        
        let html = """
        <!DOCTYPE html>
        <html>
        <head><title>Upload Music Files</title>
        <style>
        body { font-family: Arial; max-width: 600px; margin: 50px auto; padding: 20px; }
        input, select, button { padding: 10px; margin: 10px 0; width: 100%; }
        button { background: #007AFF; color: white; border: none; cursor: pointer; }
        </style>
        </head>
        <body>
        <h1>Upload Music Files (MP3/M4A)</h1>
        <form id="uploadForm" enctype="multipart/form-data">
        <select name="folder" required>
        <option value="">Select folder</option>
        \(foldersOptions)
        </select>
        <input type="file" name="file" accept=".mp3,.m4a" multiple required>
        <button type="submit">Upload</button>
        </form>
        <div id="status"></div>
        <script>
        document.getElementById('uploadForm').onsubmit = function(e) {
        e.preventDefault();
        const formData = new FormData(this);
        const files = formData.getAll('file');
        const folder = formData.get('folder');
        const status = document.getElementById('status');
        status.innerHTML = 'Uploading...';
        
        files.forEach(file => {
        const fd = new FormData();
        fd.append('file', file);
        fd.append('folder', folder);
        fetch('/upload', { method: 'POST', body: fd })
        .then(r => r.text())
        .then(t => status.innerHTML += '<br>' + file.name + ': ' + t)
        .catch(e => status.innerHTML += '<br>Error: ' + e);
        });
        };
        </script>
        </body>
        </html>
        """
        
        sendResponse(connection: connection, statusCode: 200, body: html, contentType: "text/html")
    }
    
    private func sendResponse(connection: NWConnection, statusCode: Int, body: String, contentType: String = "text/plain") {
        let response = "HTTP/1.1 \(statusCode) \(statusCode == 200 ? "OK" : "Error")\r\n" +
                      "Content-Type: \(contentType)\r\n" +
                      "Content-Length: \(body.utf8.count)\r\n" +
                      "Access-Control-Allow-Origin: *\r\n\r\n" +
                      body
        
        guard let responseData = response.data(using: .utf8) else { return }
        
        connection.send(content: responseData, completion: .contentProcessed { error in
            if let error = error {
                print("Send error: \(error)")
            }
            connection.cancel()
        })
    }
}

