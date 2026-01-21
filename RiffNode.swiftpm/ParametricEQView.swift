import SwiftUI

// MARK: - Parametric EQ View
// GarageBand-inspired parametric equalizer with smooth curves and professional look

struct ParametricEQView: View {
    @Bindable var engine: AudioEngineManager
    @State private var selectedBand: Int? = nil
    @State private var bands: [EQBand] = EQBand.defaultBands
    @State private var isAnalyzerActive = true

    var body: some View {
        VStack(spacing: 0) {
            // Header with analyzer toggle
            GarageBandEQHeader(
                isAnalyzerActive: $isAnalyzerActive,
                onReset: { bands = EQBand.defaultBands }
            )

            // Main EQ Display - GarageBand style
            ZStack {
                // Dark gradient background like GarageBand
                LinearGradient(
                    colors: [
                        Color(red: 0.05, green: 0.05, blue: 0.08),
                        Color(red: 0.08, green: 0.08, blue: 0.12)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )

                // Spectrum analyzer background (if active)
                if isAnalyzerActive {
                    SpectrumAnalyzerView()
                        .opacity(0.4)
                }

                // Grid with GarageBand styling
                GarageBandGridView()

                // Smooth frequency response curve with fill
                GarageBandCurveView(bands: bands, selectedBand: selectedBand)

                // Draggable band nodes
                GarageBandBandNodes(
                    bands: $bands,
                    selectedBand: $selectedBand
                )
            }
            .frame(height: 280)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .strokeBorder(Color.white.opacity(0.1), lineWidth: 1)
            )

            // Band selector strip
            GarageBandBandStrip(bands: $bands, selectedBand: $selectedBand)

            // Selected band controls
            if let selected = selectedBand {
                GarageBandBandControls(band: $bands[selected])
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(red: 0.1, green: 0.1, blue: 0.12))
                .shadow(color: .black.opacity(0.3), radius: 10, y: 5)
        )
        .animation(.spring(duration: 0.25), value: selectedBand)
    }
}

// MARK: - GarageBand EQ Header

struct GarageBandEQHeader: View {
    @Binding var isAnalyzerActive: Bool
    let onReset: () -> Void

    var body: some View {
        HStack {
            // EQ Icon and title
            HStack(spacing: 8) {
                ZStack {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(LinearGradient(
                            colors: [.green, .green.opacity(0.7)],
                            startPoint: .top,
                            endPoint: .bottom
                        ))
                        .frame(width: 24, height: 24)

                    Image(systemName: "slider.horizontal.3")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(.black)
                }

                Text("EQ")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(.white)
            }

            Spacer()

            // Analyzer toggle
            Button {
                isAnalyzerActive.toggle()
            } label: {
                HStack(spacing: 4) {
                    Circle()
                        .fill(isAnalyzerActive ? Color.green : Color.gray)
                        .frame(width: 6, height: 6)
                    Text("Analyzer")
                        .font(.system(size: 11, weight: .medium))
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.white.opacity(0.1))
                .clipShape(Capsule())
            }
            .buttonStyle(.plain)
            .foregroundStyle(isAnalyzerActive ? .green : .secondary)

            // Reset button
            Button {
                onReset()
            } label: {
                Text("Reset")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.white.opacity(0.05))
                    .clipShape(Capsule())
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
    }
}

// MARK: - Spectrum Analyzer View

struct SpectrumAnalyzerView: View {
    @State private var levels: [CGFloat] = Array(repeating: 0, count: 32)

    var body: some View {
        TimelineView(.animation(minimumInterval: 0.05)) { _ in
            GeometryReader { geometry in
                HStack(spacing: 2) {
                    ForEach(0..<32, id: \.self) { index in
                        let height = generateBarHeight(index: index)

                        RoundedRectangle(cornerRadius: 1)
                            .fill(
                                LinearGradient(
                                    colors: [.green.opacity(0.8), .green.opacity(0.3)],
                                    startPoint: .bottom,
                                    endPoint: .top
                                )
                            )
                            .frame(height: height * geometry.size.height * 0.8)
                            .frame(maxHeight: .infinity, alignment: .bottom)
                    }
                }
                .padding(.horizontal, 30)
                .padding(.bottom, 20)
            }
        }
    }

