import SwiftUI

// MARK: - Effects Chain View (Pedalboard Style)

struct EffectsChainView: View {
    @Bindable var engine: AudioEngineManager
    @State private var selectedEffect: EffectNode?

    var body: some View {
        VStack(spacing: 16) {
            // Header
            HStack {
                HStack(spacing: 8) {
                    Image(systemName: "cable.connector.horizontal")
                        .foregroundStyle(.orange)
                    Text("PEDALBOARD")
                        .font(.system(size: 14, weight: .bold, design: .monospaced))
                        .foregroundStyle(.white)
                }

                Spacer()

                // Add effect menu - organized by category
                Menu {
                    ForEach(EffectCategory.allCases) { category in
                        Menu(category.rawValue) {
                            ForEach(EffectType.effectTypes(for: category)) { type in
                                Button(type.rawValue) {
                                    withAnimation(.spring(duration: 0.3)) {
                                        engine.addEffect(type)
                                    }
                                }
                            }
                        }
                    }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "plus")
                        Text("Add Pedal")
                    }
                    .font(.system(size: 12, weight: .semibold))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(.orange.gradient)
                    .foregroundStyle(.black)
                    .clipShape(Capsule())
                }
            }
            .padding(.horizontal)

            // Signal chain visualization
            SignalChainView(engine: engine, selectedEffect: $selectedEffect)

            // Parameter controls for selected effect
            if let effect = selectedEffect {
                PedalControlsView(effect: effect, engine: engine)
                    .transition(.asymmetric(
                        insertion: .move(edge: .bottom).combined(with: .opacity),
                        removal: .opacity
                    ))
            }
        }
        .padding()
        .animation(.spring(duration: 0.3), value: selectedEffect?.id)
    }
}

// MARK: - Signal Chain View

struct SignalChainView: View {
    @Bindable var engine: AudioEngineManager
    @Binding var selectedEffect: EffectNode?

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            signalChainContent
        }
        .background(signalChainBackground)
    }

    private var signalChainContent: some View {
        HStack(spacing: 0) {
            JackView(label: "IN", isInput: true)
            CableView()

            ForEach(Array(engine.effectsChain.enumerated()), id: \.element.id) { index, effect in
                pedalWithDragDrop(effect: effect, index: index)
                CableView()
            }

            JackView(label: "OUT", isInput: false)
        }
        .padding(.vertical, 20)
        .padding(.horizontal)
    }

    private func pedalWithDragDrop(effect: EffectNode, index: Int) -> some View {
        let isCurrentlySelected = selectedEffect?.id == effect.id

        return PedalView(
            effect: effect,
            isSelected: isCurrentlySelected,
            onTap: { handleTap(effect: effect) },
            onDoubleTap: { engine.toggleEffect(effect) },
            onDelete: { handleDelete(effect: effect, index: index) }
        )
        .draggable(effect.id.uuidString) {
            dragPreview(for: effect)
        }
        .dropDestination(for: String.self) { items, _ in
            return handleDrop(items: items, targetIndex: index)
        }
    }

    private func handleTap(effect: EffectNode) {
        if selectedEffect?.id == effect.id {
            selectedEffect = nil
        } else {
            selectedEffect = effect
        }
    }

    private func handleDelete(effect: EffectNode, index: Int) {
        withAnimation {
            if selectedEffect?.id == effect.id {
                selectedEffect = nil
            }
            engine.removeEffect(at: index)
        }
    }

    private func dragPreview(for effect: EffectNode) -> some View {
        PedalView(effect: effect, isSelected: false, onTap: {}, onDoubleTap: {}, onDelete: {})
            .opacity(0.7)
            .scaleEffect(0.9)
    }

    private func handleDrop(items: [String], targetIndex: Int) -> Bool {
        guard let droppedId = items.first else { return false }
        guard let sourceIndex = engine.effectsChain.firstIndex(where: { $0.id.uuidString == droppedId }) else { return false }
        guard sourceIndex != targetIndex else { return false }

        let destination = targetIndex > sourceIndex ? targetIndex + 1 : targetIndex
        withAnimation(.spring(duration: 0.3)) {
            engine.moveEffect(from: IndexSet(integer: sourceIndex), to: destination)
        }
        return true
    }

    private var signalChainBackground: some View {
        RoundedRectangle(cornerRadius: 16)
            .fill(Color.black.opacity(0.3))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .strokeBorder(Color.white.opacity(0.1), lineWidth: 1)
            )
    }
}

