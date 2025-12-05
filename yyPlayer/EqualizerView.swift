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
    let barCount: Int = 20
    
    var body: some View {
        ZStack {
            // Outer glow circle
            Circle()
                .fill(
                    RadialGradient(
                        gradient: Gradient(colors: [
                            Color.cyan.opacity(0.3),
                            Color.blue.opacity(0.2),
                            Color.clear
                        ]),
                        center: .center,
                        startRadius: 50,
                        endRadius: 100
                    )
                )
                .frame(width: 200, height: 200)
            
            // Circular bars
            ForEach(0..<barCount, id: \.self) { index in
                RoundedRectangle(cornerRadius: 2)
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
                    .frame(width: 4, height: 15 + getLevelForBar(index) * 25)
                    .offset(y: -50)
                    .rotationEffect(.degrees(Double(index) * (360.0 / Double(barCount))))
                    .shadow(color: Color.cyan.opacity(0.6), radius: 3, x: 0, y: 0)
                    .animation(.spring(response: 0.3, dampingFraction: 0.6), value: getLevelForBar(index))
            }
            
            // Center icon
            Image(systemName: "music.note")
                .font(.system(size: 50))
                .foregroundStyle(
                    LinearGradient(
                        gradient: Gradient(colors: [Color.cyan, Color.blue, Color.purple]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .shadow(color: Color.cyan.opacity(0.5), radius: 10, x: 0, y: 5)
        }
        .frame(width: 200, height: 200)
    }
    
    private func getLevelForBar(_ index: Int) -> CGFloat {
        let levelIndex = index % levels.count
        return levels[levelIndex]
    }
}

