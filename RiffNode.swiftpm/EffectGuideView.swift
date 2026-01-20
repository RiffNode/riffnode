import SwiftUI

// MARK: - Effect Guide View

struct EffectGuideView: View {
    
    // MARK: - Dependencies
    
    private let guideService: EffectGuideServiceProtocol
    
    // MARK: - State
    
    @State private var selectedCategoryIndex: Int = 0
    @State private var expandedEffectId: UUID? = nil
    
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
            VStack(spacing: 0) {
                GuideHeaderView()

                // Sound Science educational section
                VStack(alignment: .leading, spacing: 8) {
                    Text("THE SCIENCE OF SOUND")
                        .font(.system(size: 12, weight: .bold, design: .monospaced))
                        .foregroundStyle(.yellow)
                        .padding(.horizontal)
                        .padding(.top, 16)

                    SoundScienceView()
                }

                Divider()
                    .background(Color.white.opacity(0.1))
                    .padding(.vertical, 16)

                // Effect categories section
                VStack(alignment: .leading, spacing: 8) {
                    Text("EFFECT CATEGORIES")
                        .font(.system(size: 12, weight: .bold, design: .monospaced))
                        .foregroundStyle(.cyan)
                        .padding(.horizontal)

                    CategorySelectorView(
                        categories: categories,
                        selectedIndex: $selectedCategoryIndex
                    )

                    if let category = selectedCategory {
                        CategoryDescriptionView(category: category)

                        // Inline effects list (not in separate ScrollView)
                        LazyVStack(spacing: 12) {
                            ForEach(Array(category.effects.enumerated()), id: \.offset) { index, effect in
                                if let effectModel = effect as? EffectInfoModel {
                                    EffectCardView(
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
        }
        .background(Color(red: 0.05, green: 0.05, blue: 0.1))
    }
}

// MARK: - Guide Header View

struct GuideHeaderView: View {
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: "book.fill")
                    .foregroundStyle(.yellow)
                Text("LEARN")
                    .font(.system(size: 16, weight: .bold, design: .monospaced))
                Spacer()
            }

            Text("Discover the science of sound and master guitar effects")
                .font(.caption)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding()
        .background(Color.black.opacity(0.3))
    }
}

// MARK: - Sound Science Section

struct SoundScienceView: View {
    @State private var selectedTopic: SoundTopic = .waveforms
    @State private var animationPhase: Double = 0

    enum SoundTopic: String, CaseIterable {
        case waveforms = "Sound Waves"
        case frequency = "Pitch & Frequency"
        case clipping = "Distortion Science"
        case time = "Time Effects"

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
                return "Sound is vibration traveling through air as waves. Guitar strings vibrate, creating pressure waves your ears interpret as sound. The shape of these waves determines the tone quality - a sine wave sounds pure, while complex waves sound rich."
            case .frequency:
                return "Frequency is how fast sound waves vibrate, measured in Hertz (Hz). Higher frequency = higher pitch. The note A above middle C vibrates at 440 Hz. Guitar effects can shift, multiply, or modulate these frequencies."
            case .clipping:
                return "Distortion occurs when a signal is too loud for a circuit to handle cleanly. The tops of the waves get 'clipped' off, creating harmonics that give that crunchy, aggressive sound. Soft clipping = warm overdrive. Hard clipping = aggressive distortion."
            case .time:
                return "Time-based effects manipulate when you hear the sound. Delay creates echoes by repeating the signal after a time gap. Reverb simulates reflections in physical spaces. Chorus uses tiny delays to create movement."
            }
        }
    }

    var body: some View {
        VStack(spacing: 16) {
            // Topic selector
            HStack(spacing: 8) {
                ForEach(SoundTopic.allCases, id: \.self) { topic in
                    Button {
                        withAnimation(.spring(duration: 0.3)) {
                            selectedTopic = topic
                        }
                    } label: {
                        VStack(spacing: 4) {
                            Image(systemName: topic.icon)
                                .font(.system(size: 16))
                            Text(topic.rawValue)
                                .font(.system(size: 9, weight: .medium))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(selectedTopic == topic ? topic.color.opacity(0.3) : Color.clear)
                        )
                        .foregroundStyle(selectedTopic == topic ? topic.color : .secondary)
                    }
                    .buttonStyle(.plain)
                }
            }

            // Visualization
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.black.opacity(0.4))

                SoundVisualization(topic: selectedTopic, phase: animationPhase)
                    .padding()
            }
            .frame(height: 100)