// MARK: - Pedal View (Clean Guitar Pedal Style)

struct PedalView: View {
    let effect: EffectNode
    let isSelected: Bool
    let onTap: () -> Void
    let onDoubleTap: () -> Void
    let onDelete: () -> Void

    @State private var isHovering = false

    var body: some View {
        VStack(spacing: 0) {
            // Pedal body
            ZStack {
                // Metal enclosure
                RoundedRectangle(cornerRadius: 8)
                    .fill(
                        LinearGradient(
                            colors: effect.isEnabled
                                ? [effect.type.color.opacity(0.9), effect.type.color.opacity(0.6)]
                                : [Color.gray.opacity(0.5), Color.gray.opacity(0.3)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .strokeBorder(
                                isSelected ? Color.white : Color.black.opacity(0.4),
                                lineWidth: isSelected ? 2 : 1
                            )
                    )
                    .shadow(color: effect.isEnabled ? effect.type.color.opacity(0.4) : .clear, radius: isSelected ? 8 : 4)

                VStack(spacing: 6) {
                    // LED indicator
                    Circle()
                        .fill(effect.isEnabled ? Color.green : Color.red.opacity(0.4))
                        .frame(width: 6, height: 6)
                        .shadow(color: effect.isEnabled ? .green : .clear, radius: 3)

                    // Effect abbreviation (clean text, no icons)
                    Text(effect.type.abbreviation)
                        .font(.system(size: 18, weight: .bold, design: .monospaced))
                        .foregroundStyle(.white)

                    // Full effect name
                    Text(effect.type.rawValue)
                        .font(.system(size: 8, weight: .medium))
                        .foregroundStyle(.white.opacity(0.8))
                        .lineLimit(1)

                    // Footswitch
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [Color.gray.opacity(0.7), Color.gray.opacity(0.3)],
                                center: .center,
                                startRadius: 0,
                                endRadius: 12
                            )
                        )
                        .frame(width: 26, height: 26)
                        .overlay(
                            Circle()
                                .strokeBorder(Color.black.opacity(0.4), lineWidth: 1.5)
                        )
                }
                .padding(.vertical, 10)

                // Delete button on hover
                if isHovering {
                    VStack {
                        HStack {
                            Spacer()
                            Button(action: onDelete) {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.system(size: 14))
                                    .foregroundStyle(.white, .red)
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel("Remove \(effect.type.rawValue) pedal")
                        }
                        Spacer()
                    }
                    .padding(4)
                }
            }
            .frame(width: 75, height: 110)
            .onTapGesture(count: 2) { onDoubleTap() }
            .onTapGesture { onTap() }
            .onHover { isHovering = $0 }
        }
        // Accessibility
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(effect.type.rawValue) pedal, \(effect.isEnabled ? "enabled" : "bypassed")")
        .accessibilityHint("Tap to select, double-tap to toggle on or off")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

// MARK: - Jack View

struct JackView: View {
    let label: String
    let isInput: Bool

    var body: some View {
        VStack(spacing: 4) {
            // Jack housing
            ZStack {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 40, height: 50)

                Circle()
                    .fill(
                        RadialGradient(
                            colors: [Color.black, Color.gray.opacity(0.5)],
                            center: .center,
                            startRadius: 0,
                            endRadius: 12
                        )
                    )
                    .frame(width: 24, height: 24)
                    .overlay(
                        Circle()
                            .strokeBorder(Color.gray, lineWidth: 2)
                    )
            }

            Text(label)
                .font(.system(size: 10, weight: .bold, design: .monospaced))
                .foregroundStyle(isInput ? .green : .cyan)
        }
    }
}

// MARK: - Cable View

struct CableView: View {
    var body: some View {
        Rectangle()
            .fill(
                LinearGradient(
                    colors: [.gray.opacity(0.3), .gray.opacity(0.5), .gray.opacity(0.3)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .frame(width: 30, height: 4)
            .overlay(
                Rectangle()
                    .fill(Color.cyan.opacity(0.3))
                    .frame(height: 2)
            )
    }
}

// MARK: - Pedal Controls View

struct PedalControlsView: View {
    @Bindable var effect: EffectNode
    let engine: AudioEngineManager
    @State private var showingInfo = false

    var body: some View {
        VStack(spacing: 16) {
            // Header
            HStack {
                Text(effect.type.abbreviation)
                    .font(.system(size: 14, weight: .bold, design: .monospaced))
                    .foregroundStyle(effect.type.color)
                Text(effect.type.rawValue)
                    .font(.headline)

                Spacer()

                // Info button
                Button {
                    withAnimation { showingInfo.toggle() }
                } label: {
                    Image(systemName: showingInfo ? "info.circle.fill" : "info.circle")
                        .foregroundStyle(showingInfo ? effect.type.color : .secondary)
                }
                .buttonStyle(.plain)

                // Bypass toggle
                Toggle("", isOn: Binding(
                    get: { effect.isEnabled },
                    set: { _ in engine.toggleEffect(effect) }
                ))
                .toggleStyle(.switch)
                .tint(effect.type.color)
            }

            Divider()
                .background(Color.white.opacity(0.2))

            // Educational content
            if showingInfo {
                EffectEducationView(effectType: effect.type)
                    .transition(.asymmetric(
                        insertion: .move(edge: .top).combined(with: .opacity),
                        removal: .opacity
                    ))

                Divider()
                    .background(Color.white.opacity(0.2))
            }

            // Knobs based on effect type
            EffectKnobsView(effect: effect, binding: binding)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .strokeBorder(effect.type.color.opacity(0.3), lineWidth: 1)
                )
        )
        .animation(.spring(duration: 0.3), value: showingInfo)
    }

    private func binding(for key: String) -> Binding<Float> {
        Binding(
            get: { effect.parameters[key] ?? 0 },
            set: { engine.updateEffectParameter(effect, key: key, value: $0) }
        )
    }
}

// MARK: - Effect Education View

struct EffectEducationView: View {
    let effectType: EffectType

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // What it does
            EducationSection(
                title: "What It Does",
                icon: "questionmark.circle",
                content: effectType.effectDescription,
                color: effectType.color
            )

            // How to use
            EducationSection(
                title: "How To Use",
                icon: "hand.point.up",
                content: effectType.howToUse,
                color: .green
            )

            // Signal chain position
            EducationSection(
                title: "Signal Chain Position",
                icon: "arrow.right.circle",
                content: effectType.signalChainPosition,
                color: .cyan
            )

            // Genres
            HStack(alignment: .top, spacing: 8) {
                Image(systemName: "music.note.list")
                    .foregroundStyle(.purple)
                    .frame(width: 20)

                VStack(alignment: .leading, spacing: 4) {
                    Text("Common Genres")
                        .font(.caption.bold())
                        .foregroundStyle(.purple)

                    FlowLayout(spacing: 4) {
                        ForEach(effectType.commonGenres, id: \.self) { genre in
                            Text(genre)
                                .font(.caption2)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.purple.opacity(0.2))
                                .foregroundStyle(.purple)
                                .clipShape(Capsule())
                        }
                    }
                }
            }

            // Famous examples
            EducationSection(
                title: "Famous Examples",
                icon: "star.fill",
                content: effectType.famousExamples,
                color: .yellow
            )
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.black.opacity(0.3))
        )
    }
}