    private func generateBarHeight(index: Int) -> CGFloat {
        // Simulate frequency-weighted levels
        let baseLevel = CGFloat.random(in: 0.1...0.6)
        let frequencyWeight: CGFloat
        if index < 8 {
            frequencyWeight = 0.8 // Bass frequencies
        } else if index < 20 {
            frequencyWeight = 1.0 // Mid frequencies
        } else {
            frequencyWeight = 0.5 // High frequencies
        }
        return baseLevel * frequencyWeight
    }
}

// MARK: - GarageBand Grid View

struct GarageBandGridView: View {
    let frequencies: [Float] = [30, 60, 125, 250, 500, 1000, 2000, 4000, 8000, 16000]
    let gains: [Float] = [-24, -18, -12, -6, 0, 6, 12, 18, 24]

    var body: some View {
        GeometryReader { geometry in
            let width = geometry.size.width
            let height = geometry.size.height

            ZStack {
                // Vertical frequency lines
                ForEach(frequencies, id: \.self) { freq in
                    let x = frequencyToX(freq, width: width)

                    Path { path in
                        path.move(to: CGPoint(x: x, y: 0))
                        path.addLine(to: CGPoint(x: x, y: height))
                    }
                    .stroke(Color.white.opacity(0.08), lineWidth: 1)

                    // Frequency label at bottom
                    Text(formatFrequency(freq))
                        .font(.system(size: 8, weight: .medium, design: .monospaced))
                        .foregroundStyle(.white.opacity(0.35))
                        .position(x: x, y: height - 8)
                }

                // Horizontal gain lines
                ForEach(gains, id: \.self) { gain in
                    let y = gainToY(gain, height: height)

                    Path { path in
                        path.move(to: CGPoint(x: 25, y: y))
                        path.addLine(to: CGPoint(x: width - 5, y: y))
                    }
                    .stroke(
                        gain == 0 ? Color.white.opacity(0.25) : Color.white.opacity(0.06),
                        lineWidth: gain == 0 ? 1 : 0.5
                    )

                    // Gain label on left
                    if gain == 0 || abs(gain) == 12 || abs(gain) == 24 {
                        Text("\(gain > 0 ? "+" : "")\(Int(gain))")
                            .font(.system(size: 8, weight: .medium, design: .monospaced))
                            .foregroundStyle(.white.opacity(0.35))
                            .position(x: 12, y: y)
                    }
                }
            }
        }
    }

    private func formatFrequency(_ freq: Float) -> String {
        if freq >= 1000 {
            return "\(Int(freq / 1000))k"
        }
        return "\(Int(freq))"
    }

    private func frequencyToX(_ freq: Float, width: CGFloat) -> CGFloat {
        let minFreq: Float = 20
        let maxFreq: Float = 20000
        let logMin = log10(minFreq)
        let logMax = log10(maxFreq)
        let logFreq = log10(max(freq, minFreq))
        return 30 + CGFloat((logFreq - logMin) / (logMax - logMin)) * (width - 40)
    }

    private func gainToY(_ gain: Float, height: CGFloat) -> CGFloat {
        let minGain: Float = -24
        let maxGain: Float = 24
        return 15 + CGFloat(1 - (gain - minGain) / (maxGain - minGain)) * (height - 35)
    }
}

// MARK: - GarageBand Curve View

struct GarageBandCurveView: View {
    let bands: [EQBand]
    let selectedBand: Int?

