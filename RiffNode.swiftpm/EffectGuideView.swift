import SwiftUI

// MARK: - Effect Guide View
// Liquid Glass UI Design - iOS 26+

struct EffectGuideView: View {

    // MARK: - Dependencies

    private let guideService: EffectGuideServiceProtocol

    // MARK: - State

    @State private var selectedCategoryIndex: Int = 0
    @State private var expandedEffectId: UUID? = nil
    @Namespace private var guideNamespace

    // MARK: - Initialization

    init(guideService: EffectGuideServiceProtocol = EffectGuideService.shared) {
        self.guideService = guideService
    }

    // MARK: - Computed Properties

    private var categories: [any EffectCategoryProviding] {
        guideService.categories
    }

    private var selectedCategory: (any EffectCategoryProviding)? {
        guard selectedCategoryIndex < categories.count else { return nil }
        return categories[selectedCategoryIndex]
    }

    // MARK: - Body

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Header
                GlassGuideHeader()

                // Sound Science educational section
                GlassSoundScienceView()

                // Effect categories section
                VStack(spacing: 16) {
                    // Section header
                    HStack {
                        HStack(spacing: 8) {
                            Image(systemName: "square.grid.2x2.fill")
                                .foregroundStyle(.primary)
                            Text("Effect Categories")
                                .font(.headline)
                        }
                        Spacer()
                    }
                    .padding(.horizontal)

                    // Category selector
                    GlassCategorySelectorView(
                        categories: categories,
                        selectedIndex: $selectedCategoryIndex,
                        namespace: guideNamespace
                    )

                    if let category = selectedCategory {
                        GlassCategoryDescriptionView(category: category)

                        // Effects list
                        LazyVStack(spacing: 12) {
                            ForEach(Array(category.effects.enumerated()), id: \.offset) { index, effect in
                                if let effectModel = effect as? EffectInfoModel {
                                    GlassEffectCardView(
                                        effect: effectModel,
                                        isExpanded: expandedEffectId == effectModel.id
                                    ) {
                                        withAnimation(.spring(duration: 0.3)) {
                                            expandedEffectId = expandedEffectId == effectModel.id ? nil : effectModel.id
                                        }
                                    }
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                }
            }
            .padding(.vertical)
        }
    }
}

// MARK: - Glass Guide Header

struct GlassGuideHeader: View {
    var body: some View {
        GlassCard(cornerRadius: 16) {
            VStack(spacing: 8) {
                HStack {
                    HStack(spacing: 8) {
                        Image(systemName: "book.fill")
                            .foregroundStyle(.primary)
                        Text("Learn")
                            .font(.headline)
                    }
                    Spacer()
                }

                Text("Discover the science of sound and master guitar effects")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(.horizontal)
    }
}

// MARK: - Glass Sound Science Section

struct GlassSoundScienceView: View {
    @State private var selectedTopic: SoundTopic = .waveforms
    @State private var animationPhase: Double = 0
    @Namespace private var scienceNamespace

    enum SoundTopic: String, CaseIterable {
        case waveforms = "Waves"
        case frequency = "Pitch"
        case clipping = "Distortion"
        case time = "Time"

        var icon: String {
            switch self {
            case .waveforms: return "waveform"
            case .frequency: return "tuningfork"
            case .clipping: return "bolt.fill"
            case .time: return "clock"
            }
        }

        var color: Color {
            switch self {
            case .waveforms: return .cyan
            case .frequency: return .green
            case .clipping: return .orange
            case .time: return .blue
            }
        }

        var explanation: String {
            switch self {
            case .waveforms:
                return "Sound is vibration traveling through air as waves. Guitar strings vibrate, creating pressure waves your ears interpret as sound. The shape of these waves determines the tone quality."
            case .frequency:
                return "Frequency is how fast sound waves vibrate, measured in Hertz (Hz). Higher frequency = higher pitch. Guitar effects can shift, multiply, or modulate these frequencies."
            case .clipping:
                return "Distortion occurs when a signal is too loud for a circuit to handle cleanly. The tops of the waves get 'clipped' off, creating harmonics that give that crunchy, aggressive sound."
            case .time:
                return "Time-based effects manipulate when you hear the sound. Delay creates echoes, reverb simulates reflections in physical spaces, and chorus uses tiny delays for movement."
            }
        }
    }

    var body: some View {
        GlassCard(cornerRadius: 16) {
            VStack(spacing: 16) {
                // Header
                HStack {
                    HStack(spacing: 8) {
                        Image(systemName: "waveform.badge.magnifyingglass")
                            .foregroundStyle(.primary)
                        Text("Science of Sound")
                            .font(.headline)
                    }
                    Spacer()
                }

                // Topic selector with glass pills
                GlassEffectContainer(spacing: 4) {
                    ForEach(SoundTopic.allCases, id: \.self) { topic in
                        Button {
                            withAnimation(.spring(duration: 0.3)) {
                                selectedTopic = topic
                            }
                        } label: {
                            VStack(spacing: 4) {
                                Image(systemName: topic.icon)
                                    .font(.system(size: 14))
                                Text(topic.rawValue)
                                    .font(.system(size: 10, weight: .medium))
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                            .foregroundStyle(selectedTopic == topic ? topic.color : .secondary)
                        }
                        .glassEffect(
                            selectedTopic == topic ? .regular.tint(topic.color) : .clear,
                            in: RoundedRectangle(cornerRadius: 8)
                        )
                        .glassEffectID("topic_\(topic.rawValue)", in: scienceNamespace)
                        .buttonStyle(.plain)
                    }
                }

                // Visualization
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(.black.opacity(0.3))

                    SoundVisualization(topic: selectedTopic, phase: animationPhase)
                        .padding()
                }
                .frame(height: 100)
                .overlay {
                    RoundedRectangle(cornerRadius: 12)
                        .strokeBorder(.white.opacity(0.1), lineWidth: 1)
                }

                // Explanation
                Text(selectedTopic.explanation)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(.horizontal)
        .onAppear {
            withAnimation(.linear(duration: 2).repeatForever(autoreverses: false)) {
                animationPhase = .pi * 2
            }
        }
    }
}

// MARK: - Sound Visualization

struct SoundVisualization: View {
    let topic: GlassSoundScienceView.SoundTopic
    let phase: Double

    var body: some View {
        TimelineView(.animation) { timeline in
            Canvas { context, size in
                let midY = size.height / 2
                let time = timeline.date.timeIntervalSinceReferenceDate

                switch topic {
                case .waveforms:
                    drawWaveform(context: context, size: size, midY: midY, time: time)
                case .frequency:
                    drawFrequency(context: context, size: size, midY: midY, time: time)
                case .clipping:
                    drawClipping(context: context, size: size, midY: midY, time: time)
                case .time:
                    drawTimeEffect(context: context, size: size, midY: midY, time: time)
                }
            }
        }
    }

    private func drawWaveform(context: GraphicsContext, size: CGSize, midY: CGFloat, time: Double) {
        var path = Path()
        path.move(to: CGPoint(x: 0, y: midY))

        for x in stride(from: 0, through: size.width, by: 2) {
            let relativeX = x / size.width
            let y = midY + sin(relativeX * .pi * 4 + time * 2) * size.height * 0.35
            path.addLine(to: CGPoint(x: x, y: y))
        }

        context.stroke(path, with: .color(.cyan), lineWidth: 2)
    }

    private func drawFrequency(context: GraphicsContext, size: CGSize, midY: CGFloat, time: Double) {
        // Low frequency wave
        var lowPath = Path()
        lowPath.move(to: CGPoint(x: 0, y: midY - 20))
        for x in stride(from: 0, through: size.width, by: 2) {
            let y = midY - 20 + sin(x / size.width * .pi * 2 + time) * 15
            lowPath.addLine(to: CGPoint(x: x, y: y))
        }
        context.stroke(lowPath, with: .color(.red.opacity(0.8)), lineWidth: 2)

        // High frequency wave
        var highPath = Path()
        highPath.move(to: CGPoint(x: 0, y: midY + 20))
        for x in stride(from: 0, through: size.width, by: 2) {
            let y = midY + 20 + sin(x / size.width * .pi * 8 + time * 2) * 15
            highPath.addLine(to: CGPoint(x: x, y: y))
        }
        context.stroke(highPath, with: .color(.green.opacity(0.8)), lineWidth: 2)
    }

    private func drawClipping(context: GraphicsContext, size: CGSize, midY: CGFloat, time: Double) {
        // Clean wave
        var cleanPath = Path()
        cleanPath.move(to: CGPoint(x: 0, y: midY))
        for x in stride(from: 0, through: size.width / 2 - 10, by: 2) {
            let y = midY + sin(x / size.width * .pi * 6 + time * 2) * size.height * 0.35
            cleanPath.addLine(to: CGPoint(x: x, y: y))
        }
        context.stroke(cleanPath, with: .color(.green.opacity(0.6)), lineWidth: 2)

        // Clipped wave
        var clippedPath = Path()
        let startX = size.width / 2 + 10
        clippedPath.move(to: CGPoint(x: startX, y: midY))
        for x in stride(from: startX, through: size.width, by: 2) {
            var y = midY + sin(x / size.width * .pi * 6 + time * 2) * size.height * 0.5
            let clipThreshold = size.height * 0.25
            y = min(max(y, midY - clipThreshold), midY + clipThreshold)
            clippedPath.addLine(to: CGPoint(x: x, y: y))
        }
        context.stroke(clippedPath, with: .color(.orange), lineWidth: 2)
    }

    private func drawTimeEffect(context: GraphicsContext, size: CGSize, midY: CGFloat, time: Double) {
        // Original signal
        var originalPath = Path()
        originalPath.move(to: CGPoint(x: 0, y: midY))
        for x in stride(from: 0, through: size.width, by: 2) {
            let y = midY + sin(x / size.width * .pi * 4 + time * 2) * size.height * 0.3
            originalPath.addLine(to: CGPoint(x: x, y: y))
        }
        context.stroke(originalPath, with: .color(.cyan), lineWidth: 2)

        // Delayed echo
        var delayedPath = Path()
        let offset: CGFloat = 40
        delayedPath.move(to: CGPoint(x: offset, y: midY))
        for x in stride(from: offset, through: size.width, by: 2) {
            let y = midY + sin((x - offset) / size.width * .pi * 4 + time * 2) * size.height * 0.2
            delayedPath.addLine(to: CGPoint(x: x, y: y))
        }
        context.stroke(delayedPath, with: .color(.cyan.opacity(0.4)), lineWidth: 2)
    }
}

// MARK: - Glass Category Selector View

struct GlassCategorySelectorView: View {
    let categories: [any EffectCategoryProviding]
    @Binding var selectedIndex: Int
    var namespace: Namespace.ID

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            GlassEffectContainer(spacing: 8) {
                ForEach(Array(categories.enumerated()), id: \.offset) { index, category in
                    Button {
                        withAnimation(.spring(duration: 0.3)) {
                            selectedIndex = index
                        }
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: category.icon)
                                .font(.system(size: 12))
                            Text(category.name)
                                .font(.system(size: 12, weight: .medium))
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .foregroundStyle(selectedIndex == index ? .white : .secondary)
                    }
                    .glassEffect(
                        selectedIndex == index ? .regular.tint(category.color) : .clear,
                        in: Capsule()
                    )
                    .glassEffectID("category_\(index)", in: namespace)
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal)
        }
    }
}

// MARK: - Glass Category Description View

struct GlassCategoryDescriptionView: View {
    let category: any EffectCategoryProviding

    var body: some View {
        GlassCard(cornerRadius: 12, padding: 12) {
            VStack(spacing: 12) {
                HStack(spacing: 12) {
                    Image(systemName: category.icon)
                        .font(.title2)
                        .foregroundStyle(.primary)

                    Text(category.description)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                // Effect category visualization
                GlassEffectCategoryVisualization(category: category)
            }
        }
        .padding(.horizontal)
    }
}

// MARK: - Glass Effect Category Visualization

struct GlassEffectCategoryVisualization: View {
    let category: any EffectCategoryProviding

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8)
                .fill(.black.opacity(0.3))

            TimelineView(.animation(minimumInterval: 0.03)) { timeline in
                Canvas { context, size in
                    let time = timeline.date.timeIntervalSinceReferenceDate
                    let midY = size.height / 2

                    switch category.name.lowercased() {
                    case "dynamics":
                        drawDynamicsEffect(context: context, size: size, midY: midY, time: time, color: category.color)
                    case "gain / dirt":
                        drawDistortionEffect(context: context, size: size, midY: midY, time: time, color: category.color)
                    case "modulation":
                        drawModulationEffect(context: context, size: size, midY: midY, time: time, color: category.color)
                    case "time / ambience":
                        drawTimeEffect(context: context, size: size, midY: midY, time: time, color: category.color)
                    case "filter / pitch":
                        drawFilterEffect(context: context, size: size, midY: midY, time: time, color: category.color)
                    default:
                        drawGenericWaveform(context: context, size: size, midY: midY, time: time, color: category.color)
                    }
                }
            }
            .padding(8)

            // Labels
            HStack {
                VStack(alignment: .leading) {
                    Text("INPUT")
                        .font(.system(size: 8, weight: .semibold))
                        .foregroundStyle(.secondary)
                    Spacer()
                }
                Spacer()
                VStack(alignment: .trailing) {
                    Text("OUTPUT")
                        .font(.system(size: 8, weight: .semibold))
                        .foregroundStyle(category.color)
                    Spacer()
                }
            }
            .padding(8)
        }
        .frame(height: 80)
        .overlay {
            RoundedRectangle(cornerRadius: 8)
                .strokeBorder(.white.opacity(0.1), lineWidth: 1)
        }
    }