// MARK: - Education Section

struct EducationSection: View {
    let title: String
    let icon: String
    let content: String
    let color: Color

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: icon)
                .foregroundStyle(color)
                .frame(width: 20)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.caption.bold())
                    .foregroundStyle(color)

                Text(content)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

// MARK: - Flow Layout for Tags

struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = FlowResult(in: proposal.width ?? 0, subviews: subviews, spacing: spacing)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = FlowResult(in: bounds.width, subviews: subviews, spacing: spacing)
        for (index, subview) in subviews.enumerated() {
            subview.place(at: CGPoint(x: bounds.minX + result.positions[index].x,
                                       y: bounds.minY + result.positions[index].y),
                          proposal: .unspecified)
        }
    }

    struct FlowResult {
        var size: CGSize = .zero
        var positions: [CGPoint] = []

        init(in maxWidth: CGFloat, subviews: Subviews, spacing: CGFloat) {
            var x: CGFloat = 0
            var y: CGFloat = 0
            var rowHeight: CGFloat = 0

            for subview in subviews {
                let size = subview.sizeThatFits(.unspecified)

                if x + size.width > maxWidth && x > 0 {
                    x = 0
                    y += rowHeight + spacing
                    rowHeight = 0
                }

                positions.append(CGPoint(x: x, y: y))
                rowHeight = max(rowHeight, size.height)
                x += size.width + spacing

                self.size.width = max(self.size.width, x)
            }

            self.size.height = y + rowHeight
        }
    }
}

