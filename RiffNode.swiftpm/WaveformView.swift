import SwiftUI
import Charts

// MARK: - Visualization Views
// Liquid Glass UI Design - iOS 26+

// MARK: - Real-time Waveform View

struct WaveformView: View {
    let samples: [Float]
    var color: Color = .cyan
    var showMirror: Bool = true

    private var samplePoints: [WaveformSample] {
        samples.enumerated().map { WaveformSample(id: $0.offset, amplitude: $0.element) }
    }

    var body: some View {
        if samples.isEmpty {
            Rectangle()
                .fill(Color.clear)
        } else {
            Chart {
                ForEach(samplePoints) { sample in
                    AreaMark(
                        x: .value("Sample", sample.id),
                        yStart: .value("Amplitude", showMirror ? -sample.amplitude : 0),
                        yEnd: .value("Amplitude", sample.amplitude)
                    )
                    .foregroundStyle(
                        LinearGradient(
                            colors: [color.opacity(0.8), color.opacity(0.2)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .interpolationMethod(.catmullRom)
                }

                RuleMark(y: .value("Center", 0))
                    .foregroundStyle(color.opacity(0.3))
                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 4]))
            }
            .chartXAxis(.hidden)
            .chartYAxis(.hidden)
            .chartYScale(domain: -1...1)
        }
    }
}

// MARK: - Glass Level Meter View

struct LevelMeterView: View {
    let level: Float
    var label: String = "Level"
    var color: Color = .green

    private var normalizedLevel: CGFloat {
        CGFloat(min(max(level * 3, 0), 1))
    }

    private var meterColor: Color {
        if normalizedLevel > 0.8 {
            return .red
        } else if normalizedLevel > 0.6 {
            return .yellow
        }
        return color
    }

    var body: some View {
        VStack(spacing: 6) {
            Text(label)
                .font(.system(size: 9, weight: .semibold))
                .foregroundStyle(.secondary)

            GeometryReader { geometry in
                ZStack(alignment: .bottom) {
                    // Glass background
                    RoundedRectangle(cornerRadius: 6)
                        .fill(.ultraThinMaterial)

                    // Level indicator with gradient
                    RoundedRectangle(cornerRadius: 6)
                        .fill(
                            LinearGradient(
                                colors: [
                                    meterColor.opacity(0.9),
                                    meterColor.opacity(0.5)
                                ],
                                startPoint: .bottom,
                                endPoint: .top
                            )
                        )
                        .frame(height: geometry.size.height * normalizedLevel)

                    // Subtle segment markers
                    VStack(spacing: 0) {
                        ForEach(0..<10, id: \.self) { _ in
                            Spacer()
                            Rectangle()
                                .fill(Color.white.opacity(0.05))
                                .frame(height: 1)
                        }
                    }

                    // Clip indicator
                    if normalizedLevel > 0.95 {
                        VStack {
                            RoundedRectangle(cornerRadius: 3)
                                .fill(Color.red)
                                .frame(height: 4)
                                .shadow(color: .red.opacity(0.5), radius: 4)
                            Spacer()
                        }
                    }
                }
            }
            .frame(width: 24)
            .clipShape(RoundedRectangle(cornerRadius: 6))

            // dB label
            Text(String(format: "%.0f", 20 * log10(max(level, 0.001))))
                .font(.system(size: 8, weight: .semibold).monospacedDigit())
                .foregroundStyle(meterColor)
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
        GlassCard(tint: .cyan, cornerRadius: 16) {
            VStack(spacing: 12) {
                // Header
                HStack {
                    HStack(spacing: 8) {
                        Image(systemName: "waveform.circle.fill")
                            .foregroundStyle(.cyan)
                        Text("Visualizer")
                            .font(.headline)
                    }

                    Spacer()

                    // Mode picker with glass pills
                    GlassEffectContainer(spacing: 2) {
                        ForEach(VisualizationMode.allCases, id: \.self) { mode in
                            Button {
                                withAnimation(.spring(duration: 0.25)) {
                                    visualizationMode = mode
                                }
                            } label: {
                                Image(systemName: mode.icon)
                                    .font(.system(size: 12, weight: .medium))
                                    .frame(width: 32, height: 28)
                                    .foregroundStyle(
                                        visualizationMode == mode ? .cyan : .secondary
                                    )
                            }
                            .glassEffect(
                                visualizationMode == mode ? .regular.tint(.cyan) : .clear,
                                in: RoundedRectangle(cornerRadius: 6)
                            )
                            .buttonStyle(.plain)
                        }
                    }
                }

                // Visualization content
                HStack(spacing: 12) {
                    // Input level meter
                    LevelMeterView(level: engine.inputLevel, label: "IN", color: .green)

                    // Main visualization
                    ZStack {
                        // Glass background for visualization area
                        RoundedRectangle(cornerRadius: 12)
                            .fill(.black.opacity(0.3))

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
                    LevelMeterView(level: engine.outputLevel, label: "OUT", color: .cyan)
                }
                .frame(height: 140)
            }
        }
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
                    let hue = 0.5 + (Double(index) / Double(max(barCount, 1))) * 0.15

                    VStack(spacing: 0) {
                        Spacer()
                        RoundedRectangle(cornerRadius: 2)
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color(hue: hue, saturation: 0.7, brightness: 0.95),
                                        Color(hue: hue, saturation: 0.8, brightness: 0.7)
                                    ],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
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

                // Draw bar
                var barPath = Path()
                barPath.move(to: CGPoint(x: startX, y: startY))
                barPath.addLine(to: CGPoint(x: endX, y: endY))

                let hue: Double = Double(index) / Double(sampleCount) * 0.5 + 0.45
                let color = Color(hue: hue, saturation: 0.65, brightness: 0.9)
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

            // Draw filled area with subtle color
            context.fill(
                outerPath,
                with: .color(Color.cyan.opacity(0.08))
            )

            // Center circle with subtle glow
            let innerGlowRect = CGRect(x: centerX - 25, y: centerY - 25, width: 50, height: 50)
            let innerGlow = Path(ellipseIn: innerGlowRect)
            context.fill(innerGlow, with: .color(.cyan.opacity(0.1)))

            let circleRect = CGRect(x: centerX - 15, y: centerY - 15, width: 30, height: 30)
            let centerCircle = Path(ellipseIn: circleRect)
            context.fill(centerCircle, with: .color(.cyan.opacity(0.5)))

            let innerCircleRect = CGRect(x: centerX - 8, y: centerY - 8, width: 16, height: 16)
            let innerCircle = Path(ellipseIn: innerCircleRect)
            context.fill(innerCircle, with: .color(.black.opacity(0.4)))
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
