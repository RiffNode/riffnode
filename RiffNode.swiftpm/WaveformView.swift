import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

// MARK: - Visualization Views
// Liquid Glass UI Design - iOS 26+

// MARK: - Liquid Waveform View (High-Performance Canvas)

struct WaveformView: View {
    let samples: [Float]
    var color: Color = .cyan
    var showMirror: Bool = true
    
    // Calculate max amplitude for dynamic coloring
    private var amplitude: Float {
        samples.max() ?? 0
    }
    
    var body: some View {
        Canvas { context, size in
            guard !samples.isEmpty else { return }
            
            let midY = size.height / 2
            let width = size.width
            let step = width / CGFloat(max(samples.count - 1, 1))
            
            var path = Path()
            path.move(to: CGPoint(x: 0, y: midY))
            
            // Draw smooth curve using Bezier (Liquid feel)
            for (index, sample) in samples.enumerated() {
                let x = CGFloat(index) * step
                let y = midY - (CGFloat(sample) * (size.height / 2))
                
                if index == 0 {
                    path.addLine(to: CGPoint(x: x, y: y))
                } else {
                    let prevX = CGFloat(index - 1) * step
                    let prevSample = samples[index - 1]
                    let prevY = midY - (CGFloat(prevSample) * (size.height / 2))
                    
                    // Control points for smooth Bezier
                    let ctrl1 = CGPoint(x: (prevX + x) / 2, y: prevY)
                    let ctrl2 = CGPoint(x: (prevX + x) / 2, y: y)
                    
                    path.addCurve(to: CGPoint(x: x, y: y), control1: ctrl1, control2: ctrl2)
                }
            }
            
            // Mirror path for bottom half
            var fullPath = path
            var bottomPath = Path()
            bottomPath.move(to: CGPoint(x: width, y: midY))
            
            // Reverse loop for bottom mirror
            for index in (0..<samples.count).reversed() {
                let x = CGFloat(index) * step
                let y = midY + (CGFloat(samples[index]) * (size.height / 2))
                
                if index == samples.count - 1 {
                    bottomPath.addLine(to: CGPoint(x: x, y: y))
                } else {
                    let nextX = CGFloat(index + 1) * step
                    let nextSample = samples[index + 1]
                    let nextY = midY + (CGFloat(nextSample) * (size.height / 2))
                    
                    let ctrl1 = CGPoint(x: (nextX + x) / 2, y: nextY)
                    let ctrl2 = CGPoint(x: (nextX + x) / 2, y: y)
                    
                    bottomPath.addCurve(to: CGPoint(x: x, y: y), control1: ctrl1, control2: ctrl2)
                }
            }
            fullPath.addPath(bottomPath)
            fullPath.closeSubpath()
            
            // Dark glass fill with gradient
            context.fill(
                fullPath,
                with: .linearGradient(
                    Gradient(colors: [
                        Color(white: 0.2, opacity: 0.4),
                        Color(white: 0.3, opacity: 0.7),
                        Color(white: 0.2, opacity: 0.4)
                    ]),
                    startPoint: CGPoint(x: 0, y: 0),
                    endPoint: CGPoint(x: 0, y: size.height)
                )
            )

            // Edge glow stroke - darker, more visible
            context.stroke(
                fullPath,
                with: .linearGradient(
                    Gradient(colors: [
                        Color(white: 0.4, opacity: 0.6),
                        Color(white: 0.6, opacity: 1.0),
                        Color(white: 0.4, opacity: 0.6)
                    ]),
                    startPoint: CGPoint(x: 0, y: 0),
                    endPoint: CGPoint(x: width, y: 0)
                ),
                lineWidth: 2
            )

            // Center line - subtle
            var centerLine = Path()
            centerLine.move(to: CGPoint(x: 0, y: midY))
            centerLine.addLine(to: CGPoint(x: width, y: midY))
            context.stroke(centerLine, with: .color(Color(white: 0.5, opacity: 0.2)), style: StrokeStyle(lineWidth: 1, dash: [4, 4]))
        }
    }
}