// MARK: - Effect Knobs View

struct EffectKnobsView: View {
    let effect: EffectNode
    let binding: (String) -> Binding<Float>

    var body: some View {
        HStack(spacing: 24) {
            switch effect.type {
            // Dynamics
            case .compressor:
                KnobView(label: "THRESHOLD", value: binding("threshold"), range: -40...0, color: effect.type.color, format: "%.0fdB")
                KnobView(label: "RATIO", value: binding("ratio"), range: 1...20, color: effect.type.color, format: "%.1f:1")
                KnobView(label: "ATTACK", value: binding("attack"), range: 0.1...100, color: effect.type.color, format: "%.0fms")

            // Filter & Pitch
            case .equalizer:
                KnobView(label: "BASS", value: binding("bass"), range: -12...12, color: .red, format: "%.1fdB")
                KnobView(label: "MID", value: binding("mid"), range: -12...12, color: .yellow, format: "%.1fdB")
                KnobView(label: "TREBLE", value: binding("treble"), range: -12...12, color: .cyan, format: "%.1fdB")

            // Gain / Dirt
            case .overdrive:
                KnobView(label: "DRIVE", value: binding("drive"), range: 0...100, color: effect.type.color)
                KnobView(label: "TONE", value: binding("tone"), range: 0...100, color: effect.type.color)
                KnobView(label: "LEVEL", value: binding("level"), range: 0...100, color: effect.type.color)

            case .distortion:
                KnobView(label: "DRIVE", value: binding("drive"), range: 0...100, color: effect.type.color)
                KnobView(label: "TONE", value: binding("tone"), range: 0...100, color: effect.type.color)
                KnobView(label: "LEVEL", value: binding("level"), range: 0...100, color: effect.type.color)

            case .fuzz:
                KnobView(label: "FUZZ", value: binding("fuzz"), range: 0...100, color: effect.type.color)
                KnobView(label: "TONE", value: binding("tone"), range: 0...100, color: effect.type.color)
                KnobView(label: "LEVEL", value: binding("level"), range: 0...100, color: effect.type.color)

            // Modulation
            case .chorus:
                KnobView(label: "RATE", value: binding("rate"), range: 0.1...10, color: effect.type.color, format: "%.1fHz")
                KnobView(label: "DEPTH", value: binding("depth"), range: 0...100, color: effect.type.color)
                KnobView(label: "MIX", value: binding("mix"), range: 0...100, color: effect.type.color)

            case .phaser:
                KnobView(label: "RATE", value: binding("rate"), range: 0.1...5, color: effect.type.color, format: "%.1fHz")
                KnobView(label: "DEPTH", value: binding("depth"), range: 0...100, color: effect.type.color)
                KnobView(label: "FEEDBACK", value: binding("feedback"), range: 0...100, color: effect.type.color)

            case .flanger:
                KnobView(label: "RATE", value: binding("rate"), range: 0.1...2, color: effect.type.color, format: "%.2fHz")
                KnobView(label: "DEPTH", value: binding("depth"), range: 0...100, color: effect.type.color)
                KnobView(label: "FEEDBACK", value: binding("feedback"), range: 0...100, color: effect.type.color)

            case .tremolo:
                KnobView(label: "RATE", value: binding("rate"), range: 0.5...15, color: effect.type.color, format: "%.1fHz")
                KnobView(label: "DEPTH", value: binding("depth"), range: 0...100, color: effect.type.color)

            // Time & Ambience
            case .delay:
                KnobView(label: "TIME", value: binding("time"), range: 0...2, color: effect.type.color, format: "%.2fs")
                KnobView(label: "FEEDBACK", value: binding("feedback"), range: 0...100, color: effect.type.color)
                KnobView(label: "MIX", value: binding("mix"), range: 0...100, color: effect.type.color)

            case .reverb:
                KnobView(label: "WET/DRY", value: binding("wetDryMix"), range: 0...100, color: effect.type.color)
                KnobView(label: "DECAY", value: binding("decay"), range: 0.1...5, color: effect.type.color, format: "%.1fs")
            }
        }
    }
}