    var body: some View {
        GeometryReader { geometry in
            let width = geometry.size.width
            let height = geometry.size.height

            // Gradient fill under curve
            Path { path in
                let zeroY = gainToY(0, height: height)
                path.move(to: CGPoint(x: 30, y: zeroY))

                for x in stride(from: 30, to: width - 10, by: 1) {
                    let freq = xToFrequency(x, width: width)
                    let totalGain = calculateTotalGain(at: freq)
                    let y = gainToY(totalGain, height: height)
                    path.addLine(to: CGPoint(x: x, y: y))
                }

                path.addLine(to: CGPoint(x: width - 10, y: zeroY))
                path.closeSubpath()
            }
            .fill(
                LinearGradient(
                    colors: [
                        Color.green.opacity(0.35),
                        Color.green.opacity(0.05)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )

            // Main curve stroke
            Path { path in
                var started = false
                for x in stride(from: 30, to: width - 10, by: 1) {
                    let freq = xToFrequency(x, width: width)
                    let totalGain = calculateTotalGain(at: freq)
                    let y = gainToY(totalGain, height: height)

                    if !started {
                        path.move(to: CGPoint(x: x, y: y))
                        started = true
                    } else {
                        path.addLine(to: CGPoint(x: x, y: y))
                    }
                }
            }
            .stroke(
                LinearGradient(
                    colors: [.green.opacity(0.9), .green],
                    startPoint: .leading,
                    endPoint: .trailing
                ),
                style: StrokeStyle(lineWidth: 2.5, lineCap: .round, lineJoin: .round)
            )
            .shadow(color: .green.opacity(0.5), radius: 4)

            // Selected band individual curve highlight
            if let selected = selectedBand {
                let band = bands[selected]
                Path { path in
                    var started = false
                    for x in stride(from: 30, to: width - 10, by: 1) {
                        let freq = xToFrequency(x, width: width)
                        let bandGain = calculateBandGain(band, at: freq)
                        let y = gainToY(bandGain, height: height)

                        if !started {
                            path.move(to: CGPoint(x: x, y: y))
                            started = true
                        } else {
                            path.addLine(to: CGPoint(x: x, y: y))
                        }
                    }
                }
                .stroke(band.type.color.opacity(0.6), style: StrokeStyle(lineWidth: 1.5, dash: [4, 4]))
            }
        }
    }

    private func calculateTotalGain(at frequency: Float) -> Float {
        var total: Float = 0
        for band in bands where band.isEnabled {
            total += calculateBandGain(band, at: frequency)
        }
        return max(-24, min(24, total))
    }

    private func calculateBandGain(_ band: EQBand, at frequency: Float) -> Float {
        let ratio = frequency / band.frequency
        let logRatio = log2(ratio)

        switch band.type {
        case .peak:
            let bandwidth = 1.0 / band.q
            let x = logRatio / bandwidth
            return band.gain * exp(-x * x * 2)

        case .lowShelf:
            if frequency < band.frequency {
                return band.gain
            } else {
                let x = logRatio * band.q
                return band.gain * exp(-x * x)
            }

        case .highShelf:
            if frequency > band.frequency {
                return band.gain
            } else {
                let x = -logRatio * band.q
                return band.gain * exp(-x * x)
            }

        case .highPass:
            if frequency < band.frequency {
                let octaves = log2(band.frequency / frequency)
                return -octaves * 12
            }
            return 0

        case .lowPass:
            if frequency > band.frequency {
                let octaves = log2(frequency / band.frequency)
                return -octaves * 12
            }
            return 0
        }
    }

    private func frequencyToX(_ freq: Float, width: CGFloat) -> CGFloat {
        let minFreq: Float = 20
        let maxFreq: Float = 20000
        let logMin = log10(minFreq)
        let logMax = log10(maxFreq)
        let logFreq = log10(max(freq, minFreq))
        return 30 + CGFloat((logFreq - logMin) / (logMax - logMin)) * (width - 40)
    }

    private func xToFrequency(_ x: CGFloat, width: CGFloat) -> Float {
        let minFreq: Float = 20
        let maxFreq: Float = 20000
        let logMin = log10(minFreq)
        let logMax = log10(maxFreq)
        let ratio = Float((x - 30) / (width - 40))
        let logFreq = logMin + ratio * (logMax - logMin)
        return pow(10, logFreq)
    }

    private func gainToY(_ gain: Float, height: CGFloat) -> CGFloat {
        let minGain: Float = -24
        let maxGain: Float = 24
        return 15 + CGFloat(1 - (gain - minGain) / (maxGain - minGain)) * (height - 35)
    }
}

// MARK: - GarageBand Band Nodes

struct GarageBandBandNodes: View {
    @Binding var bands: [EQBand]
    @Binding var selectedBand: Int?

    var body: some View {
        GeometryReader { geometry in
            let width = geometry.size.width
            let height = geometry.size.height

            ForEach(bands.indices, id: \.self) { index in
                let band = bands[index]
                let x = frequencyToX(band.frequency, width: width)
                let y = gainToY(band.gain, height: height)
                let isSelected = selectedBand == index

                ZStack {
                    // Outer glow for selected
                    if isSelected {
                        Circle()
                            .fill(band.type.color.opacity(0.3))
                            .frame(width: 36, height: 36)
                            .blur(radius: 6)
                    }

                    // Main node
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [band.type.color, band.type.color.opacity(0.7)],
                                center: .center,
                                startRadius: 0,
                                endRadius: isSelected ? 12 : 8
                            )
                        )
                        .frame(width: isSelected ? 24 : 16, height: isSelected ? 24 : 16)
                        .overlay(
                            Circle()
                                .strokeBorder(Color.white, lineWidth: isSelected ? 2 : 1)
                        )
                        .shadow(color: band.type.color.opacity(0.6), radius: isSelected ? 8 : 4)

                    // Band number
                    Text("\(index + 1)")
                        .font(.system(size: isSelected ? 10 : 8, weight: .bold))
                        .foregroundStyle(.white)
                }
                .position(x: x, y: y)
                .gesture(
                    DragGesture()
                        .onChanged { value in
                            selectedBand = index
                            let newFreq = xToFrequency(value.location.x, width: width)
                            let newGain = yToGain(value.location.y, height: height)
                            bands[index].frequency = max(20, min(20000, newFreq))
                            bands[index].gain = max(-24, min(24, newGain))
                        }
                )
                .onTapGesture {
                    withAnimation(.spring(duration: 0.2)) {
                        selectedBand = selectedBand == index ? nil : index
                    }
                }
            }
        }
    }