    private func drawDynamicsEffect(context: GraphicsContext, size: CGSize, midY: CGFloat, time: Double, color: Color) {
        var inputPath = Path()
        var outputPath = Path()

        inputPath.move(to: CGPoint(x: 0, y: midY))
        outputPath.move(to: CGPoint(x: 0, y: midY))

        for x in stride(from: 0, through: size.width, by: 2) {
            let relativeX = x / size.width
            let inputAmplitude = (0.3 + sin(relativeX * .pi * 2) * 0.5) * size.height * 0.4
            let inputY = midY + sin(relativeX * .pi * 6 + time * 2) * inputAmplitude

            let compressedAmplitude = size.height * 0.25
            let outputY = midY + sin(relativeX * .pi * 6 + time * 2) * compressedAmplitude

            inputPath.addLine(to: CGPoint(x: x, y: inputY))
            outputPath.addLine(to: CGPoint(x: x, y: outputY))
        }

        context.stroke(inputPath, with: .color(.gray.opacity(0.5)), lineWidth: 1.5)
        context.stroke(outputPath, with: .color(color), lineWidth: 2)
    }

    private func drawDistortionEffect(context: GraphicsContext, size: CGSize, midY: CGFloat, time: Double, color: Color) {
        var cleanPath = Path()
        var clippedPath = Path()

        cleanPath.move(to: CGPoint(x: 0, y: midY))
        clippedPath.move(to: CGPoint(x: 0, y: midY))

        for x in stride(from: 0, through: size.width, by: 2) {
            let relativeX = x / size.width
            let wave = sin(relativeX * .pi * 4 + time * 2)

            let cleanY = midY + wave * size.height * 0.35
            cleanPath.addLine(to: CGPoint(x: x, y: cleanY))

            let clippedWave = max(-0.6, min(0.6, wave * 1.5))
            let clippedY = midY + clippedWave * size.height * 0.35
            clippedPath.addLine(to: CGPoint(x: x, y: clippedY))
        }

        context.stroke(cleanPath, with: .color(.gray.opacity(0.4)), lineWidth: 1.5)
        context.stroke(clippedPath, with: .color(color), lineWidth: 2)
    }

