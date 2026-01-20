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
                    Image(systemName: "square.grid.3x3.fill")
                        .foregroundStyle(.orange)
                    Text("PEDALBOARD")
                        .font(.system(size: 14, weight: .bold, design: .monospaced))
                        .foregroundStyle(.white)
                }

                Spacer()

                // Add effect menu
                Menu {
                    ForEach(EffectType.allCases) { type in
                        Button {
                            withAnimation(.spring(duration: 0.3)) {
                                engine.addEffect(type)
                            }
                        } label: {
                            Label(type.rawValue, systemImage: type.icon)
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
                        PedalView(effect: effect, isSelected: false, onTap: {}, onDoubleTap: {}, onDelete: {})
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
            .padding(.vertical, 20)
            .padding(.horizontal)
        }
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.black.opacity(0.3))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .strokeBorder(Color.white.opacity(0.1), lineWidth: 1)
                )
        )
    }
}

// MARK: - Pedal View (Guitar Pedal Style)

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
                                ? [effect.type.color, effect.type.color.opacity(0.7)]
                                : [Color.gray.opacity(0.6), Color.gray.opacity(0.4)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .strokeBorder(
                                isSelected ? Color.white : Color.black.opacity(0.3),
                                lineWidth: isSelected ? 2 : 1
                            )
                    )
                    .shadow(color: effect.isEnabled ? effect.type.color.opacity(0.5) : .clear, radius: isSelected ? 10 : 5)

                VStack(spacing: 8) {
                    // LED indicator
                    Circle()
                        .fill(effect.isEnabled ? Color.green : Color.red.opacity(0.5))
                        .frame(width: 8, height: 8)
                        .shadow(color: effect.isEnabled ? .green : .clear, radius: 4)

                    // Effect icon
                    Image(systemName: effect.type.icon)
                        .font(.system(size: 24, weight: .medium))
                        .foregroundStyle(.white)

                    // Effect name
                    Text(effect.type.rawValue.uppercased())
                        .font(.system(size: 9, weight: .bold, design: .monospaced))
                        .foregroundStyle(.white.opacity(0.9))

                    // Footswitch
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [Color.gray.opacity(0.8), Color.gray.opacity(0.4)],
                                center: .center,
                                startRadius: 0,
                                endRadius: 15
                            )
                        )
                        .frame(width: 30, height: 30)
                        .overlay(
                            Circle()
                                .strokeBorder(Color.black.opacity(0.5), lineWidth: 2)
                        )
                }
                .padding(.vertical, 12)

                // Delete button on hover
                if isHovering {
                    VStack {
                        HStack {
                            Spacer()
                            Button(action: onDelete) {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.system(size: 16))
                                    .foregroundStyle(.white, .red)
                            }
                            .buttonStyle(.plain)
                        }
                        Spacer()
                    }
                    .padding(4)
                }
            }
            .frame(width: 80, height: 120)
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

    var body: some View {
        VStack(spacing: 16) {
            // Header
            HStack {
                Image(systemName: effect.type.icon)
                    .foregroundStyle(effect.type.color)
                Text(effect.type.rawValue)
                    .font(.headline)

                Spacer()

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

            // Knobs based on effect type
            HStack(spacing: 24) {
                switch effect.type {
                case .distortion:
                    KnobView(label: "DRIVE", value: binding(for: "drive"), range: 0...100, color: effect.type.color)
                    KnobView(label: "MIX", value: binding(for: "mix"), range: 0...100, color: effect.type.color)

                case .delay:
                    KnobView(label: "TIME", value: binding(for: "time"), range: 0...2, color: effect.type.color, format: "%.2fs")
                    KnobView(label: "FEEDBACK", value: binding(for: "feedback"), range: 0...100, color: effect.type.color)
                    KnobView(label: "MIX", value: binding(for: "mix"), range: 0...100, color: effect.type.color)

                case .reverb:
                    KnobView(label: "WET/DRY", value: binding(for: "wetDryMix"), range: 0...100, color: effect.type.color)

                case .equalizer:
                    KnobView(label: "BASS", value: binding(for: "bass"), range: -12...12, color: .red, format: "%.1fdB")
                    KnobView(label: "MID", value: binding(for: "mid"), range: -12...12, color: .yellow, format: "%.1fdB")
                    KnobView(label: "TREBLE", value: binding(for: "treble"), range: -12...12, color: .cyan, format: "%.1fdB")
                }
            }
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
    }

    private func binding(for key: String) -> Binding<Float> {
        Binding(
            get: { effect.parameters[key] ?? 0 },
            set: { engine.updateEffectParameter(effect, key: key, value: $0) }
        )
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
    }
}

// MARK: - Legacy Parameter Slider (kept for compatibility)

struct ParameterSlider: View {
    let label: String
    @Binding var value: Float
    let range: ClosedRange<Float>
    let color: Color
    var format: String = "%.0f%%"

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(label)
                    .font(.subheadline)
                Spacer()
                Text(String(format: format, value))
                    .font(.caption)
                    .monospacedDigit()
                    .foregroundStyle(.secondary)
            }

            Slider(value: $value, in: range)
                .tint(color)
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
