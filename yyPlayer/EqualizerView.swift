import SwiftUI

struct EqualizerView: View {
    let levels: [CGFloat]
    let barCount: Int = 8
    let barWidth: CGFloat = 8
    let barSpacing: CGFloat = 6
    
    var body: some View {
        HStack(spacing: barSpacing) {
            ForEach(0..<barCount, id: \.self) { index in
                RoundedRectangle(cornerRadius: 4)
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color.cyan,
                                Color.blue,
                                Color.purple
                            ]),
                            startPoint: .bottom,
                            endPoint: .top
                        )
                    )
                    .frame(width: barWidth)
                    .frame(height: max(20, levels[index] * 120))
                    .shadow(color: Color.cyan.opacity(0.5), radius: 4, x: 0, y: 2)
                    .animation(.spring(response: 0.3, dampingFraction: 0.6), value: levels[index])
            }
        }
        .frame(height: 120)
    }
}

struct EqualizerCircleView: View {
    let levels: [CGFloat]
    let barCount: Int = 24
    
    var body: some View {
        ZStack {
            // Animated pulsing glow circles
            ForEach(0..<3) { ring in
                Circle()
                    .stroke(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color.cyan.opacity(0.4),
                                Color.blue.opacity(0.3),
                                Color.purple.opacity(0.2)
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 2
                    )
                    .frame(width: 140 + CGFloat(ring) * 30, height: 140 + CGFloat(ring) * 30)
                    .opacity(0.3 - Double(ring) * 0.1)
            }
            
            // Outer glow circle - more intense
            Circle()
                .fill(
                    RadialGradient(
                        gradient: Gradient(colors: [
                            Color.cyan.opacity(0.5),
                            Color.blue.opacity(0.3),
                            Color.purple.opacity(0.1),
                            Color.clear
                        ]),
                        center: .center,
                        startRadius: 40,
                        endRadius: 120
                    )
                )
                .frame(width: 240, height: 240)
            
            // Circular bars - bigger and more dramatic
            ForEach(0..<barCount, id: \.self) { index in
                RoundedRectangle(cornerRadius: 3)
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color.cyan,
                                Color.blue,
                                Color.purple
                            ]),
                            startPoint: .bottom,
                            endPoint: .top
                        )
                    )
                    .frame(width: 5, height: 20 + getLevelForBar(index) * 50) // Doubled height range
                    .offset(y: -60)
                    .rotationEffect(.degrees(Double(index) * (360.0 / Double(barCount))))
                    .shadow(color: Color.cyan.opacity(0.8), radius: 5, x: 0, y: 0)
                    .shadow(color: Color.blue.opacity(0.6), radius: 8, x: 0, y: 0) // Double shadow for glow
                    .animation(.spring(response: 0.2, dampingFraction: 0.5), value: getLevelForBar(index)) // Faster response
            }
            
            // Pulsing center circle background
            Circle()
                .fill(
                    RadialGradient(
                        gradient: Gradient(colors: [
                            Color.blue.opacity(0.3),
                            Color.purple.opacity(0.2),
                            Color.clear
                        ]),
                        center: .center,
                        startRadius: 0,
                        endRadius: 50
                    )
                )
                .frame(width: 100, height: 100)
                .scaleEffect(1.0 + (levels.reduce(0, +) / CGFloat(levels.count)) * 0.3) // Pulse with music
                .animation(.easeInOut(duration: 0.2), value: levels)
            
            // Center icon with pulsing effect
            Image(systemName: "music.note")
                .font(.system(size: 50))
                .foregroundStyle(
                    LinearGradient(
                        gradient: Gradient(colors: [Color.cyan, Color.blue, Color.purple]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .shadow(color: Color.cyan.opacity(0.8), radius: 15, x: 0, y: 5)
                .shadow(color: Color.blue.opacity(0.6), radius: 20, x: 0, y: 5)
                .scaleEffect(1.0 + (levels.reduce(0, +) / CGFloat(levels.count)) * 0.2) // Slight pulse
                .animation(.easeInOut(duration: 0.2), value: levels)
        }
        .frame(width: 240, height: 240)
    }
    
    private func getLevelForBar(_ index: Int) -> CGFloat {
        let levelIndex = index % levels.count
        return levels[levelIndex]
    }
}