            // Explanation
            Text(selectedTopic.explanation)
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .strokeBorder(selectedTopic.color.opacity(0.3), lineWidth: 1)
                )
        )
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
    let topic: SoundScienceView.SoundTopic
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
            // Clip the wave
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

        // Delayed echo (offset and faded)
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

// MARK: - Category Selector View

struct CategorySelectorView: View {
    let categories: [any EffectCategoryProviding]
    @Binding var selectedIndex: Int
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(Array(categories.enumerated()), id: \.offset) { index, category in
                    GuideCategoryButton(
                        category: category,
                        isSelected: selectedIndex == index
                    ) {
                        withAnimation(.spring(duration: 0.3)) {
                            selectedIndex = index
                        }
                    }
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
        }
        .background(Color.black.opacity(0.2))
    }
}

// MARK: - Guide Category Button

struct GuideCategoryButton: View {
    let category: any EffectCategoryProviding
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: category.icon)
                    .font(.system(size: 12))
                Text(category.name)
                    .font(.system(size: 12, weight: .medium))
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                Capsule()
                    .fill(isSelected ? category.color : Color.gray.opacity(0.3))
            )
            .foregroundStyle(isSelected ? .black : .white)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Category Description View

struct CategoryDescriptionView: View {
    let category: any EffectCategoryProviding
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: category.icon)
                .font(.title2)
                .foregroundStyle(category.color)
            
            Text(category.description)
                .font(.callout)
                .foregroundStyle(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(category.color.opacity(0.1))
    }
}

// MARK: - Effects List View

struct EffectsListView: View {
    let effects: [any EffectInfoProviding]
    @Binding var expandedEffectId: UUID?
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(Array(effects.enumerated()), id: \.offset) { index, effect in
                    if let effectModel = effect as? EffectInfoModel {
                        EffectCardView(
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

// MARK: - Effect Card View

struct EffectCardView: View {
    let effect: EffectInfoModel
    let isExpanded: Bool
    let onTap: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            EffectCardHeader(effect: effect, isExpanded: isExpanded, onTap: onTap)
            
            if isExpanded {
                EffectCardDetails(effect: effect)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .strokeBorder(
                            isExpanded ? effect.color.opacity(0.5) : Color.white.opacity(0.1),
                            lineWidth: 1
                        )
                )
        )
        .animation(.spring(duration: 0.3), value: isExpanded)
    }
}

// MARK: - Effect Card Header

struct EffectCardHeader: View {
    let effect: EffectInfoModel
    let isExpanded: Bool
    let onTap: () -> Void
    
    var body: some View {
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
                
                Text(effect.name)
                    .font(.headline)
                    .foregroundStyle(.white)
                
                Spacer()
                
                Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                    .foregroundStyle(.secondary)
            }
            .padding()
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Effect Card Details

struct EffectCardDetails: View {
    let effect: EffectInfoModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Divider()
                .background(effect.color.opacity(0.3))
            
            EffectDetailRow(
                title: "Function",
                content: effect.function,
                icon: "gearshape.fill",
                color: .cyan
            )
            
            EffectDetailRow(
                title: "Sound",
                content: effect.sound,
                icon: "speaker.wave.3.fill",
                color: .green
            )
            
            EffectDetailRow(
                title: "How to Use",
                content: effect.howToUse,
                icon: "hand.point.up.fill",
                color: .yellow
            )
            
            EffectDetailRow(
                title: "Signal Chain Position",
                content: effect.signalChainPosition,
                icon: "arrow.right.circle.fill",
                color: .orange
            )
            
            EffectDetailRow(
                title: "Famous Users",
                content: effect.famousUsers,
                icon: "star.fill",
                color: .purple
            )
        }
        .padding()
    }
}

// MARK: - Effect Detail Row

struct EffectDetailRow: View {
    let title: String
    let content: String
    let icon: String
    let color: Color
    
    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: icon)
                .foregroundStyle(color)
                .frame(width: 20)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.caption.bold())
                    .foregroundStyle(color)
                
                Text(content)
                    .font(.callout)
                    .foregroundStyle(.white.opacity(0.9))
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

// MARK: - Preview

#Preview {
    EffectGuideView()
}
