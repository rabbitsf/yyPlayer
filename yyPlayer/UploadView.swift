import SwiftUI

struct UploadView: View {
    @StateObject private var serverManager = WiFiUploadServer.shared
    @State private var ipAddress: String? = nil
    @State private var showIPAlert = false
    
    var body: some View {
        ZStack {
            // Beautiful gradient background
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
            
            // Decorative background elements
            GeometryReader { geo in
                Group {
                    // Top area decorations
                    Image(systemName: "wifi")
                        .font(.system(size: 42))
                        .foregroundColor(.white.opacity(0.1))
                        .position(x: geo.size.width * 0.15, y: geo.size.height * 0.12)
                    
                    Image(systemName: "arrow.up.circle")
                        .font(.system(size: 40))
                        .foregroundColor(.white.opacity(0.12))
                        .position(x: geo.size.width * 0.85, y: geo.size.height * 0.15)
                    
                    // Middle decorations
                    Image(systemName: "network")
                        .font(.system(size: 35))
                        .foregroundColor(.white.opacity(0.09))
                        .position(x: geo.size.width * 0.1, y: geo.size.height * 0.4)
                    
                    Image(systemName: "music.note")
                        .font(.system(size: 32))
                        .foregroundColor(.white.opacity(0.08))
                        .position(x: geo.size.width * 0.9, y: geo.size.height * 0.45)
                    
                    // Bottom decorations
                    Image(systemName: "server.rack")
                        .font(.system(size: 38))
                        .foregroundColor(.white.opacity(0.11))
                        .position(x: geo.size.width * 0.12, y: geo.size.height * 0.7)
                    
                    Image(systemName: "icloud.and.arrow.up")
                        .font(.system(size: 36))
                        .foregroundColor(.white.opacity(0.1))
                        .position(x: geo.size.width * 0.88, y: geo.size.height * 0.75)
                    
                    // Decorative dots
                    ForEach(0..<8) { i in
                        Circle()
                            .fill(Color.white.opacity(0.05 + Double(i % 3) * 0.01))
                            .frame(width: CGFloat(5 + i % 4), height: CGFloat(5 + i % 4))
                            .position(
                                x: geo.size.width * CGFloat([0.25, 0.75, 0.3, 0.7, 0.2, 0.8, 0.35, 0.65][i]),
                                y: geo.size.height * CGFloat([0.22, 0.28, 0.52, 0.58, 0.82, 0.88, 0.35, 0.62][i])
                            )
                    }
                }
            }
            
            // Content frame
            RoundedRectangle(cornerRadius: 25)
                .stroke(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color.white.opacity(0.2),
                            Color.white.opacity(0.05),
                            Color.white.opacity(0.15)
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 2
                )
                .padding(15)
            
            VStack(spacing: 20) {
                // IP Address Section
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Image(systemName: "network")
                            .font(.title2)
                            .foregroundStyle(
                                LinearGradient(
                                    gradient: Gradient(colors: [Color.cyan, Color.blue]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                        Text("Device IP Address")
                            .font(.headline)
                            .foregroundColor(.white)
                    }
                    
                    if let ip = ipAddress {
                        HStack {
                            Text(ip)
                                .font(.system(.body, design: .monospaced))
                                .foregroundColor(.white)
                                .padding()
                                .background(
                                    RoundedRectangle(cornerRadius: 10)
                                        .fill(Color.white.opacity(0.2))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 10)
                                                .stroke(Color.white.opacity(0.3), lineWidth: 1)
                                        )
                                )
                            
                            Button(action: {
                                UIPasteboard.general.string = ip
                            }) {
                                Image(systemName: "doc.on.doc")
                                    .foregroundColor(.white)
                                    .padding(12)
                                    .background(
                                        Circle()
                                            .fill(
                                                LinearGradient(
                                                    gradient: Gradient(colors: [Color.cyan, Color.blue]),
                                                    startPoint: .topLeading,
                                                    endPoint: .bottomTrailing
                                                )
                                            )
                                    )
                                    .shadow(color: Color.cyan.opacity(0.4), radius: 5, x: 0, y: 3)
                            }
                        }
                    } else {
                        Text("Unable to get IP address")
                            .foregroundColor(.red.opacity(0.9))
                    }
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: 15)
                        .fill(Color.white.opacity(0.15))
                        .overlay(
                            RoundedRectangle(cornerRadius: 15)
                                .stroke(
                                    LinearGradient(
                                        gradient: Gradient(colors: [Color.white.opacity(0.3), Color.clear]),
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 1
                                )
                        )
                )
                .padding(.horizontal)
                
                // Upload Server Toggle
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        HStack {
                            Image(systemName: "server.rack")
                                .font(.title2)
                                .foregroundStyle(
                                    LinearGradient(
                                        gradient: Gradient(colors: [Color.green, Color.cyan]),
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                            Text("Upload Server")
                                .font(.headline)
                                .foregroundColor(.white)
                        }
                        
                        Spacer()
                        
                        Toggle("", isOn: Binding(
                            get: { serverManager.isServerRunning },
                            set: { isOn in
                                if isOn {
                                    serverManager.startServer()
                                } else {
                                    serverManager.stopServer()
                                }
                            }
                        ))
                        .tint(.green)
                    }
                    
                    if serverManager.isServerRunning, let ip = ipAddress {
                        VStack(alignment: .leading, spacing: 5) {
                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                                Text("Access at: http://\(ip):8080")
                                    .font(.caption)
                                    .foregroundColor(.white.opacity(0.9))
                            }
                            
                            HStack {
                                Image(systemName: "lock.open.fill")
                                    .foregroundColor(.yellow)
                                Text("Screen will not auto-lock while server is active")
                                    .font(.caption2)
                                    .foregroundColor(.yellow.opacity(0.9))
                            }
                        }
                        .padding(.top, 5)
                    } else {
                        HStack {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.gray)
                            Text("Server is disabled")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.7))
                        }
                        .padding(.top, 5)
                    }
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 15)
                        .fill(Color.white.opacity(0.15))
                        .overlay(
                            RoundedRectangle(cornerRadius: 15)
                                .stroke(
                                    LinearGradient(
                                        gradient: Gradient(colors: [Color.white.opacity(0.3), Color.clear]),
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 1
                                )
                        )
                )
                .padding(.horizontal)
                
                // Upload Status Section
                if !serverManager.uploadStatus.isEmpty {
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Image(systemName: "list.bullet")
                                .font(.title3)
                                .foregroundStyle(
                                    LinearGradient(
                                        gradient: Gradient(colors: [Color.orange, Color.pink]),
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                            Text("Upload Status")
                                .font(.headline)
                                .foregroundColor(.white)
                        }
                        .padding(.horizontal)
                        
                        ScrollView {
                            VStack(alignment: .leading, spacing: 8) {
                                ForEach(Array(serverManager.uploadStatus.keys.sorted()), id: \.self) { filename in
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(filename)
                                            .font(.caption)
                                            .foregroundColor(.white)
                                            .lineLimit(1)
                                        
                                        if let status = serverManager.uploadStatus[filename] {
                                            Text(status)
                                                .font(.caption2)
                                                .foregroundColor(.white.opacity(0.7))
                                        }
                                    }
                                    .padding(.horizontal)
                                    .padding(.vertical, 8)
                                    .background(
                                        RoundedRectangle(cornerRadius: 8)
                                            .fill(Color.white.opacity(0.1))
                                    )
                                    .padding(.horizontal)
                                }
                            }
                        }
                        .frame(maxHeight: 200)
                    }
                    .padding(.vertical)
                    .background(
                        RoundedRectangle(cornerRadius: 15)
                            .fill(Color.white.opacity(0.15))
                            .overlay(
                                RoundedRectangle(cornerRadius: 15)
                                    .stroke(
                                        LinearGradient(
                                            gradient: Gradient(colors: [Color.white.opacity(0.3), Color.clear]),
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        ),
                                        lineWidth: 1
                                    )
                            )
                    )
                    .padding(.horizontal)
                }
                
                Spacer()
            }
            .padding(.top)
        }
        .navigationTitle("Upload")
        .navigationBarTitleDisplayMode(.large)
        .onAppear {
            loadIPAddress()
        }
    }
    
    private func loadIPAddress() {
        ipAddress = NetworkHelper.shared.getLocalIPAddress()
    }
}