// MARK: - Pro Level Meter View (Peak Hold)

struct LevelMeterView: View {
    let level: Float
    var label: String = "Level"
    var color: Color = .white  // Neutral default
    
    // Peak hold state
    @State private var peakLevel: CGFloat = 0
    
    private var normalizedLevel: CGFloat {
        CGFloat(min(max(level * 3, 0), 1))
    }
    
    var body: some View {
        VStack(spacing: 6) {
            Text(label)
                .font(.system(size: 9, weight: .bold))
                .foregroundStyle(.tertiary)
            
            GeometryReader { geo in
                ZStack(alignment: .bottom) {
                    // Glass Track
                    RoundedRectangle(cornerRadius: 4)
                        .fill(.white.opacity(0.1))
                    
                    // Active Level (Pure neutral white gradient)
                    RoundedRectangle(cornerRadius: 4)
                        .fill(
                            LinearGradient(
                                stops: [
                                    .init(color: .white.opacity(0.4), location: 0.0),
                                    .init(color: .white.opacity(0.7), location: 0.6),
                                    .init(color: .white.opacity(0.9), location: 1.0)
                                ],
                                startPoint: .bottom,
                                endPoint: .top
                            )
                        )
                        .frame(height: geo.size.height * normalizedLevel)
                        .animation(.interpolatingSpring(stiffness: 300, damping: 20), value: normalizedLevel)
                    
                    // Peak Hold Indicator (Ghost line)
                    if peakLevel > 0.01 {
                        Rectangle()
                            .fill(.white.opacity(0.9))
                            .frame(height: 2)
                            .offset(y: -geo.size.height * peakLevel + 2)
                            .frame(maxHeight: .infinity, alignment: .bottom)
                    }
                    
                    // Subtle segment markers
                    VStack(spacing: 0) {
                        ForEach(0..<8, id: \.self) { _ in
                            Spacer()
                            Rectangle()
                                .fill(Color.white.opacity(0.05))
                                .frame(height: 1)
                        }
                    }
                    
                    // Clip indicator
                    if normalizedLevel > 0.95 {
                        VStack {
                            RoundedRectangle(cornerRadius: 2)
                                .fill(Color.white)
                                .frame(height: 3)
                                .shadow(color: .white.opacity(0.6), radius: 4)
                            Spacer()
                        }
                    }
                }
                .onChange(of: normalizedLevel) { oldValue, newValue in
                    updatePeak(newLevel: newValue)
                }
            }
            .frame(width: 14) // Thinner, more elegant
            .clipShape(RoundedRectangle(cornerRadius: 4))
            .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 4))
            
            // dB label
            Text(String(format: "%.0f", 20 * log10(max(level, 0.001))))
                .font(.system(size: 8, weight: .semibold).monospacedDigit())
                .foregroundStyle(.secondary)
        }
    }
    
    private func updatePeak(newLevel: CGFloat) {
        if newLevel > peakLevel {
            // Immediate push up
            withAnimation(.easeOut(duration: 0.05)) {
                peakLevel = newLevel
            }
        } else {
            // Slow decay after a hold
            withAnimation(.linear(duration: 1.5).delay(0.3)) {
                peakLevel = newLevel
            }
        }
    }
}

// MARK: - Audio Visualization Panel

struct AudioVisualizationPanel: View {
    @Bindable var engine: AudioEngineManager
    @State private var visualizationMode: VisualizationMode = .waveform

    enum VisualizationMode: String, CaseIterable {
        case waveform = "Waveform"
        case bars = "Bars"
        case circular = "Circular"

        var icon: String {
            switch self {
            case .waveform: return "waveform"
            case .bars: return "chart.bar.fill"
            case .circular: return "circle.hexagongrid.fill"
            }
        }
    }

