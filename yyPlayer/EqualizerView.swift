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
    let audioLevel: CGFloat
    @State private var phase: Double = 0
    
    var body: some View {
        ZStack {
            // Outer glow effect
            Ellipse()
                .fill(
                    RadialGradient(
                        gradient: Gradient(colors: [
                            Color.cyan.opacity(0.3 + audioLevel * 0.2),
                            Color.blue.opacity(0.2 + audioLevel * 0.15),
                            Color.clear
                        ]),
                        center: .center,
                        startRadius: 50,
                        endRadius: 150
                    )
                )
                .frame(width: 300, height: 200)
                .blur(radius: 30)
            
            // Multiple wave layers for depth
            ForEach(0..<5) { layer in
                SmoothWavePath(
                    audioLevel: audioLevel,
                    phase: phase + Double(layer) * 0.5,
                    amplitude: 1.0 - Double(layer) * 0.15,
                    frequency: 2.0 + Double(layer) * 0.5
                )
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
                SmoothWavePath(
                    audioLevel: audioLevel,
                    phase: phase + Double(layer) * 0.5,
                    amplitude: 1.0 - Double(layer) * 0.15,
                    frequency: 2.0 + Double(layer) * 0.5
                )
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
            withAnimation(.linear(duration: 3).repeatForever(autoreverses: false)) {
                phase = .pi * 2
            }
        }
    }
}

struct SmoothWavePath: Shape {
    let audioLevel: CGFloat
    let phase: Double
    let amplitude: Double
    let frequency: Double
    
    var animatableData: Double {
        get { phase }
        set { }
    }
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let width = rect.width
        let height = rect.height
        let midHeight = height / 2
        
        let pointCount = 100
        let segmentWidth = width / CGFloat(pointCount - 1)
        
        // Create continuous smooth wave
        for i in 0..<pointCount {
            let x = CGFloat(i) * segmentWidth
            let progress = Double(i) / Double(pointCount - 1)
            
            // Create smooth flowing sine waves
            let wave = sin(progress * .pi * frequency + phase) * 20 * amplitude
            
            // Audio level affects the amplitude smoothly across entire wave
            let audioAmplitude = Double(audioLevel) * 30 * amplitude
            
            let y = midHeight + CGFloat(wave) * CGFloat(1.0 + audioLevel * 0.5)
            
            if i == 0 {
                path.move(to: CGPoint(x: x, y: y))
            } else {
                // Create very smooth bezier curves
                let previousX = CGFloat(i - 1) * segmentWidth
                let previousPoint = path.currentPoint ?? CGPoint(x: previousX, y: midHeight)
                
                // Control points for smooth curves
                let controlPoint1X = previousX + segmentWidth * 0.4
                let controlPoint2X = x - segmentWidth * 0.4
                
                let controlPoint1 = CGPoint(x: controlPoint1X, y: previousPoint.y)
                let controlPoint2 = CGPoint(x: controlPoint2X, y: y)
                
                path.addCurve(to: CGPoint(x: x, y: y), control1: controlPoint1, control2: controlPoint2)
            }
        }
        
        return path
    }
}