    private func drawModulationEffect(context: GraphicsContext, size: CGSize, midY: CGFloat, time: Double, color: Color) {
        let colors: [Color] = [color.opacity(0.3), color.opacity(0.5), color]

        for (i, c) in colors.enumerated() {
            var path = Path()
            let phaseOffset = Double(i) * 0.1
            let pitchOffset = Double(i) * 0.05

            path.move(to: CGPoint(x: 0, y: midY))

            for x in stride(from: 0, through: size.width, by: 2) {
                let relativeX = x / size.width
                let modulatedFreq = 4.0 + sin(time * 3 + phaseOffset) * pitchOffset
                let y = midY + sin(relativeX * .pi * modulatedFreq + time * 2 + phaseOffset) * size.height * 0.3
                path.addLine(to: CGPoint(x: x, y: y))
            }

            context.stroke(path, with: .color(c), lineWidth: i == 2 ? 2 : 1.5)
        }
    }

    private func drawTimeEffect(context: GraphicsContext, size: CGSize, midY: CGFloat, time: Double, color: Color) {
        let echoes = 4

        for i in (0..<echoes).reversed() {
            var path = Path()
            let delay = Double(i) * 0.15
            let fade = 1.0 - Double(i) * 0.25

            path.move(to: CGPoint(x: 0, y: midY))

            for x in stride(from: 0, through: size.width, by: 2) {
                let relativeX = x / size.width
                let y = midY + sin(relativeX * .pi * 4 + time * 2 - delay * 10) * size.height * 0.3 * fade
                path.addLine(to: CGPoint(x: x, y: y))
            }

            let strokeColor = i == 0 ? color : color.opacity(fade * 0.6)
            context.stroke(path, with: .color(strokeColor), lineWidth: i == 0 ? 2 : 1.5)
        }
    }

