import SwiftUI

struct UploadView: View {
    @StateObject private var serverManager = SimpleUploadServer.shared
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
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                            Text("Access at: http://\(ip):8080")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.9))
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

