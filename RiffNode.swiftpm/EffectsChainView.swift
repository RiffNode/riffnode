import SwiftUI

// MARK: - Effects Chain View (Pedalboard Style with Liquid Glass)

struct EffectsChainView: View {
    @Bindable var engine: AudioEngineManager
    @State private var selectedEffect: EffectNode?
    @Namespace private var effectsNamespace

    var body: some View {
        VStack(spacing: 16) {
            // Header
            GlassEffectContainer(spacing: 12) {
                HStack {
                    HStack(spacing: 8) {
                        Image(systemName: "cable.connector.horizontal")
                            .foregroundStyle(.cyan)
                        Text("SIGNAL CHAIN")
                            .font(.system(size: 14, weight: .semibold, design: .monospaced))
                            .foregroundStyle(.white)
                    }

                    Spacer()

                    // Add effect menu - organized by category
                    Menu {
                        ForEach(EffectCategory.allCases) { category in
                            Menu {
                                ForEach(EffectType.effectTypes(for: category)) { type in
                                    Button {
                                        withAnimation(.spring(duration: 0.3)) {
                                            engine.addEffect(type)
                                        }
                                    } label: {
                                        Text(type.rawValue)
                                    }
                                }
                            } label: {
                                Label(category.rawValue, systemImage: category.icon)
                            }
                        }
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "plus")
                            Text("Add Pedal")
                        }
                        .font(.system(size: 12, weight: .semibold))
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                    }
                    .buttonStyle(.glassProminent)
                }
                .padding(.horizontal)
            }

            // Signal chain visualization
            SignalChainView(engine: engine, selectedEffect: $selectedEffect, namespace: effectsNamespace)

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
    let namespace: Namespace.ID

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            GlassEffectContainer(spacing: 20) {
                HStack(spacing: 0) {
                    // Input jack
                    JackView(label: "IN", isInput: true)

                    // Cable segment
                    CableView()

                    // Effect pedals
                    ForEach(Array(engine.effectsChain.enumerated()), id: \.element.id) { index, effect in
                        PedalView(
                            effect: effect,
                            isSelected: selectedEffect?.id == effect.id,
                            namespace: namespace,
                            onTap: { selectedEffect = selectedEffect?.id == effect.id ? nil : effect },
                            onDoubleTap: { engine.toggleEffect(effect) },
                            onDelete: {
                                withAnimation {
                                    if selectedEffect?.id == effect.id { selectedEffect = nil }
                                    engine.removeEffect(at: index)
                                }
                            }
                        )
                        .draggable(effect.id.uuidString) {
                            PedalView(effect: effect, isSelected: false, namespace: namespace, onTap: {}, onDoubleTap: {}, onDelete: {})
                                .opacity(0.7)
                                .scaleEffect(0.9)
                        }
                        .dropDestination(for: String.self) { items, _ in
                            guard let droppedId = items.first,
                                  let sourceIndex = engine.effectsChain.firstIndex(where: { $0.id.uuidString == droppedId }),
                                  sourceIndex != index else { return false }
                            withAnimation(.spring(duration: 0.3)) {
                                engine.moveEffect(from: IndexSet(integer: sourceIndex), to: index > sourceIndex ? index + 1 : index)
                            }
                            return true
                        }

                        CableView()
                    }

                    // Output jack
                    JackView(label: "OUT", isInput: false)
                }
                .padding(.vertical, 24)
                .padding(.horizontal)
            }
        }
        .glassEffect(in: .rect(cornerRadius: 20))
    }
}

// MARK: - Pedal View (Modern Liquid Glass Style)

struct PedalView: View {
    let effect: EffectNode
    let isSelected: Bool
    let namespace: Namespace.ID
    let onTap: () -> Void
    let onDoubleTap: () -> Void
    let onDelete: () -> Void

    @State private var isHovering = false

    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                // Pedal content
                VStack(spacing: 10) {
                    // LED indicator
                    Circle()
                        .fill(effect.isEnabled ? Color.green : Color.red.opacity(0.4))
                        .frame(width: 8, height: 8)
                        .shadow(color: effect.isEnabled ? .green.opacity(0.8) : .clear, radius: 6)

                    // Effect name only - no icon clutter
                    Text(effect.type.rawValue.uppercased())
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundStyle(.white)

                    // Footswitch
                    Circle()
                        .fill(Color.white.opacity(0.1))
                        .frame(width: 28, height: 28)
                        .overlay(
                            Circle()
                                .strokeBorder(Color.white.opacity(0.3), lineWidth: 1)
                        )
                }
                .padding(.vertical, 16)