    private func drawFilterEffect(context: GraphicsContext, size: CGSize, midY: CGFloat, time: Double, color: Color) {
        var fullPath = Path()
        var filteredPath = Path()

        fullPath.move(to: CGPoint(x: 0, y: midY))
        filteredPath.move(to: CGPoint(x: 0, y: midY))

        for x in stride(from: 0, through: size.width, by: 2) {
            let relativeX = x / size.width

            let low = sin(relativeX * .pi * 2 + time * 2) * 0.5
            let mid = sin(relativeX * .pi * 6 + time * 2) * 0.3
            let high = sin(relativeX * .pi * 16 + time * 2) * 0.2
            let fullY = midY + (low + mid + high) * size.height * 0.3
            fullPath.addLine(to: CGPoint(x: x, y: fullY))

            let filteredY = midY + (low + mid * 0.5) * size.height * 0.3
            filteredPath.addLine(to: CGPoint(x: x, y: filteredY))
        }

        context.stroke(fullPath, with: .color(.gray.opacity(0.4)), lineWidth: 1.5)
        context.stroke(filteredPath, with: .color(color), lineWidth: 2)
    }

    private func drawGenericWaveform(context: GraphicsContext, size: CGSize, midY: CGFloat, time: Double, color: Color) {
        var path = Path()
        path.move(to: CGPoint(x: 0, y: midY))

        for x in stride(from: 0, through: size.width, by: 2) {
            let relativeX = x / size.width
            let y = midY + sin(relativeX * .pi * 4 + time * 2) * size.height * 0.3
            path.addLine(to: CGPoint(x: x, y: y))
        }

        context.stroke(path, with: .color(color), lineWidth: 2)
    }
}

// MARK: - Glass Effect Card View

struct GlassEffectCardView: View {
    let effect: EffectInfoModel
    let isExpanded: Bool
    let onTap: () -> Void
    @Namespace private var cardNamespace

