import Foundation
import Network
import Combine

class WiFiUploadServer: ObservableObject {
    static let shared = WiFiUploadServer()
    
    @Published var isServerRunning = false
    @Published var uploadStatus: [String: String] = [:]
    
    private var listener: NWListener?
    private let port: UInt16 = 8080
    private var activeConnections: [NWConnection] = []
    
    private init() {}
    
    func startServer() {
        guard !isServerRunning else { return }
        
        do {
            let parameters = NWParameters.tcp
            parameters.allowLocalEndpointReuse = true
            
            listener = try NWListener(using: parameters, on: NWEndpoint.Port(rawValue: port)!)
            
            listener?.newConnectionHandler = { [weak self] connection in
                self?.handleNewConnection(connection)
            }
            
            listener?.stateUpdateHandler = { [weak self] state in
                DispatchQueue.main.async {
                    switch state {
                    case .ready:
                        self?.isServerRunning = true
                        print("✅ WiFi Upload Server started on port \(self?.port ?? 8080)")
                    case .failed(let error):
                        print("❌ Server failed: \(error)")
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
            print("❌ Failed to start server: \(error)")
        }
    }
    
    func stopServer() {
        listener?.cancel()
        activeConnections.forEach { $0.cancel() }
        activeConnections.removeAll()
        isServerRunning = false
        print("🛑 Server stopped")
    }
    
    private func handleNewConnection(_ connection: NWConnection) {
        activeConnections.append(connection)
        print("🔵 New connection from \(connection.endpoint)")
        
        connection.stateUpdateHandler = { [weak self] state in
            switch state {
            case .ready:
                self?.receiveHTTPRequest(on: connection)
            case .failed(let error):
                print("❌ Connection failed: \(error)")
                self?.activeConnections.removeAll { $0 === connection }
            case .cancelled:
                self?.activeConnections.removeAll { $0 === connection }
            default:
                break
            }
        }
        
        connection.start(queue: .global(qos: .userInitiated))
    }
    
    private func receiveHTTPRequest(on connection: NWConnection) {
        var receivedData = Data()
        var expectedContentLength: Int?
        var headerEndIndex: Int?
        var hasProcessed = false
        
        func receiveChunk() {
            connection.receive(minimumIncompleteLength: 1, maximumLength: 65536) { [weak self] data, context, isComplete, error in
                guard let self = self, !hasProcessed else {
                    return
                }
                
                if let error = error {
                    print("⚠️ Receive error: \(error.localizedDescription)")
                    connection.cancel()
                    return
                }
                
                if let data = data, !data.isEmpty {
                    receivedData.append(data)
                    
                    // Parse headers if we haven't yet
                    if headerEndIndex == nil {
                        if let headerEnd = receivedData.range(of: "\r\n\r\n".data(using: .utf8)!) {
                            headerEndIndex = headerEnd.upperBound
                            print("📋 Found header end at position \(headerEndIndex!)")
                            
                            // Extract Content-Length from headers
                            if let headerString = String(data: receivedData[..<headerEnd.lowerBound], encoding: .utf8) {
                                // Check if it's a GET request
                                let firstLine = headerString.components(separatedBy: "\r\n").first ?? ""
                                print("📝 Request line: \(firstLine)")
                                
                                for line in headerString.components(separatedBy: "\r\n") {
                                    if line.lowercased().hasPrefix("content-length:") {
                                        let parts = line.components(separatedBy: ":")
                                        if parts.count > 1, let length = Int(parts[1].trimmingCharacters(in: .whitespaces)) {
                                            expectedContentLength = length
                                            print("📊 Content-Length: \(length) bytes (total expected: \(headerEndIndex! + length))")
                                            break
                                        }
                                    }
                                }
                                
                                // If no Content-Length, check if it's a GET/OPTIONS request
                                if expectedContentLength == nil {
                                    if firstLine.hasPrefix("GET ") || firstLine.hasPrefix("OPTIONS ") {
                                        print("✅ GET/OPTIONS request complete (no body expected)")
                                        hasProcessed = true
                                        self.processHTTPRequest(receivedData, on: connection)
                                        return
                                    }
                                }
                            }
                        }
                    }
                    
                    // Check if we have all the data for POST requests with Content-Length
                    if let headerEnd = headerEndIndex, let contentLength = expectedContentLength {
                        let bodySize = receivedData.count - headerEnd
                        let progress = Int((Double(bodySize) / Double(contentLength)) * 100)
                        
                        if progress % 25 == 0 && bodySize < contentLength {
                            print("📈 Progress: \(progress)% (\(bodySize)/\(contentLength) bytes)")
                        }
                        
                        if bodySize >= contentLength {
                            print("✅ Received complete request: \(receivedData.count) bytes")
                            hasProcessed = true
                            self.processHTTPRequest(receivedData, on: connection)
                            return
                        }
                    }
                }
                
                if isComplete {
                    if receivedData.isEmpty {
                        print("⚠️ Connection closed with no data")
                        connection.cancel()
                        return
                    }
                    print("✅ Connection complete, processing \(receivedData.count) bytes")
                    hasProcessed = true
                    self.processHTTPRequest(receivedData, on: connection)
                } else {
                    // Continue receiving
                    receiveChunk()
                }
            }
        }
        
        receiveChunk()
    }
    
    private func processHTTPRequest(_ data: Data, on connection: NWConnection) {
        // Find header end
        guard let headerEnd = data.range(of: "\r\n\r\n".data(using: .utf8)!),
              let headerString = String(data: data[..<headerEnd.lowerBound], encoding: .utf8) else {
            sendResponse(connection: connection, statusCode: 400, body: "Invalid request")
            return
        }
        
        let lines = headerString.components(separatedBy: "\r\n")
        guard let requestLine = lines.first else {
            sendResponse(connection: connection, statusCode: 400, body: "Invalid request")
            return
        }
        
        let parts = requestLine.components(separatedBy: " ")
        guard parts.count >= 2 else {
            sendResponse(connection: connection, statusCode: 400, body: "Invalid request")
            return
        }
        
        let method = parts[0]
        let path = parts[1]
        
        print("📝 \(method) \(path)")
        
        switch (method, path) {
        case ("GET", "/"):
            sendHTMLResponse(connection: connection)
        case ("POST", "/api/upload"):
            handleUpload(data: data, connection: connection)
        case ("POST", "/api/createFolder"):
            handleCreateFolder(data: data, connection: connection)
        case ("OPTIONS", _):
            sendCORSResponse(connection: connection)
        default:
            sendResponse(connection: connection, statusCode: 404, body: "Not Found")
        }
    }
    
    private func handleUpload(data: Data, connection: NWConnection) {
        print("📤 Processing file upload...")
        
        // Extract boundary
        guard let headerEnd = data.range(of: "\r\n\r\n".data(using: .utf8)!),
              let headerString = String(data: data[..<headerEnd.lowerBound], encoding: .utf8) else {
            sendResponse(connection: connection, statusCode: 400, body: "Invalid headers")
            return
        }
        
        var boundary: String?
        for line in headerString.components(separatedBy: "\r\n") {
            if line.lowercased().contains("content-type:") && line.contains("boundary=") {
                let parts = line.components(separatedBy: "boundary=")
                if parts.count > 1 {
                    var boundaryValue = parts[1].trimmingCharacters(in: .whitespaces).trimmingCharacters(in: CharacterSet(charactersIn: "\""))
                    // Don't add -- if boundary already starts with dashes
                    if !boundaryValue.hasPrefix("--") {
                        boundaryValue = "--" + boundaryValue
                    }
                    boundary = boundaryValue
                }
            }
        }
        
        guard let boundary = boundary else {
            sendResponse(connection: connection, statusCode: 400, body: "No boundary found")
            return
        }
        
        print("🔍 Boundary: \(boundary)")
        
        // Parse multipart data
        let bodyData = data[headerEnd.upperBound...]
        let parts = parseMultipartData(bodyData, boundary: boundary)
        
        var targetFolder: String?
        var files: [(String, Data)] = []
        
        print("🔍 Parsing \(parts.count) multipart parts")
        for (index, part) in parts.enumerated() {
            print("  Part \(index): fieldName=\(part.fieldName ?? "nil"), filename=\(part.filename ?? "nil"), textValue=\(part.textValue ?? "nil"), hasData=\(part.data != nil)")
            
            if part.isFormField, part.fieldName == "folder", let value = part.textValue {
                targetFolder = value
                print("📁 Target folder: \(value)")
            } else if let filename = part.filename, let fileData = part.data {
                files.append((filename, fileData))
                print("📄 Found file: \(filename) (\(fileData.count) bytes)")
            }
        }
        
        guard let folder = targetFolder, !folder.isEmpty else {
            sendResponse(connection: connection, statusCode: 400, body: "No folder specified")
            return
        }
        
        var successCount = 0
        for (filename, fileData) in files {
            let ext = (filename as NSString).pathExtension.lowercased()
            guard ext == "mp3" || ext == "m4a" else {
                print("⚠️ Skipping \(filename) - unsupported format")
                continue
            }
            
            let folderPath = FileManagerHelper.shared.getFolderPath(folder)
            let filePath = (folderPath as NSString).appendingPathComponent(filename)
            
            // Create folder if needed
            try? FileManager.default.createDirectory(atPath: folderPath, withIntermediateDirectories: true)
            
            do {
                try fileData.write(to: URL(fileURLWithPath: filePath))
                successCount += 1
                print("✅ Saved: \(filename)")
                
                DispatchQueue.main.async {
                    self.uploadStatus[filename] = "Uploaded successfully"
                    DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                        self.uploadStatus.removeValue(forKey: filename)
                    }
                }
            } catch {
                print("❌ Failed to save \(filename): \(error)")
            }
        }
        
        let message = "\(successCount) file(s) uploaded successfully"
        print("✅ \(message)")
        sendResponse(connection: connection, statusCode: 200, body: message)
    }
    
    private func handleCreateFolder(data: Data, connection: NWConnection) {
        guard let headerEnd = data.range(of: "\r\n\r\n".data(using: .utf8)!) else {
            sendResponse(connection: connection, statusCode: 400, body: "Invalid request")
            return
        }
        
        let bodyData = data[headerEnd.upperBound...]
        guard let json = try? JSONSerialization.jsonObject(with: bodyData) as? [String: Any],
              let folderName = json["folderName"] as? String, !folderName.isEmpty else {
            sendResponse(connection: connection, statusCode: 400, body: "Invalid request")
            return
        }
        
        do {
            try FileManagerHelper.shared.createFolder(name: folderName)
            print("✅ Created folder: \(folderName)")
            sendResponse(connection: connection, statusCode: 200, body: "Folder created")
        } catch {
            print("❌ Failed to create folder: \(error)")
            sendResponse(connection: connection, statusCode: 500, body: "Error creating folder")
        }
    }
    
    private struct MultipartPart {
        var fieldName: String?
        var filename: String?
        var textValue: String?
        var data: Data?
        
        var isFormField: Bool {
            filename == nil && textValue != nil
        }
    }
    
    private func parseMultipartData(_ data: Data, boundary: String) -> [MultipartPart] {
        print("🔍 parseMultipartData: boundary='\(boundary)', dataSize=\(data.count)")
        var parts: [MultipartPart] = []
        let boundaryData = boundary.data(using: .utf8)!
        let crlfData = "\r\n".data(using: .utf8)!
        
        // Log first 500 bytes to see the structure
        if let preview = String(data: data.prefix(500), encoding: .utf8) {
            print("📄 Data preview:\n\(preview.replacingOccurrences(of: "\r\n", with: "\\r\\n"))")
        }
        
        // Find all boundary positions first
        var boundaryPositions: [Int] = []
        var searchPos = data.startIndex
        while searchPos < data.endIndex {
            if let range = data.range(of: boundaryData, in: searchPos..<data.endIndex) {
                boundaryPositions.append(range.lowerBound)
                searchPos = range.upperBound
            } else {
                break
            }
        }
        
        print("  Found \(boundaryPositions.count) boundaries at positions: \(boundaryPositions)")
        
        // Parse each part between boundaries
        for i in 0..<boundaryPositions.count - 1 {
            let currentBoundary = boundaryPositions[i]
            let nextBoundary = boundaryPositions[i + 1]
            
            // Start after current boundary + \r\n
            var partStart = currentBoundary + boundaryData.count
            if partStart + 2 <= data.endIndex && data[partStart..<partStart + 2] == crlfData {
                partStart += 2
            }
            
            // End at \r\n before next boundary (if it exists)
            var partEnd = nextBoundary
            if partEnd >= 2 && data[partEnd - 2..<partEnd] == crlfData {
                partEnd -= 2
            }
            
            if partStart < partEnd {
                let partData = data[partStart..<partEnd]
                print("  Part \(i): from \(partStart) to \(partEnd) (\(partData.count) bytes)")
                if let part = parseMultipartPart(partData) {
                    parts.append(part)
                    print("    ✅ Parsed part \(i): fieldName=\(part.fieldName ?? "nil"), filename=\(part.filename ?? "nil")")
                }
            }
        }
        
        print("🔍 Total parts parsed: \(parts.count)")
        return parts
    }
    
    private func parseMultipartPart(_ data: Data) -> MultipartPart? {
        guard let headerEnd = data.range(of: "\r\n\r\n".data(using: .utf8)!) else {
            print("      ❌ No header end found in part")
            return nil
        }
        
        let headerData = data[..<headerEnd.lowerBound]
        let bodyData = data[headerEnd.upperBound...]
        
        guard let headerString = String(data: headerData, encoding: .utf8) else {
            print("      ❌ Failed to decode headers as UTF-8")
            return nil
        }
        
        print("      Part headers: \(headerString.replacingOccurrences(of: "\r\n", with: " | "))")
        
        var part = MultipartPart()
        
        // Parse headers
        for line in headerString.components(separatedBy: "\r\n") {
            if line.lowercased().contains("content-disposition:") {
                // Extract name
                if let nameRange = line.range(of: "name=\"") {
                    let afterName = line[nameRange.upperBound...]
                    if let endQuote = afterName.firstIndex(of: "\"") {
                        part.fieldName = String(afterName[..<endQuote])
                        print("      Found fieldName: \(part.fieldName!)")
                    }
                }
                
                // Extract filename
                if let filenameRange = line.range(of: "filename=\"") {
                    let afterFilename = line[filenameRange.upperBound...]
                    if let endQuote = afterFilename.firstIndex(of: "\"") {
                        part.filename = String(afterFilename[..<endQuote])
                        print("      Found filename: \(part.filename!)")
                    }
                }
            }
        }
        
        // Set data or text value
        if part.filename != nil {
            part.data = Data(bodyData)
            print("      Set file data: \(bodyData.count) bytes")
        } else if let text = String(data: bodyData, encoding: .utf8) {
            // Debug: show raw value
            let escaped = text.replacingOccurrences(of: "\r", with: "\\r").replacingOccurrences(of: "\n", with: "\\n")
            print("      Raw text value: '\(escaped)'")
            
            // Clean the text value - create character set with all unwanted chars
            let unwantedChars = CharacterSet.whitespacesAndNewlines.union(CharacterSet(charactersIn: "-"))
            let cleanText = text.trimmingCharacters(in: unwantedChars)
            
            part.textValue = cleanText
            let cleanEscaped = cleanText.replacingOccurrences(of: "\r", with: "\\r").replacingOccurrences(of: "\n", with: "\\n")
            print("      Cleaned text value: '\(cleanEscaped)'")
        } else {
            print("      ❌ Could not decode body as text")
        }
        
        return part
    }
    
    private func sendHTMLResponse(connection: NWConnection) {
        let folders = FileManagerHelper.shared.getFolders()
        let html = generateHTML(folders: folders)
        
        print("📄 Sending HTML response (\(html.utf8.count) bytes)")
        
        let response = "HTTP/1.1 200 OK\r\n" +
                      "Content-Type: text/html; charset=utf-8\r\n" +
                      "Content-Length: \(html.utf8.count)\r\n\r\n" +
                      html
        
        sendRaw(response, on: connection)
    }
    
    private func sendResponse(connection: NWConnection, statusCode: Int, body: String) {
        let statusText = statusCode == 200 ? "OK" : "Error"
        print("📤 Sending \(statusCode) response: \(body.prefix(50))...")
        
        let response = "HTTP/1.1 \(statusCode) \(statusText)\r\n" +
                      "Content-Type: text/plain; charset=utf-8\r\n" +
                      "Content-Length: \(body.utf8.count)\r\n\r\n" +
                      body
        
        sendRaw(response, on: connection)
    }
    
    private func sendCORSResponse(connection: NWConnection) {
        let response = "HTTP/1.1 200 OK\r\n" +
                      "Access-Control-Allow-Origin: *\r\n" +
                      "Access-Control-Allow-Methods: GET, POST, OPTIONS\r\n" +
                      "Access-Control-Allow-Headers: Content-Type\r\n" +
                      "Content-Length: 0\r\n\r\n"
        
        sendRaw(response, on: connection)
    }
    
    private func sendRaw(_ response: String, on connection: NWConnection) {
        guard let data = response.data(using: .utf8) else {
            print("⚠️ Failed to convert response to data")
            return
        }
        
        print("📡 Sending response (\(data.count) bytes)...")
        
        connection.send(content: data, completion: .contentProcessed { [weak self] error in
            if let error = error {
                print("❌ Send error: \(error)")
            } else {
                print("✅ Response data processed by network stack")
            }
            
            // Remove from active connections
            self?.activeConnections.removeAll { $0 === connection }
            
            // Schedule cleanup after a timeout to allow client to read data
            DispatchQueue.global().asyncAfter(deadline: .now() + 3.0) {
                print("🧹 Closing connection after timeout")
                connection.cancel()
            }
        })
    }
    
    private func generateHTML(folders: [String]) -> String {
        let folderOptions = folders.map { "<option value=\"\($0)\">\($0)</option>" }.joined()
        
        return """
        <!DOCTYPE html>
        <html>
        <head>
            <meta charset="UTF-8">
            <meta name="viewport" content="width=device-width, initial-scale=1">
            <title>Music Upload</title>
            <style>
                * { box-sizing: border-box; margin: 0; padding: 0; }
                body { 
                    font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Arial, sans-serif;
                    background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
                    min-height: 100vh;
                    padding: 20px;
                }
                .container {
                    max-width: 700px;
                    margin: 0 auto;
                    background: white;
                    border-radius: 16px;
                    box-shadow: 0 20px 60px rgba(0,0,0,0.3);
                    overflow: hidden;
                }
                .header {
                    background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
                    color: white;
                    padding: 30px;
                    text-align: center;
                }
                .header h1 { font-size: 28px; margin-bottom: 8px; }
                .header p { opacity: 0.9; font-size: 14px; }
                .content { padding: 30px; }
                .section {
                    margin-bottom: 30px;
                    padding: 20px;
                    background: #f8f9fa;
                    border-radius: 12px;
                }
                .section h2 {
                    font-size: 18px;
                    color: #333;
                    margin-bottom: 15px;
                    display: flex;
                    align-items: center;
                    gap: 8px;
                }
                input, select, button {
                    width: 100%;
                    padding: 12px 16px;
                    border: 2px solid #e0e0e0;
                    border-radius: 8px;
                    font-size: 15px;
                    font-family: inherit;
                    margin-bottom: 12px;
                    transition: all 0.3s;
                }
                input:focus, select:focus {
                    outline: none;
                    border-color: #667eea;
                }
                button {
                    background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
                    color: white;
                    border: none;
                    cursor: pointer;
                    font-weight: 600;
                    margin-bottom: 0;
                }
                button:hover { transform: translateY(-2px); box-shadow: 0 4px 12px rgba(102, 126, 234, 0.4); }
                button:active { transform: translateY(0); }
                .upload-area {
                    border: 3px dashed #d0d0d0;
                    border-radius: 12px;
                    padding: 40px;
                    text-align: center;
                    cursor: pointer;
                    transition: all 0.3s;
                    margin: 15px 0;
                }
                .upload-area:hover, .upload-area.drag-over {
                    border-color: #667eea;
                    background: #f0f4ff;
                }
                .upload-area p { color: #666; margin-bottom: 15px; }
                .file-input { display: none; }
                .progress {
                    margin: 10px 0;
                    padding: 12px;
                    background: white;
                    border-radius: 8px;
                    box-shadow: 0 2px 4px rgba(0,0,0,0.1);
                }
                .progress-name { 
                    font-size: 14px;
                    color: #333;
                    margin-bottom: 8px;
                    font-weight: 500;
                }
                .progress-bar {
                    height: 8px;
                    background: #e0e0e0;
                    border-radius: 4px;
                    overflow: hidden;
                    margin-bottom: 6px;
                }
                .progress-fill {
                    height: 100%;
                    background: linear-gradient(90deg, #667eea 0%, #764ba2 100%);
                    transition: width 0.3s;
                    border-radius: 4px;
                }
                .progress-status {
                    font-size: 13px;
                    color: #666;
                }
                .status-success { color: #28a745; font-weight: 600; }
                .status-error { color: #dc3545; font-weight: 600; }
            </style>
        </head>
        <body>
            <div class="container">
                <div class="header">
                    <h1>🎵 Music Upload</h1>
                    <p>Upload MP3 and M4A files to your music library</p>
                </div>
                <div class="content">
                    <div class="section">
                        <h2>📁 Create New Folder</h2>
                        <input type="text" id="newFolder" placeholder="Enter folder name">
                        <button onclick="createFolder()">Create Folder</button>
                    </div>
                    
                    <div class="section">
                        <h2>📂 Select Folder</h2>
                        <select id="folder">
                            <option value="">-- Choose a folder --</option>
                            \(folderOptions)
                        </select>
                    </div>
                    
                    <div class="section">
                        <h2>📤 Upload Files</h2>
                        <div class="upload-area" id="uploadArea" onclick="document.getElementById('fileInput').click()">
                            <p>🎵 Drag & drop files here or click to browse</p>
                            <button type="button" onclick="event.stopPropagation(); document.getElementById('fileInput').click()">Select Files</button>
                        </div>
                        <input type="file" id="fileInput" class="file-input" multiple accept=".mp3,.m4a">
                        <div id="progress"></div>
                    </div>
                </div>
            </div>
            
            <script>
                const uploadArea = document.getElementById('uploadArea');
                const fileInput = document.getElementById('fileInput');
                const folderSelect = document.getElementById('folder');
                const progressDiv = document.getElementById('progress');
                
                uploadArea.addEventListener('dragover', (e) => {
                    e.preventDefault();
                    uploadArea.classList.add('drag-over');
                });
                
                uploadArea.addEventListener('dragleave', () => {
                    uploadArea.classList.remove('drag-over');
                });
                
                uploadArea.addEventListener('drop', (e) => {
                    e.preventDefault();
                    uploadArea.classList.remove('drag-over');
                    handleFiles(e.dataTransfer.files);
                });
                
                fileInput.addEventListener('change', (e) => {
                    handleFiles(e.target.files);
                });
                
                function createFolder() {
                    const name = document.getElementById('newFolder').value.trim();
                    if (!name) {
                        alert('Please enter a folder name');
                        return;
                    }
                    
                    fetch('/api/createFolder', {
                        method: 'POST',
                        headers: { 'Content-Type': 'application/json' },
                        body: JSON.stringify({ folderName: name })
                    })
                    .then(r => r.text())
                    .then(() => {
                        alert('Folder created!');
                        location.reload();
                    })
                    .catch(e => alert('Error: ' + e));
                }
                
                function handleFiles(files) {
                    const folder = folderSelect.value;
                    if (!folder) {
                        alert('Please select a folder first');
                        return;
                    }
                    
                    progressDiv.innerHTML = '';
                    
                    Array.from(files).forEach((file, i) => {
                        const ext = file.name.split('.').pop().toLowerCase();
                        if (ext !== 'mp3' && ext !== 'm4a') {
                            alert(file.name + ' is not supported (MP3/M4A only)');
                            return;
                        }
                        
                        const progressId = 'progress-' + i;
                        const progressHTML = `
                            <div class="progress" id="${progressId}">
                                <div class="progress-name">${file.name}</div>
                                <div class="progress-bar">
                                    <div class="progress-fill" id="${progressId}-fill" style="width: 0%"></div>
                                </div>
                                <div class="progress-status" id="${progressId}-status">Preparing...</div>
                            </div>
                        `;
                        progressDiv.insertAdjacentHTML('beforeend', progressHTML);
                        
                        const formData = new FormData();
                        formData.append('file', file);
                        formData.append('folder', folder);
                        
                        const xhr = new XMLHttpRequest();
                        
                        xhr.upload.onprogress = (e) => {
                            if (e.lengthComputable) {
                                const pct = Math.round((e.loaded / e.total) * 100);
                                document.getElementById(progressId + '-fill').style.width = pct + '%';
                                document.getElementById(progressId + '-status').textContent = 'Uploading: ' + pct + '%';
                            }
                        };
                        
                        xhr.onload = () => {
                            if (xhr.status === 200) {
                                document.getElementById(progressId + '-fill').style.width = '100%';
                                document.getElementById(progressId + '-status').textContent = '✅ Upload complete!';
                                document.getElementById(progressId + '-status').classList.add('status-success');
                            } else {
                                document.getElementById(progressId + '-status').textContent = '❌ Upload failed';
                                document.getElementById(progressId + '-status').classList.add('status-error');
                            }
                        };
                        
                        xhr.onerror = () => {
                            document.getElementById(progressId + '-status').textContent = '❌ Upload error';
                            document.getElementById(progressId + '-status').classList.add('status-error');
                        };
                        
                        xhr.open('POST', '/api/upload');
                        xhr.send(formData);
                    });
                }
            </script>
        </body>
        </html>
        """
    }
}