    private func frequencyToX(_ freq: Float, width: CGFloat) -> CGFloat {
        let minFreq: Float = 20
        let maxFreq: Float = 20000
        let logMin = log10(minFreq)
        let logMax = log10(maxFreq)
        let logFreq = log10(max(freq, minFreq))
        return 30 + CGFloat((logFreq - logMin) / (logMax - logMin)) * (width - 40)
    }

    private func xToFrequency(_ x: CGFloat, width: CGFloat) -> Float {
        let minFreq: Float = 20
        let maxFreq: Float = 20000
        let logMin = log10(minFreq)
        let logMax = log10(maxFreq)
        let ratio = Float(max(0, min(x - 30, width - 40)) / (width - 40))
        let logFreq = logMin + ratio * (logMax - logMin)
        return pow(10, logFreq)
    }

    private func gainToY(_ gain: Float, height: CGFloat) -> CGFloat {
        let minGain: Float = -24
        let maxGain: Float = 24
        return 15 + CGFloat(1 - (gain - minGain) / (maxGain - minGain)) * (height - 35)
    }

    private func yToGain(_ y: CGFloat, height: CGFloat) -> Float {
        let minGain: Float = -24
        let maxGain: Float = 24
        let ratio = Float(max(0, min(y - 15, height - 35)) / (height - 35))
        return maxGain - ratio * (maxGain - minGain)
    }
}

// MARK: - GarageBand Band Strip

struct GarageBandBandStrip: View {
    @Binding var bands: [EQBand]
    @Binding var selectedBand: Int?

