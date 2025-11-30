import Foundation
import Combine
import Network

// We'll use a simpler approach with URLSession-based server
// Or we can use Swifter which is Swift-native

class UploadServerManager: ObservableObject {
    static let shared = UploadServerManager()
    
    @Published var isServerRunning = false
    @Published var uploadProgress: [String: Double] = [:] // filename: progress (0.0 to 1.0)
    @Published var uploadStatus: [String: String] = [:] // filename: status message
    
    private var listener: NWListener?
    private let port: UInt16 = 8080
    private var connections: [NWConnection] = []
    private var requestBuffers: [ObjectIdentifier: Data] = [:]
    private var requestStartTimes: [ObjectIdentifier: Date] = [:]
    private var lastDataReceivedTimes: [ObjectIdentifier: Date] = [:]
    
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
                        print("Server started on port \(self?.port ?? 8080)")
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
        connections.forEach { $0.cancel() }
        connections.removeAll()
        requestBuffers.removeAll()
        requestStartTimes.removeAll()
        lastDataReceivedTimes.removeAll()
        isServerRunning = false
    }
    
    private func handleConnection(_ connection: NWConnection) {
        let connectionId = ObjectIdentifier(connection)
        print("New connection established: \(connectionId)")
        connections.append(connection)
        
        connection.stateUpdateHandler = { [weak self] state in
            switch state {
            case .ready:
                print("Connection ready: \(connectionId)")
                self?.receiveData(on: connection)
            case .failed(let error):
                print("Connection failed: \(connectionId), error: \(error)")
                self?.connections.removeAll { $0 === connection }
                self?.requestBuffers.removeValue(forKey: connectionId)
                self?.requestStartTimes.removeValue(forKey: connectionId)
                self?.lastDataReceivedTimes.removeValue(forKey: connectionId)
            case .cancelled:
                print("Connection cancelled: \(connectionId)")
                self?.connections.removeAll { $0 === connection }
                self?.requestBuffers.removeValue(forKey: connectionId)
                self?.requestStartTimes.removeValue(forKey: connectionId)
                self?.lastDataReceivedTimes.removeValue(forKey: connectionId)
            default:
                break
            }
        }
        
        connection.start(queue: .global(qos: .userInitiated))
    }
    
    private func receiveData(on connection: NWConnection) {
        let connectionId = ObjectIdentifier(connection)
        connection.receive(minimumIncompleteLength: 1, maximumLength: 65536) { [weak self] data, context, isComplete, error in
            guard let self = self else { return }
            
            if let error = error {
                print("Receive error: \(error)")
                self.requestBuffers.removeValue(forKey: connectionId)
                self.requestStartTimes.removeValue(forKey: connectionId)
                self.lastDataReceivedTimes.removeValue(forKey: connectionId)
                return
            }
            
            let now = Date()
            var receivedNewData = false
            
            if let data = data, !data.isEmpty {
                receivedNewData = true
                if self.requestBuffers[connectionId] == nil {
                    self.requestBuffers[connectionId] = Data()
                    self.requestStartTimes[connectionId] = now
                }
                self.requestBuffers[connectionId]?.append(data)
                self.lastDataReceivedTimes[connectionId] = now
                
                // Only log occasionally to reduce spam
                let bufferedData = self.requestBuffers[connectionId] ?? Data()
                if bufferedData.count % 500000 < 65536 {
                    print("Received data chunk: \(data.count) bytes, total: \(bufferedData.count) bytes")
                }
            }
            
            let bufferedData = self.requestBuffers[connectionId] ?? Data()
            
            // Check if we have complete headers (for GET requests) or complete request
            let hasHeaders = bufferedData.count > 4 && String(data: bufferedData.prefix(min(2048, bufferedData.count)), encoding: .utf8)?.contains("\r\n\r\n") == true
            
            if isComplete {
                // Connection complete, process whatever we have
                if !bufferedData.isEmpty {
                    print("✅ Connection complete, processing request, size: \(bufferedData.count) bytes")
                    self.processRequest(data: bufferedData, connection: connection)
                    self.requestBuffers.removeValue(forKey: connectionId)
                    self.requestStartTimes.removeValue(forKey: connectionId)
                    self.lastDataReceivedTimes.removeValue(forKey: connectionId)
                }
            } else if hasHeaders {
                // Check if it's a GET request (can process immediately) or POST (need full body)
                if let preview = String(data: bufferedData.prefix(20), encoding: .utf8), preview.contains("GET ") {
                    // GET request - process immediately
                    print("Processing GET request, size: \(bufferedData.count) bytes")
                    self.processRequest(data: bufferedData, connection: connection)
                    self.requestBuffers.removeValue(forKey: connectionId)
                    self.requestStartTimes.removeValue(forKey: connectionId)
                    self.lastDataReceivedTimes.removeValue(forKey: connectionId)
                } else {
                    // POST request - check if we have the complete body
                    
                    // Log once when we first detect it's a POST
                    if bufferedData.count < 100000 {
                        if let preview = String(data: bufferedData.prefix(200), encoding: .utf8) {
                            print("🔵 Detected POST request: \(preview.components(separatedBy: "\r\n").first ?? "unknown")")
                        }
                    }
                    
                    let hasCompleteBody = self.hasCompletePostBody(bufferedData)
                    let timeSinceStart = self.requestStartTimes[connectionId].map { now.timeIntervalSince($0) } ?? 0
                    let timeSinceLastData = self.lastDataReceivedTimes[connectionId].map { now.timeIntervalSince($0) } ?? 0
                    
                    // Safety mechanism: if no new data has arrived for 2 seconds and we have substantial data, process it
                    let hasSubstantialData = bufferedData.count > 10000
                    let idleTimeout = timeSinceLastData > 2.0 && hasSubstantialData && !receivedNewData
                    
                    if hasCompleteBody {
                        print("✅ Processing POST request (complete body detected), size: \(bufferedData.count) bytes")
                        self.processRequest(data: bufferedData, connection: connection)
                        self.requestBuffers.removeValue(forKey: connectionId)
                        self.requestStartTimes.removeValue(forKey: connectionId)
                        self.lastDataReceivedTimes.removeValue(forKey: connectionId)
                    } else if idleTimeout {
                        print("⏰ Processing POST request (idle timeout - no data for \(String(format: "%.1f", timeSinceLastData))s), size: \(bufferedData.count) bytes")
                        self.processRequest(data: bufferedData, connection: connection)
                        self.requestBuffers.removeValue(forKey: connectionId)
                        self.requestStartTimes.removeValue(forKey: connectionId)
                        self.lastDataReceivedTimes.removeValue(forKey: connectionId)
                    } else {
                        // Continue receiving
                        // Only log occasionally
                        if bufferedData.count % 500000 < 65536 {
                            print("⏳ Waiting for more POST data... (current size: \(bufferedData.count), time elapsed: \(String(format: "%.2f", timeSinceStart))s, idle: \(String(format: "%.2f", timeSinceLastData))s)")
                        }
                        self.receiveData(on: connection)
                    }
                }
            } else {
                // Continue receiving
                self.receiveData(on: connection)
            }
        }
    }
    
    private func processRequest(data: Data, connection: NWConnection) {
        // Parse HTTP request
        print("=== Processing request, total size: \(data.count) bytes ===")
        
        // Find the header end first
        let doubleCRLF = "\r\n\r\n".data(using: .utf8)!
        guard let headerEndRange = data.range(of: doubleCRLF) else {
            print("No header end marker found")
            sendErrorResponse(connection: connection, message: "Invalid request")
            return
        }
        
        // Only decode the headers (before the binary body)
        let headerData = data[..<headerEndRange.lowerBound]
        guard let requestString = String(data: headerData, encoding: .utf8) else {
            print("Failed to decode headers as UTF-8")
            sendErrorResponse(connection: connection, message: "Invalid request")
            return
        }
        
        let lines = requestString.components(separatedBy: "\r\n")
        guard let firstLine = lines.first else {
            print("No first line in request")
            sendErrorResponse(connection: connection, message: "Invalid request")
            return
        }
        
        print("Request first line: \(firstLine)")
        
        let components = firstLine.components(separatedBy: " ")
        guard components.count >= 3 else {
            print("Invalid request line format")
            sendErrorResponse(connection: connection, message: "Invalid request")
            return
        }
        
        let method = components[0]
        var path = components[1]
        
        if let queryIndex = path.firstIndex(of: "?") {
            path = String(path[..<queryIndex])
        }
        
        print("\(method) \(path) - Processing...")
        
        if method == "GET" {
            if path == "/" || path.isEmpty {
                sendResponse(connection: connection, html: generateWebInterface())
            } else if path == "/api/folders" {
                sendResponse(connection: connection, json: generateFoldersJSON())
            } else {
                sendErrorResponse(connection: connection, message: "Not Found", statusCode: 404)
            }
        } else if method == "POST" {
            if path == "/api/upload" {
                handleFileUpload(data: data, connection: connection)
            } else if path == "/api/createFolder" {
                handleCreateFolder(data: data, connection: connection)
            } else {
                sendErrorResponse(connection: connection, message: "Not Found", statusCode: 404)
            }
        } else if method == "OPTIONS" {
            // CORS preflight
            let response = "HTTP/1.1 200 OK\r\n" +
                          "Access-Control-Allow-Origin: *\r\n" +
                          "Access-Control-Allow-Methods: GET, POST, OPTIONS\r\n" +
                          "Access-Control-Allow-Headers: Content-Type\r\n" +
                          "Content-Length: 0\r\n\r\n"
            sendRawResponse(connection: connection, response: response)
        } else {
            sendErrorResponse(connection: connection, message: "Method Not Allowed", statusCode: 405)
        }
    }
    
    private func handleFileUpload(data: Data, connection: NWConnection) {
        // Extract boundary
        guard let boundary = extractBoundary(from: data) else {
            sendErrorResponse(connection: connection, message: "No boundary found")
            return
        }
        
        print("Boundary: \(boundary)")
        
        // Parse multipart data using a simpler approach
        let parts = parseMultipart(data: data, boundary: boundary)
        
        var folder: String?
        var uploadedFiles: [(filename: String, data: Data)] = []
        
        for part in parts {
            if part.isFolder {
                folder = part.value
                print("Found folder: \(folder ?? "nil")")
            } else if let filename = part.filename, let fileData = part.data {
                uploadedFiles.append((filename: filename, data: fileData))
                print("Found file: \(filename), size: \(fileData.count) bytes")
            }
        }
        
        guard let targetFolder = folder else {
            sendErrorResponse(connection: connection, message: "No folder specified")
            return
        }
        
        var uploadedCount = 0
        for (filename, fileData) in uploadedFiles {
            let lowercased = filename.lowercased()
            // Only accept supported audio formats
            if !(lowercased.hasSuffix(".mp3") || lowercased.hasSuffix(".m4a")) {
                continue
            }
            
            DispatchQueue.main.async {
                self.uploadStatus[filename] = "Uploading..."
                self.uploadProgress[filename] = 0.0
            }
            
            let folderPath = FileManagerHelper.shared.getFolderPath(targetFolder)
            let filePath = "\(folderPath)/\(filename)"
            let fileURL = URL(fileURLWithPath: filePath)
            
            let fileManager = FileManager.default
            if !fileManager.fileExists(atPath: folderPath) {
                do {
                    try fileManager.createDirectory(atPath: folderPath, withIntermediateDirectories: true, attributes: nil)
                } catch {
                    print("Failed to create folder: \(error)")
                    DispatchQueue.main.async {
                        self.uploadStatus[filename] = "Failed: \(error.localizedDescription)"
                    }
                    continue
                }
            }
            
            do {
                try fileData.write(to: fileURL)
                print("File saved: \(filename)")
                
                DispatchQueue.main.async {
                    self.uploadProgress[filename] = 1.0
                    self.uploadStatus[filename] = "Uploaded successfully"
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                        self.uploadProgress.removeValue(forKey: filename)
                        self.uploadStatus.removeValue(forKey: filename)
                    }
                }
                uploadedCount += 1
            } catch {
                print("Failed to save file: \(error)")
                DispatchQueue.main.async {
                    self.uploadStatus[filename] = "Failed: \(error.localizedDescription)"
                }
            }
        }
        
        let message = uploadedCount > 0 ? "\(uploadedCount) file(s) uploaded successfully" : "No files uploaded"
        sendResponse(connection: connection, text: message)
    }
    
    private func handleCreateFolder(data: Data, connection: NWConnection) {
        // Find JSON body
        guard let bodyRange = String(data: data, encoding: .utf8)?.range(of: "\r\n\r\n") else {
            sendErrorResponse(connection: connection, message: "Invalid request")
            return
        }
        
        let bodyString = String(data: data, encoding: .utf8) ?? ""
        let jsonString = String(bodyString[bodyRange.upperBound...])
        guard let jsonData = jsonString.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any],
              let action = json["action"] as? String,
              action == "createFolder",
              let folderName = json["folderName"] as? String,
              !folderName.isEmpty else {
            sendErrorResponse(connection: connection, message: "Invalid request")
            return
        }
        
        do {
            try FileManagerHelper.shared.createFolder(name: folderName)
            sendResponse(connection: connection, text: "Folder created: \(folderName)")
        } catch {
            sendErrorResponse(connection: connection, message: "Error: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Multipart Parsing
    
    private struct MultipartPart {
        let filename: String?
        let value: String?
        let data: Data?
        let isFolder: Bool
        
        init(filename: String? = nil, value: String? = nil, data: Data? = nil) {
            self.filename = filename
            self.value = value
            self.data = data
            self.isFolder = filename == nil && value != nil
        }
    }
    
    private func extractBoundary(from data: Data) -> String? {
        guard let string = String(data: data.prefix(2048), encoding: .utf8) else { return nil }
        for line in string.components(separatedBy: "\r\n") {
            if line.lowercased().contains("content-type:") && line.contains("boundary=") {
                let parts = line.components(separatedBy: "boundary=")
                if parts.count > 1 {
                    var boundary = parts[1].trimmingCharacters(in: .whitespacesAndNewlines)
                    if boundary.hasPrefix("\"") && boundary.hasSuffix("\"") {
                        boundary = String(boundary.dropFirst().dropLast())
                    }
                    if boundary.hasSuffix(";") {
                        boundary = String(boundary.dropLast())
                    }
                    return "--" + boundary.trimmingCharacters(in: .whitespacesAndNewlines)
                }
            }
        }
        return nil
    }
    
    private func hasCompletePostBody(_ data: Data) -> Bool {
        // First, always check Content-Length as it's the most reliable
        if checkContentLength(data: data) {
            return true
        }
        
        // If no Content-Length or it doesn't match yet, check for multipart boundary completion
        guard let preview = String(data: data.prefix(min(2048, data.count)), encoding: .utf8),
              preview.contains("POST ") && preview.contains("multipart/form-data") else {
            // Not multipart and no valid Content-Length
            return false
        }
        
        // Extract boundary
        guard let boundary = extractBoundary(from: data) else {
            return false
        }
        
        // Check for final boundary marker - it can appear in various formats:
        // 1. \r\n--boundary--\r\n
        // 2. --boundary--\r\n
        // 3. \r\n--boundary--
        // 4. --boundary--
        let finalBoundary1 = ("\r\n" + boundary + "--\r\n").data(using: .utf8)!
        let finalBoundary2 = ("\r\n" + boundary + "--").data(using: .utf8)!
        let finalBoundary3 = (boundary + "--\r\n").data(using: .utf8)!
        let finalBoundary4 = (boundary + "--").data(using: .utf8)!
        
        // Check in the last 1000 bytes for any of these patterns
        let searchLength = min(1000, data.count)
        if data.count > 0 {
            let tail = data.suffix(searchLength)
            
            if tail.range(of: finalBoundary1) != nil {
                print("Found final boundary marker (format 1)")
                return true
            }
            if tail.range(of: finalBoundary2) != nil {
                print("Found final boundary marker (format 2)")
                return true
            }
            if tail.range(of: finalBoundary3) != nil {
                print("Found final boundary marker (format 3)")
                return true
            }
            if tail.range(of: finalBoundary4) != nil {
                print("Found final boundary marker (format 4)")
                return true
            }
        }
        
        return false
    }
    
    private var loggedContentLengthInfo: Set<Int> = []
    
    private func checkContentLength(data: Data) -> Bool {
        guard let headerString = String(data: data.prefix(min(2048, data.count)), encoding: .utf8) else {
            return false
        }
        
        // Find where headers end
        guard let headerEndRange = headerString.range(of: "\r\n\r\n") else {
            return false
        }
        
        let headerLength = headerString.distance(from: headerString.startIndex, to: headerEndRange.upperBound)
        
        // Look for Content-Length header
        let lines = headerString.components(separatedBy: "\r\n")
        var foundContentLength = false
        for line in lines {
            if line.lowercased().hasPrefix("content-length:") {
                foundContentLength = true
                let parts = line.components(separatedBy: ":")
                if parts.count > 1, let contentLength = Int(parts[1].trimmingCharacters(in: .whitespacesAndNewlines)) {
                    let expectedTotal = headerLength + contentLength
                    let hasEnough = data.count >= expectedTotal
                    
                    // Log once when we find Content-Length
                    if !self.loggedContentLengthInfo.contains(contentLength) {
                        print("📊 Content-Length header found: \(contentLength) bytes (+ \(headerLength) header bytes = \(expectedTotal) total)")
                        self.loggedContentLengthInfo.insert(contentLength)
                    }
                    
                    // Log progress for large uploads
                    if !hasEnough && contentLength > 100000 {
                        let progress = Int((Double(data.count - headerLength) / Double(contentLength)) * 100)
                        // Log every 20% 
                        if progress % 20 == 0 && progress > 0 {
                            print("📈 Upload progress: \(progress)% (\(data.count - headerLength)/\(contentLength) bytes)")
                        }
                    } else if hasEnough {
                        print("✅ Content-Length satisfied: \(data.count) >= \(expectedTotal) bytes")
                        self.loggedContentLengthInfo.remove(contentLength) // Reset for next upload
                    }
                    
                    return hasEnough
                }
            }
        }
        
        if !foundContentLength && data.count > headerLength && data.count < headerLength + 1000 {
            print("⚠️ No Content-Length header found in request")
        }
        
        return false
    }
    
    private func parseMultipart(data: Data, boundary: String) -> [MultipartPart] {
        var parts: [MultipartPart] = []
        
        guard let boundaryData = boundary.data(using: .utf8) else { return parts }
        
        // Find body start in Data directly
        let doubleCRLF = "\r\n\r\n".data(using: .utf8)!
        guard let bodyStartRange = data.range(of: doubleCRLF) else { return parts }
        let bodyStart = bodyStartRange.upperBound
        
        let bodyData = data[bodyStart...]
        let boundaryMarker = (boundary + "\r\n").data(using: .utf8)!
        let partBoundary = ("\r\n" + boundary + "\r\n").data(using: .utf8)!
        let finalBoundary = ("\r\n" + boundary + "--\r\n").data(using: .utf8)!
        
        // Find all boundaries
        var boundaries: [Data.Index] = []
        var searchStart = bodyData.startIndex
        
        // First boundary
        if let first = bodyData.range(of: boundaryMarker, options: [], in: searchStart..<bodyData.endIndex) {
            boundaries.append(first.lowerBound)
            searchStart = first.upperBound
        }
        
        // Other boundaries
        while let found = bodyData.range(of: partBoundary, options: [], in: searchStart..<bodyData.endIndex) {
            boundaries.append(found.lowerBound)
            searchStart = found.upperBound
        }
        
        // Final boundary
        if let final = bodyData.range(of: finalBoundary, options: [], in: bodyData.startIndex..<bodyData.endIndex) {
            boundaries.append(final.lowerBound)
        } else {
            boundaries.append(bodyData.endIndex)
        }
        
        // Parse each part
        for i in 0..<max(0, boundaries.count - 1) {
            let partStart = boundaries[i] + (i == 0 ? boundaryMarker.count : partBoundary.count)
            let partEnd = boundaries[i + 1]
            
            if partStart < partEnd {
                let partData = bodyData[partStart..<partEnd]
                if let part = parsePart(partData) {
                    parts.append(part)
                }
            }
        }
        
        return parts
    }
    
    private func parsePart(_ data: Data) -> MultipartPart? {
        let doubleCRLF = "\r\n\r\n".data(using: .utf8)!
        guard let headerEnd = data.range(of: doubleCRLF) else { return nil }
        
        let headerData = data[..<headerEnd.lowerBound]
        let bodyData = data[headerEnd.upperBound...]
        
        guard let headerString = String(data: headerData, encoding: .utf8) else { return nil }
        
        var filename: String?
        var name: String?
        
        // Extract filename
        if let filenameRange = headerString.range(of: "filename=\"") {
            let after = String(headerString[filenameRange.upperBound...])
            if let endRange = after.range(of: "\"") {
                filename = String(after[..<endRange.lowerBound])
            }
        }
        
        // Extract name
        if let nameRange = headerString.range(of: "name=\"") {
            let after = String(headerString[nameRange.upperBound...])
            if let endRange = after.range(of: "\"") {
                name = String(after[..<endRange.lowerBound])
            }
        }
        
        // Remove trailing \r\n from body
        var cleanBody = bodyData
        if cleanBody.count >= 2 && cleanBody.suffix(2) == "\r\n".data(using: .utf8) {
            cleanBody = cleanBody.dropLast(2)
        }
        
        if let filename = filename {
            return MultipartPart(filename: filename, data: Data(cleanBody))
        } else if let name = name, name == "folder" {
            if let value = String(data: cleanBody, encoding: .utf8) {
                return MultipartPart(value: value.trimmingCharacters(in: .whitespacesAndNewlines))
            }
        }
        
        return nil
    }
    
    // MARK: - Response Helpers
    
    private func sendResponse(connection: NWConnection, html: String) {
        let response = "HTTP/1.1 200 OK\r\n" +
                      "Content-Type: text/html; charset=utf-8\r\n" +
                      "Access-Control-Allow-Origin: *\r\n" +
                      "Content-Length: \(html.utf8.count)\r\n\r\n" +
                      html
        sendRawResponse(connection: connection, response: response)
    }
    
    private func sendResponse(connection: NWConnection, json: String) {
        let jsonData = json.data(using: .utf8) ?? Data()
        let response = "HTTP/1.1 200 OK\r\n" +
                      "Content-Type: application/json\r\n" +
                      "Access-Control-Allow-Origin: *\r\n" +
                      "Content-Length: \(jsonData.count)\r\n\r\n" +
                      json
        sendRawResponse(connection: connection, response: response)
    }
    
    private func sendResponse(connection: NWConnection, text: String) {
        let response = "HTTP/1.1 200 OK\r\n" +
                      "Content-Type: text/plain\r\n" +
                      "Access-Control-Allow-Origin: *\r\n" +
                      "Content-Length: \(text.utf8.count)\r\n\r\n" +
                      text
        sendRawResponse(connection: connection, response: response)
    }
    
    private func sendErrorResponse(connection: NWConnection, message: String, statusCode: Int = 400) {
        let response = "HTTP/1.1 \(statusCode) \(statusCode == 404 ? "Not Found" : "Bad Request")\r\n" +
                      "Content-Type: text/plain\r\n" +
                      "Access-Control-Allow-Origin: *\r\n" +
                      "Content-Length: \(message.utf8.count)\r\n\r\n" +
                      message
        sendRawResponse(connection: connection, response: response)
    }
    
    private func sendRawResponse(connection: NWConnection, response: String) {
        guard let responseData = response.data(using: .utf8) else {
            print("Failed to convert response to data")
            return
        }
        
        let connectionId = ObjectIdentifier(connection)
        print("Sending response to connection \(connectionId), size: \(responseData.count) bytes")
        
        // Send the response
        connection.send(content: responseData, completion: .contentProcessed { [weak self] error in
            if let error = error {
                print("Error sending response to \(connectionId): \(error)")
            } else {
                print("Response sent successfully to \(connectionId)")
            }
            
            // Don't close connection immediately - allow for HTTP keep-alive
            // The connection will be closed when the client closes it or we receive the next request
            // For now, keep it open and continue receiving
            print("Keeping connection \(connectionId) open for potential keep-alive")
            
            // Continue receiving on this connection for potential next request
            if let self = self, self.connections.contains(where: { $0 === connection }) {
                // Reset buffer for potential next request on same connection
                self.requestBuffers.removeValue(forKey: connectionId)
                self.requestStartTimes.removeValue(forKey: connectionId)
                self.lastDataReceivedTimes.removeValue(forKey: connectionId)
                // Continue receiving
                self.receiveData(on: connection)
            }
        })
    }
    
    private func generateWebInterface() -> String {
        let folders = FileManagerHelper.shared.getFolders()
        let foldersJSON = folders.map { "\"\($0)\"" }.joined(separator: ",")
        
        return """
        <!DOCTYPE html>
        <html>
        <head>
            <title>Music Player Upload</title>
            <meta name="viewport" content="width=device-width, initial-scale=1">
            <style>
                body { font-family: Arial, sans-serif; max-width: 800px; margin: 0 auto; padding: 20px; }
                h1 { color: #333; }
                .folder-select { margin: 20px 0; }
                .folder-select select { width: 100%; padding: 10px; font-size: 16px; }
                .upload-area { border: 2px dashed #ccc; padding: 40px; text-align: center; margin: 20px 0; }
                .upload-area.dragover { border-color: #007AFF; background: #f0f8ff; }
                .file-input { display: none; }
                .upload-button { background: #007AFF; color: white; padding: 12px 24px; border: none; border-radius: 8px; cursor: pointer; font-size: 16px; }
                .upload-button:hover { background: #0056b3; }
                .progress-container { margin: 10px 0; }
                .progress-bar { width: 100%; height: 20px; background: #f0f0f0; border-radius: 10px; overflow: hidden; }
                .progress-fill { height: 100%; background: #007AFF; transition: width 0.3s; }
                .status { margin: 5px 0; padding: 5px; }
                .create-folder { margin: 20px 0; }
                .create-folder input { padding: 10px; font-size: 16px; width: 200px; }
                .create-folder button { padding: 10px 20px; font-size: 16px; margin-left: 10px; }
            </style>
        </head>
        <body>
            <h1>Music Player Upload Server</h1>
            
            <div class="create-folder">
                <h2>Create New Folder</h2>
                <input type="text" id="folderName" placeholder="Folder name">
                <button onclick="createFolder()">Create Folder</button>
            </div>
            
            <div class="folder-select">
                <h2>Select Folder</h2>
                <select id="folderSelect">
                    <option value="">-- Select a folder --</option>
                </select>
            </div>
            
            <div class="upload-area" id="uploadArea" ondrop="handleDrop(event)" ondragover="handleDragOver(event)" ondragleave="handleDragLeave(event)">
                <p>Drag and drop MP3/M4A files here or click to select</p>
                <input type="file" id="fileInput" class="file-input" multiple accept=".mp3,.m4a" onchange="handleFileSelect(event)">
                <button class="upload-button" onclick="document.getElementById('fileInput').click()">Select Files</button>
            </div>
            
            <div id="uploadStatus"></div>
            
            <script>
                const folders = [\(foldersJSON)];
                const folderSelect = document.getElementById('folderSelect');
                
                folders.forEach(folder => {
                    const option = document.createElement('option');
                    option.value = folder;
                    option.textContent = folder;
                    folderSelect.appendChild(option);
                });
                
                function createFolder() {
                    const folderName = document.getElementById('folderName').value.trim();
                    if (!folderName) {
                        alert('Please enter a folder name');
                        return;
                    }
                    
                    fetch('/api/createFolder', {
                        method: 'POST',
                        headers: { 'Content-Type': 'application/json' },
                        body: JSON.stringify({ action: 'createFolder', folderName: folderName })
                    })
                    .then(response => response.text())
                    .then(data => {
                        alert(data);
                        location.reload();
                    })
                    .catch(error => {
                        alert('Error: ' + error);
                    });
                }
                
                function handleDragOver(e) {
                    e.preventDefault();
                    e.currentTarget.classList.add('dragover');
                }
                
                function handleDragLeave(e) {
                    e.preventDefault();
                    e.currentTarget.classList.remove('dragover');
                }
                
                function handleDrop(e) {
                    e.preventDefault();
                    e.currentTarget.classList.remove('dragover');
                    const files = e.dataTransfer.files;
                    uploadFiles(files);
                }
                
                function handleFileSelect(e) {
                    const files = e.target.files;
                    uploadFiles(files);
                }
                
                function uploadFiles(files) {
                    const folder = folderSelect.value;
                    if (!folder) {
                        alert('Please select a folder first');
                        return;
                    }
                    
                    const statusDiv = document.getElementById('uploadStatus');
                    statusDiv.innerHTML = '';
                    
                    Array.from(files).forEach((file, index) => {
                        const name = file.name.toLowerCase();
                        if (!name.endsWith('.mp3') && !name.endsWith('.m4a')) {
                            alert(file.name + ' is not a supported audio file (MP3/M4A)');
                            return;
                        }
                        
                        const formData = new FormData();
                        formData.append('file', file);
                        formData.append('folder', folder);
                        
                        const progressContainer = document.createElement('div');
                        progressContainer.className = 'progress-container';
                        const fileName = file.name;
                        const progressId = 'progress-' + index;
                        const statusId = 'status-' + index;
                        progressContainer.innerHTML = 
                            '<div>' + fileName + '</div>' +
                            '<div class="progress-bar">' +
                            '<div class="progress-fill" id="' + progressId + '" style="width: 0%"></div>' +
                            '</div>' +
                            '<div class="status" id="' + statusId + '">Preparing...</div>';
                        statusDiv.appendChild(progressContainer);
                        
                        const xhr = new XMLHttpRequest();
                        
                        xhr.upload.addEventListener('progress', (e) => {
                            if (e.lengthComputable) {
                                const percent = (e.loaded / e.total) * 100;
                                document.getElementById(progressId).style.width = percent + '%';
                                document.getElementById(statusId).textContent = 'Uploading: ' + Math.round(percent) + '%';
                            }
                        });
                        
                        xhr.addEventListener('load', () => {
                            if (xhr.status === 200) {
                                document.getElementById(statusId).textContent = 'Uploaded successfully!';
                                document.getElementById(progressId).style.background = '#28a745';
                            } else {
                                document.getElementById(statusId).textContent = 'Upload failed';
                                document.getElementById(progressId).style.background = '#dc3545';
                            }
                        });
                        
                        xhr.addEventListener('error', () => {
                            document.getElementById(statusId).textContent = 'Upload error';
                            document.getElementById(progressId).style.background = '#dc3545';
                        });
                        
                        xhr.open('POST', '/api/upload');
                        xhr.send(formData);
                    });
                }
            </script>
        </body>
        </html>
        """
    }
    
    private func generateFoldersJSON() -> String {
        let folders = FileManagerHelper.shared.getFolders()
        let json = folders.map { "\"\($0)\"" }.joined(separator: ",")
        return "[\(json)]"
    }
}

