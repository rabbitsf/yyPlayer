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
    let barCount: Int = 32
    
    var body: some View {
        let avgLevel = levels.reduce(0, +) / CGFloat(levels.count)
        
        ZStack {
            // INTENSE pulsing outer glow that explodes with the music
            Circle()
                .fill(
                    RadialGradient(
                        gradient: Gradient(colors: [
                            Color.cyan.opacity(0.6 + avgLevel * 0.4),
                            Color.blue.opacity(0.4 + avgLevel * 0.3),
                            Color.purple.opacity(0.2 + avgLevel * 0.2),
                            Color.clear
                        ]),
                        center: .center,
                        startRadius: 30,
                        endRadius: 140
                    )
                )
                .frame(width: 280, height: 280)
                .scaleEffect(1.0 + avgLevel * 0.5) // HUGE pulse with music
                .animation(.easeOut(duration: 0.1), value: avgLevel)
            
            // Multiple animated rings that pulse
            ForEach(0..<4) { ring in
                Circle()
                    .stroke(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color.cyan.opacity(0.6 - Double(ring) * 0.15),
                                Color.blue.opacity(0.5 - Double(ring) * 0.12),
                                Color.purple.opacity(0.4 - Double(ring) * 0.1)
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 3
                    )
                    .frame(width: 130 + CGFloat(ring) * 35, height: 130 + CGFloat(ring) * 35)
                    .scaleEffect(1.0 + avgLevel * CGFloat(0.3 - Double(ring) * 0.05))
                    .opacity(0.5 - Double(ring) * 0.1)
                    .animation(.easeOut(duration: 0.1), value: avgLevel)
            }
            
            // MASSIVE circular bars - tripled height range!
            ForEach(0..<barCount, id: \.self) { index in
                let level = getLevelForBar(index)
                
                RoundedRectangle(cornerRadius: 4)
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color.cyan.opacity(0.8 + level * 0.2),
                                Color.blue,
                                Color.purple
                            ]),
                            startPoint: .bottom,
                            endPoint: .top
                        )
                    )
                    .frame(width: 6, height: 15 + level * 80) // TRIPLED from 50 to 80!
                    .offset(y: -65)
                    .rotationEffect(.degrees(Double(index) * (360.0 / Double(barCount))))
                    .shadow(color: Color.cyan.opacity(1.0), radius: 8, x: 0, y: 0)
                    .shadow(color: Color.blue.opacity(0.8), radius: 12, x: 0, y: 0)
                    .shadow(color: Color.purple.opacity(0.6), radius: 16, x: 0, y: 0) // Triple shadow!
                    .animation(.easeOut(duration: 0.08), value: level) // INSTANT response!
            }
            
            // EXPLOSIVE center pulse
            Circle()
                .fill(
                    RadialGradient(
                        gradient: Gradient(colors: [
                            Color.cyan.opacity(0.5 + avgLevel * 0.5),
                            Color.blue.opacity(0.4 + avgLevel * 0.4),
                            Color.purple.opacity(0.3 + avgLevel * 0.3),
                            Color.clear
                        ]),
                        center: .center,
                        startRadius: 0,
                        endRadius: 60
                    )
                )
                .frame(width: 120, height: 120)
                .scaleEffect(0.8 + avgLevel * 0.6) // HUGE center pulse
                .animation(.easeOut(duration: 0.1), value: avgLevel)
            
            // Center icon with MASSIVE pulsing
            Image(systemName: "music.note")
                .font(.system(size: 55))
                .foregroundStyle(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color.white,
                            Color.cyan,
                            Color.blue
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .shadow(color: Color.cyan, radius: 20, x: 0, y: 0)
                .shadow(color: Color.blue, radius: 30, x: 0, y: 0)
                .shadow(color: Color.purple, radius: 40, x: 0, y: 0)
                .scaleEffect(0.9 + avgLevel * 0.5) // HUGE icon pulse
                .rotationEffect(.degrees(avgLevel * 10)) // Slight rotation with music!
                .animation(.easeOut(duration: 0.1), value: avgLevel)
        }
        .frame(width: 280, height: 280)
    }
    
    private func getLevelForBar(_ index: Int) -> CGFloat {
        let levelIndex = index % levels.count
        return levels[levelIndex]
    }
}

