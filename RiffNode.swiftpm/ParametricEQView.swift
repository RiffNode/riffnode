import SwiftUI

// MARK: - Parametric EQ View
// Professional-style parametric equalizer with draggable frequency bands

struct ParametricEQView: View {
    @Bindable var engine: AudioEngineManager
    @State private var selectedBand: Int? = nil
    @State private var bands: [EQBand] = EQBand.defaultBands
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            EQHeaderView()
            
            // Main EQ Display
            ZStack {
                // Background grid
                EQGridView()
                
                // Frequency response curve
                EQCurveView(bands: bands, selectedBand: selectedBand)
                
                // Draggable band controls
                EQBandControlsView(
                    bands: $bands,
                    selectedBand: $selectedBand
                )
            }
            .frame(height: 300)
            .background(Color(red: 0.08, green: 0.1, blue: 0.15))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            
            // Band type selector
            EQBandTypesView(bands: $bands, selectedBand: selectedBand)
            
            // Selected band info
            if let selected = selectedBand {
                EQBandInfoView(band: $bands[selected])
                    .transition(.opacity)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .strokeBorder(Color.green.opacity(0.3), lineWidth: 1)
                )
        )
        .animation(.spring(duration: 0.3), value: selectedBand)
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
            case .lowShelf: return "arrow.down.right"
            case .peak: return "diamond"
            case .highShelf: return "arrow.up.right"
            case .lowPass: return "line.diagonal"
            }
        }
        
        var color: Color {
            switch self {
            case .highPass: return .red
            case .lowShelf: return .yellow
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