    var body: some View {
        GlassCard(cornerRadius: 16) {
            VStack(spacing: 12) {
                // Header
                HStack {
                    HStack(spacing: 8) {
                        Image(systemName: "waveform.circle.fill")
                            .foregroundStyle(.secondary)
                        Text("Visualizer")
                            .font(.headline)
                    }

                    Spacer()

                    // Glass segment slider for mode selection
                    GlassSegmentSlider(
                        selection: $visualizationMode,
                        options: VisualizationMode.allCases
                    ) { mode in
                        Image(systemName: mode.icon)
                            .font(.system(size: 12, weight: .semibold))
                    }
                    .frame(width: 120)
                }

                // Visualization content
                HStack(spacing: 12) {
                    // Input level meter
                    LevelMeterView(level: engine.inputLevel, label: "IN")

                    // Main visualization
                    ZStack {
                        // Subtle dark glass background for visualization area
                        RoundedRectangle(cornerRadius: 12)
                            .fill(.black.opacity(0.15))
                            .overlay {
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(.white.opacity(0.1), lineWidth: 1)
                            }

                        // Visualization
                        Group {
                            switch visualizationMode {
                            case .waveform:
                                WaveformView(samples: engine.waveformSamples)
                                    .padding(8)
                            case .bars:
                                BarVisualizationView(samples: engine.waveformSamples)
                            case .circular:
                                CircularVisualizationView(samples: engine.waveformSamples)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .overlay {
                        RoundedRectangle(cornerRadius: 12)
                            .strokeBorder(.white.opacity(0.1), lineWidth: 1)
                    }

                    // Output level meter
                    LevelMeterView(level: engine.outputLevel, label: "OUT")
                }
                .frame(height: 140)
            }
        }
    }
    
    // Haptic feedback for mode switching
    private func triggerHaptic() {
        #if os(iOS)
        let impact = UIImpactFeedbackGenerator(style: .light)
        impact.impactOccurred()
        #endif
    }
}

// MARK: - Bar Visualization

struct BarVisualizationView: View {
    let samples: [Float]

    private func getBarSamples() -> [Float] {
        let barCount = 32
        guard !samples.isEmpty else {
            return [Float](repeating: 0, count: barCount)
        }

        if samples.count >= barCount {
            let samplesPerBar = samples.count / barCount
            var result: [Float] = []
            for i in 0..<barCount {
                let start = i * samplesPerBar
                let end = min(start + samplesPerBar, samples.count)
                let maxVal = samples[start..<end].max() ?? 0
                result.append(maxVal)
            }
            return result
        } else {
            var result = [Float](repeating: 0, count: barCount)
            for (i, sample) in samples.enumerated() {
                let barIdx = (i * barCount) / samples.count
                if barIdx < barCount {
                    result[barIdx] = max(result[barIdx], sample)
                }
            }
            return result
        }
    }

    var body: some View {
        GeometryReader { geometry in
            let barSamples = getBarSamples()
            let barCount = barSamples.count

            HStack(alignment: .center, spacing: 3) {
                ForEach(Array(barSamples.enumerated()), id: \.offset) { index, sample in
                    let height = CGFloat(sample) * geometry.size.height * 0.85 + 4
                    // Dark grey gradient with subtle variation
                    let brightness = 0.3 + (Double(index) / Double(max(barCount, 1))) * 0.15

                    VStack(spacing: 0) {
                        Spacer()
                        RoundedRectangle(cornerRadius: 2)
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color(white: brightness + 0.2, opacity: 0.9),
                                        Color(white: brightness, opacity: 0.7)
                                    ],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .overlay {
                                // Specular highlight on each bar
                                RoundedRectangle(cornerRadius: 2)
                                    .fill(
                                        LinearGradient(
                                            colors: [.white.opacity(0.3), .clear],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                            }
                            .frame(height: height)
                        Spacer()
                    }
                }
            }
            .padding(.horizontal, 8)
        }
    }
}

// MARK: - Circular Visualization

struct CircularVisualizationView: View {
    let samples: [Float]

    private func getReducedSamples() -> [Float] {
        let targetCount = 64

        guard !samples.isEmpty else {
            return [Float](repeating: 0, count: targetCount)
        }

        if samples.count >= targetCount {
            let samplesPerPoint = samples.count / targetCount
            var result: [Float] = []
            for i in 0..<targetCount {
                let start = i * samplesPerPoint
                let end = min(start + samplesPerPoint, samples.count)
                let maxVal = samples[start..<end].max() ?? 0
                result.append(maxVal)
            }
            return result
        } else {
            var result = samples
            while result.count < targetCount {
                result.append(0)
            }
            return result
        }
    }

    var body: some View {
        Canvas { context, size in
            let centerX: CGFloat = size.width / 2
            let centerY: CGFloat = size.height / 2
            let radius: CGFloat = min(size.width, size.height) / 2 - 20
            let reducedSamples = getReducedSamples()
            let sampleCount = max(reducedSamples.count, 1)

            guard !reducedSamples.isEmpty else { return }

            // Draw connecting lines for a more cohesive look
            var outerPath = Path()

            for index in 0..<reducedSamples.count {
                let sample = reducedSamples[index]
                let angle: Double = (Double(index) / Double(sampleCount)) * 2.0 * .pi - .pi / 2.0
                let innerRadius: CGFloat = radius * 0.35
                let outerRadius: CGFloat = innerRadius + CGFloat(sample) * radius * 0.6 + 8

                let cosAngle = cos(angle)
                let sinAngle = sin(angle)

                let startX: CGFloat = centerX + cosAngle * innerRadius
                let startY: CGFloat = centerY + sinAngle * innerRadius
                let endX: CGFloat = centerX + cosAngle * outerRadius
                let endY: CGFloat = centerY + sinAngle * outerRadius

                // Draw bar - dark grey with subtle variation
                var barPath = Path()
                barPath.move(to: CGPoint(x: startX, y: startY))
                barPath.addLine(to: CGPoint(x: endX, y: endY))

                let brightness = 0.35 + (Double(index) / Double(sampleCount)) * 0.2
                let color = Color(white: brightness, opacity: 0.9)
                context.stroke(barPath, with: .color(color), lineWidth: 3)

                // Build outer path
                if index == 0 {
                    outerPath.move(to: CGPoint(x: endX, y: endY))
                } else {
                    outerPath.addLine(to: CGPoint(x: endX, y: endY))
                }
            }

            // Close outer path
            outerPath.closeSubpath()

            // Draw filled area with subtle dark color
            context.fill(
                outerPath,
                with: .color(Color(white: 0.3, opacity: 0.15))
            )

            // Center circle with glass effect simulation
            let innerGlowRect = CGRect(x: centerX - 25, y: centerY - 25, width: 50, height: 50)
            let innerGlow = Path(ellipseIn: innerGlowRect)
            context.fill(innerGlow, with: .color(Color(white: 0.4, opacity: 0.2)))

            let circleRect = CGRect(x: centerX - 15, y: centerY - 15, width: 30, height: 30)
            let centerCircle = Path(ellipseIn: circleRect)
            context.fill(centerCircle, with: .color(Color(white: 0.5, opacity: 0.6)))

            let innerCircleRect = CGRect(x: centerX - 8, y: centerY - 8, width: 16, height: 16)
            let innerCircle = Path(ellipseIn: innerCircleRect)
            context.fill(innerCircle, with: .color(Color(white: 0.2, opacity: 0.5)))
        }
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        AdaptiveBackground()

        VStack(spacing: 20) {
            AudioVisualizationPanel(engine: AudioEngineManager())
                .frame(height: 220)

            HStack(spacing: 20) {
                WaveformView(samples: (0..<128).map { _ in Float.random(in: 0...0.8) })
                    .frame(height: 80)
                    .glassCard(cornerRadius: 12, padding: 8)

                BarVisualizationView(samples: (0..<128).map { _ in Float.random(in: 0...0.8) })
                    .frame(height: 80)
                    .glassCard(cornerRadius: 12, padding: 8)
            }

            CircularVisualizationView(samples: (0..<128).map { _ in Float.random(in: 0...0.8) })
                .frame(height: 180)
                .glassCard(cornerRadius: 12, padding: 8)
        }
        .padding()
    }
}