    var body: some View {
        GlassCard(cornerRadius: 12, padding: 0) {
            VStack(alignment: .leading, spacing: 0) {
                // Header
                Button(action: onTap) {
                    HStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(effect.color.opacity(0.2))
                                .frame(width: 44, height: 44)
                            Image(systemName: effect.icon)
                                .font(.system(size: 18))
                                .foregroundStyle(effect.color)
                        }
                        .glassEffect(.clear, in: Circle())

                        Text(effect.name)
                            .font(.headline)

                        Spacer()

                        Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                            .foregroundStyle(.secondary)
                            .font(.system(size: 14, weight: .medium))
                    }
                    .padding()
                }
                .buttonStyle(.plain)

                if isExpanded {
                    GlassEffectCardDetails(effect: effect)
                        .transition(.opacity.combined(with: .move(edge: .top)))
                }
            }
        }
        .animation(.spring(duration: 0.3), value: isExpanded)
    }
}

// MARK: - Glass Effect Card Details

struct GlassEffectCardDetails: View {
    let effect: EffectInfoModel

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Divider
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [effect.color.opacity(0.6), effect.color.opacity(0.1)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(height: 2)

            VStack(alignment: .leading, spacing: 16) {
                // What It Does
                GlassEffectInfoSection(
                    icon: "gearshape.fill",
                    title: "What It Does",
                    content: effect.function,
                    accentColor: .cyan
                )

                // The Sound
                GlassEffectInfoSection(
                    icon: "waveform",
                    title: "The Sound",
                    content: effect.sound,
                    accentColor: .green
                )

                // How To Use
                GlassEffectTipsSection(
                    icon: "lightbulb.fill",
                    title: "How To Use",
                    content: effect.howToUse,
                    accentColor: .yellow
                )

                // Signal Chain Position
                GlassEffectSignalChainSection(
                    position: effect.signalChainPosition,
                    effectColor: effect.color
                )

                // Famous Artists
                GlassEffectArtistsSection(
                    artists: effect.famousUsers,
                    accentColor: .purple
                )
            }
            .padding()
        }
    }
}