// MARK: - Knob View (Amp-style rotary knob)

struct KnobView: View {
    let label: String
    @Binding var value: Float
    let range: ClosedRange<Float>
    let color: Color
    var format: String = "%.0f"

    @State private var isDragging = false

    private var normalizedValue: Double {
        Double((value - range.lowerBound) / (range.upperBound - range.lowerBound))
    }

    private var rotation: Angle {
        .degrees(-135 + normalizedValue * 270)
    }

    var body: some View {
        VStack(spacing: 8) {
            // Knob
            ZStack {
                // Knob background
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [Color.gray.opacity(0.4), Color.gray.opacity(0.2)],
                            center: .center,
                            startRadius: 0,
                            endRadius: 25
                        )
                    )
                    .frame(width: 50, height: 50)
                    .overlay(
                        Circle()
                            .strokeBorder(Color.black.opacity(0.5), lineWidth: 2)
                    )

                // Knob cap
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color.gray.opacity(0.8), Color.gray.opacity(0.4)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 40, height: 40)
                    .overlay(
                        // Indicator line
                        Rectangle()
                            .fill(color)
                            .frame(width: 3, height: 12)
                            .offset(y: -10)
                    )
                    .rotationEffect(rotation)
                    .shadow(color: isDragging ? color.opacity(0.5) : .clear, radius: 5)

                // Value arc
                Circle()
                    .trim(from: 0, to: normalizedValue * 0.75)
                    .stroke(color, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                    .frame(width: 56, height: 56)
                    .rotationEffect(.degrees(135))
            }
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { gesture in
                        isDragging = true
                        let delta = Float(-gesture.translation.height / 100)
                        let newValue = value + delta * (range.upperBound - range.lowerBound) * 0.1
                        value = min(max(newValue, range.lowerBound), range.upperBound)
                    }
                    .onEnded { _ in
                        isDragging = false
                    }
            )

            // Label and value
            VStack(spacing: 2) {
                Text(label)
                    .font(.system(size: 9, weight: .bold, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.7))

                Text(String(format: format, value))
                    .font(.system(size: 10, weight: .medium, design: .monospaced))
                    .foregroundStyle(color)
            }
        }
        // Accessibility
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(label)")
        .accessibilityValue(String(format: format, value))
        .accessibilityHint("Drag up to increase, down to decrease")
        .accessibilityAdjustableAction { direction in
            let step = (range.upperBound - range.lowerBound) * 0.05
            switch direction {
            case .increment:
                value = min(value + step, range.upperBound)
            case .decrement:
                value = max(value - step, range.lowerBound)
            @unknown default:
                break
            }
        }
    }
}

// MARK: - Preview

#Preview {
    EffectsChainView(engine: AudioEngineManager())
        .frame(height: 500)
        .padding()
        .background(Color.black)
}

