import SwiftUI

struct WaveformView: View {
    let levels: [CGFloat]
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background glow
                WavePath(levels: levels, phase: 0)
                    .stroke(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color.cyan.opacity(0.3),
                                Color.blue.opacity(0.4),
                                Color.purple.opacity(0.3)
                            ]),
                            startPoint: .leading,
                            endPoint: .trailing
                        ),
                        style: StrokeStyle(lineWidth: 30, lineCap: .round, lineJoin: .round)
                    )
                    .blur(radius: 20)
                
                // Main wave - top half
                WavePath(levels: levels, phase: 0)
                    .stroke(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color.cyan,
                                Color.blue,
                                Color.purple
                            ]),
                            startPoint: .leading,
                            endPoint: .trailing
                        ),
                        style: StrokeStyle(lineWidth: 4, lineCap: .round, lineJoin: .round)
                    )
                    .shadow(color: Color.cyan, radius: 10)
                    .shadow(color: Color.blue, radius: 15)
                
                // Mirror wave - bottom half
                WavePath(levels: levels, phase: 0)
                    .stroke(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color.cyan.opacity(0.7),
                                Color.blue.opacity(0.7),
                                Color.purple.opacity(0.7)
                            ]),
                            startPoint: .leading,
                            endPoint: .trailing
                        ),
                        style: StrokeStyle(lineWidth: 4, lineCap: .round, lineJoin: .round)
                    )
                    .scaleEffect(x: 1, y: -1)
                    .shadow(color: Color.cyan.opacity(0.5), radius: 10)
            }
        }
        .frame(height: 120)
    }
}

struct WavePath: Shape {
    let levels: [CGFloat]
    let phase: Double
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let width = rect.width
        let height = rect.height
        let midHeight = height / 2
        
        let pointCount = 60
        let segmentWidth = width / CGFloat(pointCount - 1)
        
        path.move(to: CGPoint(x: 0, y: midHeight))
        
        for i in 0..<pointCount {
            let x = CGFloat(i) * segmentWidth
            
            // Get audio level for this point
            let levelIndex = (i * levels.count) / pointCount
            let level = levels[min(levelIndex, levels.count - 1)]
            
            // Create smooth wave with audio levels
            let waveOffset = sin(Double(i) * 0.3 + phase) * 8 * Double(level)
            let audioOffset = Double(level) * 40
            
            let y = midHeight - CGFloat(waveOffset + audioOffset)
            
            if i == 0 {
                path.move(to: CGPoint(x: x, y: y))
            } else {
                // Create smooth curves between points
                let previousX = CGFloat(i - 1) * segmentWidth
                let controlPoint1 = CGPoint(x: previousX + segmentWidth / 3, y: path.currentPoint?.y ?? y)
                let controlPoint2 = CGPoint(x: x - segmentWidth / 3, y: y)
                path.addCurve(to: CGPoint(x: x, y: y), control1: controlPoint1, control2: controlPoint2)
            }
        }
        
        return path
    }
}

// Legacy bar view for reference
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

struct SiriWaveformView: View {
    let levels: [CGFloat]
    @State private var phase: Double = 0
    
    var body: some View {
        let avgLevel = levels.reduce(0, +) / CGFloat(levels.count)
        
        ZStack {
            // Outer glow effect
            Ellipse()
                .fill(
                    RadialGradient(
                        gradient: Gradient(colors: [
                            Color.cyan.opacity(0.3 + avgLevel * 0.3),
                            Color.blue.opacity(0.2 + avgLevel * 0.2),
                            Color.clear
                        ]),
                        center: .center,
                        startRadius: 50,
                        endRadius: 150
                    )
                )
                .frame(width: 300, height: 200)
                .blur(radius: 30)
                .animation(.easeOut(duration: 0.1), value: avgLevel)
            
            // Multiple wave layers for depth
            ForEach(0..<5) { layer in
                SmoothWavePath(levels: levels, phase: phase + Double(layer) * 0.5, amplitude: 1.0 - Double(layer) * 0.15)
                    .stroke(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color.cyan.opacity(0.8 - Double(layer) * 0.15),
                                Color.blue.opacity(0.9 - Double(layer) * 0.15),
                                Color.purple.opacity(0.8 - Double(layer) * 0.15)
                            ]),
                            startPoint: .leading,
                            endPoint: .trailing
                        ),
                        style: StrokeStyle(
                            lineWidth: CGFloat(6 - layer),
                            lineCap: .round,
                            lineJoin: .round
                        )
                    )
                    .frame(width: 280, height: 150)
                    .shadow(color: Color.cyan.opacity(0.6), radius: 15)
                    .shadow(color: Color.blue.opacity(0.4), radius: 25)
                    .opacity(0.9 - Double(layer) * 0.1)
            }
            
            // Mirrored waves for symmetry
            ForEach(0..<5) { layer in
                SmoothWavePath(levels: levels, phase: phase + Double(layer) * 0.5, amplitude: 1.0 - Double(layer) * 0.15)
                    .stroke(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color.cyan.opacity(0.5 - Double(layer) * 0.1),
                                Color.blue.opacity(0.6 - Double(layer) * 0.1),
                                Color.purple.opacity(0.5 - Double(layer) * 0.1)
                            ]),
                            startPoint: .leading,
                            endPoint: .trailing
                        ),
                        style: StrokeStyle(
                            lineWidth: CGFloat(6 - layer),
                            lineCap: .round,
                            lineJoin: .round
                        )
                    )
                    .frame(width: 280, height: 150)
                    .scaleEffect(x: 1, y: -1)
                    .opacity(0.6 - Double(layer) * 0.08)
            }
        }
        .frame(width: 300, height: 200)
        .onAppear {
            withAnimation(.linear(duration: 2).repeatForever(autoreverses: false)) {
                phase = .pi * 2
            }
        }
    }
}

struct SmoothWavePath: Shape {
    let levels: [CGFloat]
    let phase: Double
    let amplitude: Double
    
    var animatableData: Double {
        get { phase }
        set { }
    }
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let width = rect.width
        let height = rect.height
        let midHeight = height / 2
        
        let pointCount = 80
        let segmentWidth = width / CGFloat(pointCount - 1)
        
        for i in 0..<pointCount {
            let x = CGFloat(i) * segmentWidth
            let progress = Double(i) / Double(pointCount)
            
            // Get audio level for this point
            let levelIndex = (i * levels.count) / pointCount
            let level = levels[min(levelIndex, levels.count - 1)]
            
            // Create flowing sine wave
            let wave1 = sin(progress * .pi * 3 + phase) * 15
            let wave2 = sin(progress * .pi * 5 + phase * 1.3) * 10
            let wave3 = sin(progress * .pi * 7 + phase * 0.7) * 5
            
            // Combine waves with audio level
            let waveOffset = (wave1 + wave2 + wave3) * amplitude
            let audioOffset = Double(level) * 50 * amplitude
            
            let y = midHeight + CGFloat(waveOffset) - CGFloat(audioOffset)
            
            if i == 0 {
                path.move(to: CGPoint(x: x, y: y))
            } else {
                // Smooth curve
                let previousX = CGFloat(i - 1) * segmentWidth
                let previousPoint = path.currentPoint ?? CGPoint(x: previousX, y: midHeight)
                let controlPoint1 = CGPoint(x: previousX + segmentWidth / 2, y: previousPoint.y)
                let controlPoint2 = CGPoint(x: x - segmentWidth / 2, y: y)
                path.addCurve(to: CGPoint(x: x, y: y), control1: controlPoint1, control2: controlPoint2)
            }
        }
        
        return path
    }
}