                // Delete button on hover
                if isHovering {
                    VStack {
                        HStack {
                            Spacer()
                            Button(action: onDelete) {
                                Image(systemName: "xmark")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundStyle(.white)
                                    .frame(width: 20, height: 20)
                            }
                            .buttonStyle(.glass)
                        }
                        Spacer()
                    }
                    .padding(4)
                }
            }
            .frame(width: 80, height: 110)
            .glassEffect(
                effect.isEnabled 
                    ? .regular.tint(effect.type.color).interactive()
                    : .regular.tint(.gray).interactive(),
                in: .rect(cornerRadius: 12)
            )
            .glassEffectID(effect.id.uuidString, in: namespace)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(
                        isSelected ? Color.white : Color.clear,
                        lineWidth: 2
                    )
            )
            .onTapGesture(count: 2) { onDoubleTap() }
            .onTapGesture { onTap() }
            .onHover { isHovering = $0 }
        }
    }
}

// MARK: - Jack View

struct JackView: View {
    let label: String
    let isInput: Bool

    var body: some View {
        VStack(spacing: 6) {
            ZStack {
                Circle()
                    .fill(Color.black.opacity(0.6))
                    .frame(width: 20, height: 20)
                    .overlay(
                        Circle()
                            .strokeBorder(Color.gray.opacity(0.5), lineWidth: 2)
                    )
            }
            .frame(width: 36, height: 44)
            .glassEffect(in: .rect(cornerRadius: 8))

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
                    colors: [.cyan.opacity(0.2), .cyan.opacity(0.4), .cyan.opacity(0.2)],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .frame(width: 24, height: 3)
    }
}

// MARK: - Pedal Controls View

struct PedalControlsView: View {
    @Bindable var effect: EffectNode
    let engine: AudioEngineManager
    @State private var showingInfo = false

    var body: some View {
        GlassEffectContainer(spacing: 12) {
            VStack(spacing: 16) {
                // Header
                HStack {
                    Text(effect.type.rawValue)
                        .font(.headline)
                        .foregroundStyle(.white)

                    Spacer()

                    // Info button
                    Button {
                        withAnimation { showingInfo.toggle() }
                    } label: {
                        Image(systemName: "info")
                            .font(.system(size: 12))
                            .frame(width: 28, height: 28)
                    }
                    .buttonStyle(.glass)

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
        }
        .glassEffect(.regular.tint(effect.type.color.opacity(0.3)), in: .rect(cornerRadius: 20))
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
                content: effectType.effectDescription,
                color: effectType.color
            )

            // How to use
            EducationSection(
                title: "How To Use",
                content: effectType.howToUse,
                color: .green
            )

            // Signal chain position
            EducationSection(
                title: "Signal Chain Position",
                content: effectType.signalChainPosition,
                color: .cyan
            )

            // Genres
            VStack(alignment: .leading, spacing: 6) {
                Text("Common Genres")
                    .font(.caption.bold())
                    .foregroundStyle(.purple)

                FlowLayout(spacing: 4) {
                    ForEach(effectType.commonGenres, id: \.self) { genre in
                        Text(genre)
                            .font(.caption2)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .glassEffect(.regular.tint(.purple), in: .capsule)
                    }
                }
            }

            // Famous examples
            EducationSection(
                title: "Famous Examples",
                content: effectType.famousExamples,
                color: .orange
            )
        }
        .padding()
        .glassEffect(in: .rect(cornerRadius: 12))
    }
}

// MARK: - Education Section

struct EducationSection: View {
    let title: String
    let content: String
    let color: Color

    var body: some View {
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

// MARK: - Knob View (Clean Glass Style)

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
                // Knob cap with indicator
                Circle()
                    .fill(Color.white.opacity(0.1))
                    .frame(width: 44, height: 44)
                    .overlay(
                        // Indicator line
                        Rectangle()
                            .fill(color)
                            .frame(width: 3, height: 10)
                            .offset(y: -12)
                    )
                    .rotationEffect(rotation)

                // Value arc
                Circle()
                    .trim(from: 0, to: normalizedValue * 0.75)
                    .stroke(color, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                    .frame(width: 52, height: 52)
                    .rotationEffect(.degrees(135))
            }
            .glassEffect(.regular.interactive(), in: .circle)
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
                    .font(.system(size: 9, weight: .semibold, design: .monospaced))
                    .foregroundStyle(.secondary)

                Text(String(format: format, value))
                    .font(.system(size: 10, weight: .medium, design: .monospaced))
                    .foregroundStyle(color)
            }
        }
    }
}

// MARK: - Preview

#Preview {
    EffectsChainView(engine: AudioEngineManager())
        .frame(height: 500)
        .padding()
        .background(Color(red: 0.05, green: 0.05, blue: 0.1))
}