    var body: some View {
        HStack(spacing: 4) {
            ForEach(bands.indices, id: \.self) { index in
                let band = bands[index]
                let isSelected = selectedBand == index

                Button {
                    withAnimation(.spring(duration: 0.2)) {
                        selectedBand = selectedBand == index ? nil : index
                    }
                } label: {
                    VStack(spacing: 2) {
                        // Band number with type indicator
                        ZStack {
                            Circle()
                                .fill(isSelected ? band.type.color : band.type.color.opacity(0.3))
                                .frame(width: 20, height: 20)

                            Text("\(index + 1)")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundStyle(isSelected ? .black : .white)
                        }

                        // Frequency
                        Text(formatFrequency(band.frequency))
                            .font(.system(size: 8, design: .monospaced))
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 6)
                    .background(
                        RoundedRectangle(cornerRadius: 6)
                            .fill(isSelected ? Color.white.opacity(0.1) : Color.clear)
                    )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(Color.black.opacity(0.3))
    }

    private func formatFrequency(_ freq: Float) -> String {
        if freq >= 1000 {
            return String(format: "%.1fk", freq / 1000)
        }
        return "\(Int(freq))"
    }
}

// MARK: - GarageBand Band Controls

struct GarageBandBandControls: View {
    @Binding var band: EQBand

    var body: some View {
        VStack(spacing: 12) {
            // Type selector
            HStack(spacing: 8) {
                ForEach(EQBand.BandType.allCases, id: \.self) { type in
                    Button {
                        band.type = type
                    } label: {
                        VStack(spacing: 2) {
                            Image(systemName: type.icon)
                                .font(.system(size: 14))
                            Text(type.shortName)
                                .font(.system(size: 8, weight: .medium))
                        }
                        .frame(width: 50, height: 36)
                        .background(
                            RoundedRectangle(cornerRadius: 6)
                                .fill(band.type == type ? type.color : Color.white.opacity(0.05))
                        )
                        .foregroundStyle(band.type == type ? .black : .secondary)
                    }
                    .buttonStyle(.plain)
                }
            }

            // Value controls
            HStack(spacing: 24) {
                // Frequency
                VStack(spacing: 4) {
                    Text("FREQ")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(.secondary)

                    Text(formatFrequency(band.frequency))
                        .font(.system(size: 18, weight: .bold, design: .monospaced))
                        .foregroundStyle(.green)
                }
                .frame(width: 80)

                // Gain
                VStack(spacing: 4) {
                    Text("GAIN")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(.secondary)

                    HStack(spacing: 12) {
                        Button {
                            band.gain = max(-24, band.gain - 1)
                        } label: {
                            Image(systemName: "minus")
                                .font(.system(size: 14, weight: .bold))
                        }
                        .buttonStyle(.plain)
                        .foregroundStyle(.secondary)

                        Text(String(format: "%+.1f", band.gain))
                            .font(.system(size: 18, weight: .bold, design: .monospaced))
                            .foregroundStyle(band.gain >= 0 ? .green : .orange)
                            .frame(width: 60)

                        Button {
                            band.gain = min(24, band.gain + 1)
                        } label: {
                            Image(systemName: "plus")
                                .font(.system(size: 14, weight: .bold))
                        }
                        .buttonStyle(.plain)
                        .foregroundStyle(.secondary)
                    }
                }

                // Q
                VStack(spacing: 4) {
                    Text("Q")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(.secondary)

                    HStack(spacing: 12) {
                        Button {
                            band.q = max(0.1, band.q - 0.1)
                        } label: {
                            Image(systemName: "minus")
                                .font(.system(size: 14, weight: .bold))
                        }
                        .buttonStyle(.plain)
                        .foregroundStyle(.secondary)

                        Text(String(format: "%.1f", band.q))
                            .font(.system(size: 18, weight: .bold, design: .monospaced))
                            .foregroundStyle(.yellow)
                            .frame(width: 40)

                        Button {
                            band.q = min(10, band.q + 0.1)
                        } label: {
                            Image(systemName: "plus")
                                .font(.system(size: 14, weight: .bold))
                        }
                        .buttonStyle(.plain)
                        .foregroundStyle(.secondary)
                    }
                }
                .frame(width: 100)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.black.opacity(0.4))
        )
        .padding(.horizontal, 8)
        .padding(.bottom, 8)
    }

    private func formatFrequency(_ freq: Float) -> String {
        if freq >= 1000 {
            return String(format: "%.2fk", freq / 1000)
        }
        return String(format: "%.0f", freq)
    }
}

// MARK: - EQ Band Model

struct EQBand: Identifiable {
    let id: Int
    var frequency: Float      // 20 - 20000 Hz
    var gain: Float           // -30 to +30 dB
    var q: Float              // 0.1 to 10
    var type: BandType
    var isEnabled: Bool
    
    enum BandType: String, CaseIterable {
        case highPass = "High Pass"
        case lowShelf = "Low Shelf"
        case peak = "Peak"
        case highShelf = "High Shelf"
        case lowPass = "Low Pass"

        var icon: String {
            switch self {
            case .highPass: return "line.diagonal"
            case .lowShelf: return "arrow.down.left"
            case .peak: return "diamond"
            case .highShelf: return "arrow.up.right"
            case .lowPass: return "line.diagonal"
            }
        }

        var shortName: String {
            switch self {
            case .highPass: return "HP"
            case .lowShelf: return "LS"
            case .peak: return "PK"
            case .highShelf: return "HS"
            case .lowPass: return "LP"
            }
        }

        var color: Color {
            switch self {
            case .highPass: return .red
            case .lowShelf: return .orange
            case .peak: return .green
            case .highShelf: return .cyan
            case .lowPass: return .purple
            }
        }
    }
    
    static let defaultBands: [EQBand] = [
        EQBand(id: 0, frequency: 30, gain: 0, q: 0.7, type: .highPass, isEnabled: true),
        EQBand(id: 1, frequency: 80, gain: 0, q: 1.0, type: .lowShelf, isEnabled: true),
        EQBand(id: 2, frequency: 200, gain: 0, q: 1.0, type: .peak, isEnabled: true),
        EQBand(id: 3, frequency: 500, gain: 0, q: 1.0, type: .peak, isEnabled: true),
        EQBand(id: 4, frequency: 1000, gain: 0, q: 1.0, type: .peak, isEnabled: true),
        EQBand(id: 5, frequency: 3000, gain: 0, q: 1.0, type: .peak, isEnabled: true),
        EQBand(id: 6, frequency: 8000, gain: 0, q: 1.0, type: .highShelf, isEnabled: true),
        EQBand(id: 7, frequency: 16000, gain: 0, q: 0.7, type: .lowPass, isEnabled: true)
    ]
}

// MARK: - EQ Header View

struct EQHeaderView: View {
    var body: some View {
        HStack {
            HStack(spacing: 8) {
                Image(systemName: "slider.horizontal.3")
                    .foregroundStyle(.green)
                Text("PARAMETRIC EQ")
                    .font(.system(size: 14, weight: .bold, design: .monospaced))
                    .foregroundStyle(.white)
            }
            
            Spacer()
            
            Button {
                // Reset EQ
            } label: {
                Text("Reset")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
        }
        .padding()
    }
}

// MARK: - EQ Grid View

struct EQGridView: View {
    let frequencies: [Float] = [20, 30, 40, 50, 60, 80, 100, 200, 300, 400, 500, 600, 800, 1000, 2000, 3000, 4000, 5000, 6000, 8000, 10000, 20000]
    let gains: [Float] = [-30, -25, -20, -15, -10, -5, 0, 5, 10, 15, 20, 25, 30]
    
    var body: some View {
        GeometryReader { geometry in
            let width = geometry.size.width
            let height = geometry.size.height
            
            ZStack {
                // Vertical frequency lines
                ForEach([20, 50, 100, 200, 500, 1000, 2000, 5000, 10000, 20000], id: \.self) { freq in
                    let x = frequencyToX(Float(freq), width: width)
                    
                    Path { path in
                        path.move(to: CGPoint(x: x, y: 0))
                        path.addLine(to: CGPoint(x: x, y: height))
                    }
                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
                    
                    // Frequency label
                    Text(formatFrequency(Float(freq)))
                        .font(.system(size: 8, design: .monospaced))
                        .foregroundStyle(.white.opacity(0.4))
                        .position(x: x, y: height - 10)
                }
                
                // Horizontal gain lines
                ForEach([-20, -10, 0, 10, 20], id: \.self) { gain in
                    let y = gainToY(Float(gain), height: height)
                    
                    Path { path in
                        path.move(to: CGPoint(x: 0, y: y))
                        path.addLine(to: CGPoint(x: width, y: y))
                    }
                    .stroke(
                        gain == 0 ? Color.white.opacity(0.3) : Color.white.opacity(0.1),
                        lineWidth: gain == 0 ? 2 : 1
                    )
                    
                    // Gain label
                    Text("\(gain)")
                        .font(.system(size: 8, design: .monospaced))
                        .foregroundStyle(.white.opacity(0.4))
                        .position(x: 15, y: y)
                }
            }
        }
    }
    
    private func formatFrequency(_ freq: Float) -> String {
        if freq >= 1000 {
            return "\(Int(freq / 1000))k"
        }
        return "\(Int(freq))"
    }
    
    private func frequencyToX(_ freq: Float, width: CGFloat) -> CGFloat {
        let minFreq: Float = 20
        let maxFreq: Float = 20000
        let logMin = log10(minFreq)
        let logMax = log10(maxFreq)
        let logFreq = log10(max(freq, minFreq))
        return CGFloat((logFreq - logMin) / (logMax - logMin)) * width
    }
    
    private func gainToY(_ gain: Float, height: CGFloat) -> CGFloat {
        let minGain: Float = -30
        let maxGain: Float = 30
        return CGFloat(1 - (gain - minGain) / (maxGain - minGain)) * height
    }
}

// MARK: - EQ Curve View

struct EQCurveView: View {
    let bands: [EQBand]
    let selectedBand: Int?
    
    var body: some View {
        GeometryReader { geometry in
            let width = geometry.size.width
            let height = geometry.size.height
            
            // Combined frequency response curve
            Path { path in
                var started = false
                for x in stride(from: 0, to: width, by: 2) {
                    let freq = xToFrequency(x, width: width)
                    let totalGain = calculateTotalGain(at: freq)
                    let y = gainToY(totalGain, height: height)
                    
                    if !started {
                        path.move(to: CGPoint(x: x, y: y))
                        started = true
                    } else {
                        path.addLine(to: CGPoint(x: x, y: y))
                    }
                }
            }
            .stroke(
                LinearGradient(
                    colors: [.cyan, .green, .yellow],
                    startPoint: .leading,
                    endPoint: .trailing
                ),
                lineWidth: 2
            )
            
            // Fill under curve
            Path { path in
                let zeroY = gainToY(0, height: height)
                path.move(to: CGPoint(x: 0, y: zeroY))
                
                for x in stride(from: 0, to: width, by: 2) {
                    let freq = xToFrequency(x, width: width)
                    let totalGain = calculateTotalGain(at: freq)
                    let y = gainToY(totalGain, height: height)
                    path.addLine(to: CGPoint(x: x, y: y))
                }
                
                path.addLine(to: CGPoint(x: width, y: zeroY))
                path.closeSubpath()
            }
            .fill(
                LinearGradient(
                    colors: [.green.opacity(0.3), .green.opacity(0.05)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            
            // Selected band highlight
            if let selected = selectedBand {
                let band = bands[selected]
                let centerX = frequencyToX(band.frequency, width: width)
                let bandWidth = width * 0.15
                
                Rectangle()
                    .fill(band.type.color.opacity(0.2))
                    .frame(width: bandWidth)
                    .position(x: centerX, y: height / 2)
            }
        }
    }
    
    private func calculateTotalGain(at frequency: Float) -> Float {
        var total: Float = 0
        for band in bands where band.isEnabled {
            total += calculateBandGain(band, at: frequency)
        }
        return max(-30, min(30, total))
    }
    
    private func calculateBandGain(_ band: EQBand, at frequency: Float) -> Float {
        let ratio = frequency / band.frequency
        let logRatio = log2(ratio)
        
        switch band.type {
        case .peak:
            let bandwidth = 1.0 / band.q
            let x = logRatio / bandwidth
            return band.gain * exp(-x * x * 2)
            
        case .lowShelf:
            if frequency < band.frequency {
                return band.gain
            } else {
                let x = logRatio * band.q
                return band.gain * exp(-x * x)
            }
            
        case .highShelf:
            if frequency > band.frequency {
                return band.gain
            } else {
                let x = -logRatio * band.q
                return band.gain * exp(-x * x)
            }
            
        case .highPass:
            if frequency < band.frequency {
                let octaves = log2(band.frequency / frequency)
                return -octaves * 12 // 12dB/octave
            }
            return 0
            
        case .lowPass:
            if frequency > band.frequency {
                let octaves = log2(frequency / band.frequency)
                return -octaves * 12
            }
            return 0
        }
    }
    
    private func frequencyToX(_ freq: Float, width: CGFloat) -> CGFloat {
        let minFreq: Float = 20
        let maxFreq: Float = 20000
        let logMin = log10(minFreq)
        let logMax = log10(maxFreq)
        let logFreq = log10(max(freq, minFreq))
        return CGFloat((logFreq - logMin) / (logMax - logMin)) * width
    }
    
    private func xToFrequency(_ x: CGFloat, width: CGFloat) -> Float {
        let minFreq: Float = 20
        let maxFreq: Float = 20000
        let logMin = log10(minFreq)
        let logMax = log10(maxFreq)
        let ratio = Float(x / width)
        let logFreq = logMin + ratio * (logMax - logMin)
        return pow(10, logFreq)
    }
    
    private func gainToY(_ gain: Float, height: CGFloat) -> CGFloat {
        let minGain: Float = -30
        let maxGain: Float = 30
        return CGFloat(1 - (gain - minGain) / (maxGain - minGain)) * height
    }
}

// MARK: - EQ Band Controls View

struct EQBandControlsView: View {
    @Binding var bands: [EQBand]
    @Binding var selectedBand: Int?
    
    var body: some View {
        GeometryReader { geometry in
            let width = geometry.size.width
            let height = geometry.size.height
            
            ForEach(bands.indices, id: \.self) { index in
                let band = bands[index]
                let x = frequencyToX(band.frequency, width: width)
                let y = gainToY(band.gain, height: height)
                
                Circle()
                    .fill(band.type.color)
                    .frame(width: selectedBand == index ? 20 : 14,
                           height: selectedBand == index ? 20 : 14)
                    .overlay(
                        Circle()
                            .strokeBorder(Color.white, lineWidth: selectedBand == index ? 2 : 1)
                    )
                    .shadow(color: band.type.color.opacity(0.5), radius: selectedBand == index ? 8 : 4)
                    .position(x: x, y: y)
                    .gesture(
                        DragGesture()
                            .onChanged { value in
                                selectedBand = index
                                let newFreq = xToFrequency(value.location.x, width: width)
                                let newGain = yToGain(value.location.y, height: height)
                                bands[index].frequency = max(20, min(20000, newFreq))
                                bands[index].gain = max(-30, min(30, newGain))
                            }
                    )
                    .onTapGesture {
                        selectedBand = selectedBand == index ? nil : index
                    }
            }
        }
    }
    
    private func frequencyToX(_ freq: Float, width: CGFloat) -> CGFloat {
        let minFreq: Float = 20
        let maxFreq: Float = 20000
        let logMin = log10(minFreq)
        let logMax = log10(maxFreq)
        let logFreq = log10(max(freq, minFreq))
        return CGFloat((logFreq - logMin) / (logMax - logMin)) * width
    }
    
    private func xToFrequency(_ x: CGFloat, width: CGFloat) -> Float {
        let minFreq: Float = 20
        let maxFreq: Float = 20000
        let logMin = log10(minFreq)
        let logMax = log10(maxFreq)
        let ratio = Float(max(0, min(x, width)) / width)
        let logFreq = logMin + ratio * (logMax - logMin)
        return pow(10, logFreq)
    }
    
    private func gainToY(_ gain: Float, height: CGFloat) -> CGFloat {
        let minGain: Float = -30
        let maxGain: Float = 30
        return CGFloat(1 - (gain - minGain) / (maxGain - minGain)) * height
    }
    
    private func yToGain(_ y: CGFloat, height: CGFloat) -> Float {
        let minGain: Float = -30
        let maxGain: Float = 30
        let ratio = Float(max(0, min(y, height)) / height)
        return maxGain - ratio * (maxGain - minGain)
    }
}

// MARK: - EQ Band Types View

struct EQBandTypesView: View {
    @Binding var bands: [EQBand]
    let selectedBand: Int?
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(bands.indices, id: \.self) { index in
                    let band = bands[index]
                    
                    Button {
                        // Cycle through band types
                        let types = EQBand.BandType.allCases
                        if let currentIndex = types.firstIndex(of: band.type) {
                            let nextIndex = (currentIndex + 1) % types.count
                            bands[index].type = types[nextIndex]
                        }
                    } label: {
                        VStack(spacing: 4) {
                            Image(systemName: band.type.icon)
                                .font(.system(size: 14))
                            Text("\(index + 1)")
                                .font(.system(size: 10, weight: .bold, design: .monospaced))
                        }
                        .frame(width: 40, height: 40)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(selectedBand == index ? band.type.color : band.type.color.opacity(0.3))
                        )
                        .foregroundStyle(selectedBand == index ? .black : .white)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding()
        }
    }
}

// MARK: - EQ Band Info View

struct EQBandInfoView: View {
    @Binding var band: EQBand
    
    var body: some View {
        HStack(spacing: 24) {
            // Frequency
            VStack(spacing: 4) {
                Text("Frequency")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(formatFrequency(band.frequency))
                    .font(.system(size: 16, weight: .bold, design: .monospaced))
                    .foregroundStyle(.cyan)
            }
            
            // Gain
            VStack(spacing: 4) {
                Text("Gain")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(String(format: "%+.1f dB", band.gain))
                    .font(.system(size: 16, weight: .bold, design: .monospaced))
                    .foregroundStyle(band.gain >= 0 ? .green : .red)
            }
            
            // Q
            VStack(spacing: 4) {
                Text("Q")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                HStack(spacing: 8) {
                    Button {
                        band.q = max(0.1, band.q - 0.1)
                    } label: {
                        Image(systemName: "minus.circle")
                    }
                    .buttonStyle(.plain)
                    
                    Text(String(format: "%.2f", band.q))
                        .font(.system(size: 16, weight: .bold, design: .monospaced))
                        .foregroundStyle(.yellow)
                    
                    Button {
                        band.q = min(10, band.q + 0.1)
                    } label: {
                        Image(systemName: "plus.circle")
                    }
                    .buttonStyle(.plain)
                }
            }
            
            Spacer()
            
            // Type
            VStack(spacing: 4) {
                Text("Type")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(band.type.rawValue)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(band.type.color)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.black.opacity(0.3))
        )
    }
    
    private func formatFrequency(_ freq: Float) -> String {
        if freq >= 1000 {
            return String(format: "%.1f kHz", freq / 1000)
        }
        return String(format: "%.0f Hz", freq)
    }
}

// MARK: - Preview

#Preview {
    ParametricEQView(engine: AudioEngineManager())
        .frame(height: 500)
        .padding()
        .background(Color.black)
}