// MARK: - Glass Effect Info Section

struct GlassEffectInfoSection: View {
    let icon: String
    let title: String
    let content: String
    let accentColor: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(accentColor)

                Text(title.uppercased())
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(accentColor)
            }

            Text(content)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .lineSpacing(3)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

// MARK: - Glass Effect Tips Section

struct GlassEffectTipsSection: View {
    let icon: String
    let title: String
    let content: String
    let accentColor: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(accentColor)

                Text(title.uppercased())
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(accentColor)
            }

            HStack(alignment: .top, spacing: 8) {
                Rectangle()
                    .fill(accentColor)
                    .frame(width: 3)

                Text(content)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineSpacing(3)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(12)
            .background {
                RoundedRectangle(cornerRadius: 8)
                    .fill(accentColor.opacity(0.1))
            }
            .glassEffect(.clear, in: RoundedRectangle(cornerRadius: 8))
        }
    }
}

// MARK: - Glass Effect Signal Chain Section

struct GlassEffectSignalChainSection: View {
    let position: String
    let effectColor: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: "arrow.right.circle.fill")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(.orange)

                Text("SIGNAL CHAIN POSITION")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(.orange)
            }

            // Visual signal chain indicator
            HStack(spacing: 4) {
                Image(systemName: "guitars")
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)

                ForEach(0..<5) { i in
                    RoundedRectangle(cornerRadius: 2)
                        .fill(i == getPositionIndex() ? effectColor : Color.white.opacity(0.2))
                        .frame(width: 20, height: 8)
                }

                Image(systemName: "speaker.wave.2.fill")
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)

                Spacer()
            }

            Text(position)
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private func getPositionIndex() -> Int {
        let lowercased = position.lowercased()
        if lowercased.contains("first") || lowercased.contains("beginning") || lowercased.contains("front") {
            return 0
        } else if lowercased.contains("early") || lowercased.contains("after compressor") {
            return 1
        } else if lowercased.contains("middle") {
            return 2
        } else if lowercased.contains("late") || lowercased.contains("before reverb") {
            return 3
        } else if lowercased.contains("end") || lowercased.contains("last") {
            return 4
        }
        return 2
    }
}

// MARK: - Glass Effect Artists Section

struct GlassEffectArtistsSection: View {
    let artists: String
    let accentColor: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: "star.fill")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(accentColor)

                Text("FAMOUS USERS")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(accentColor)
            }

            let artistList = artists.components(separatedBy: ", ")
            FlowLayout(spacing: 6) {
                ForEach(artistList, id: \.self) { artist in
                    Text(artist)
                        .font(.system(size: 11, weight: .medium))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background {
                            Capsule()
                                .fill(accentColor.opacity(0.15))
                        }
                        .glassEffect(.clear, in: Capsule())
                }
            }
        }
    }
}

// MARK: - Effects List View (Legacy)

struct EffectsListView: View {
    let effects: [any EffectInfoProviding]
    @Binding var expandedEffectId: UUID?

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(Array(effects.enumerated()), id: \.offset) { index, effect in
                    if let effectModel = effect as? EffectInfoModel {
                        GlassEffectCardView(
                            effect: effectModel,
                            isExpanded: expandedEffectId == effectModel.id
                        ) {
                            withAnimation(.spring(duration: 0.3)) {
                                expandedEffectId = expandedEffectId == effectModel.id ? nil : effectModel.id
                            }
                        }
                    }
                }
            }
            .padding()
        }
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        AdaptiveBackground()

        EffectGuideView()
    }
}
