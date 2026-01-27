import SwiftUI

// MARK: - Guided Tour View
// Liquid Glass UI Design - iOS 26+
// An interactive 3-minute educational experience about guitar effects

struct GuidedTourView: View {
    @Bindable var engine: AudioEngineManager
    let onComplete: () -> Void

    @State private var currentStep = 0
    @State private var showingEffect = false
    @State private var demoEffect: EffectType = .distortion
    @State private var savedEffectStates: [EffectType: Bool] = [:]
    @Namespace private var tourNamespace

    private let tourSteps: [TourStep] = [
        TourStep(
            title: "Welcome to RiffNode",
            subtitle: "Your Guitar Effects Playground",
            content: "Ever wondered how guitarists create those amazing sounds? From the crunchy distortion of rock to the spacey echoes of ambient music - it's all about effects pedals.",
            highlightEffect: nil,
            actionLabel: "Let's Explore"
        ),
        TourStep(
            title: "The Signal Chain",
            subtitle: "How Sound Flows",
            content: "Your guitar signal flows through a chain of effects, each one transforming the sound. The order matters - distortion before reverb sounds very different from reverb before distortion!",
            highlightEffect: nil,
            actionLabel: "Show Me"
        ),
        TourStep(
            title: "Distortion",
            subtitle: "The Sound of Rock",
            content: "Distortion clips your audio signal, creating that gritty, aggressive tone. From subtle warmth to full metal crunch - this effect defined rock music. Used by Metallica, AC/DC, and Nirvana.",
            highlightEffect: .distortion,
            actionLabel: "Hear It"
        ),
        TourStep(
            title: "Delay",
            subtitle: "Echoes in Time",
            content: "Delay repeats your notes like an echo. Short delays add thickness, longer delays create rhythmic patterns. Think U2's 'Where The Streets Have No Name' - that's delay magic!",
            highlightEffect: .delay,
            actionLabel: "Try Delay"
        ),
        TourStep(
            title: "Reverb",
            subtitle: "Creating Space",
            content: "Reverb simulates how sound bounces in physical spaces. A small room, a concert hall, or a massive cathedral - reverb puts your guitar anywhere. Essential for that 'polished' sound.",
            highlightEffect: .reverb,
            actionLabel: "Add Space"
        ),
        TourStep(
            title: "Chorus",
            subtitle: "Shimmer & Width",
            content: "Chorus makes one guitar sound like several playing together, slightly out of tune. It creates a lush, shimmering quality. The secret behind Nirvana's 'Come As You Are'.",
            highlightEffect: .chorus,
            actionLabel: "Hear Chorus"
        ),
        TourStep(
            title: "You're Ready!",
            subtitle: "Start Creating",
            content: "Now you understand the basics of guitar effects. Experiment with different combinations, adjust the knobs, and discover your own signature sound. There are no wrong answers - only new discoveries!",
            highlightEffect: nil,
            actionLabel: "Start Playing"
        )
    ]

    var body: some View {
        ZStack {
            AdaptiveBackground()

            VStack(spacing: 0) {
                // Progress indicator
                GlassProgressBar(
                    progress: Double(currentStep) / Double(tourSteps.count - 1),
                    steps: tourSteps.count,
                    currentStep: currentStep
                )
                .padding(.horizontal, 40)
                .padding(.top, 20)

                Spacer()

                // Main content
                let step = tourSteps[currentStep]

                VStack(spacing: 24) {
                    // Effect visualization if applicable
                    if let effectType = step.highlightEffect {
                        GlassEffectDemoView(effectType: effectType, isActive: showingEffect)
                            .frame(height: 150)
                            .transition(.scale.combined(with: .opacity))
                    }

                    // Text content in glass card
                    GlassCard(tint: step.highlightEffect?.color ?? .cyan, cornerRadius: 20) {
                        VStack(spacing: 12) {
                            Text(step.title)
                                .font(.system(size: 28, weight: .bold))

                            Text(step.subtitle)
                                .font(.title3)
                                .foregroundStyle(step.highlightEffect?.color ?? .cyan)

                            Text(step.content)
                                .font(.body)
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.top, 4)
                        }
                    }
                    .padding(.horizontal, 24)
                }
                .id(currentStep)
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing).combined(with: .opacity),
                    removal: .move(edge: .leading).combined(with: .opacity)
                ))

                Spacer()

                // Navigation
                GlassTourNavigation(
                    currentStep: currentStep,
                    actionLabel: tourSteps[currentStep].actionLabel,
                    onBack: {
                        withAnimation(.spring(duration: 0.4)) {
                            showingEffect = false
                            currentStep -= 1
                        }
                    },
                    onNext: handleAction,
                    namespace: tourNamespace
                )
                .padding(.bottom, 40)

                // Skip option
                Button("Skip Tour") {
                    onComplete()
                }
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .padding(.bottom, 20)
            }
        }
        .onAppear {
            saveAndBypassAllEffects()
        }
        .onDisappear {
            restoreEffectStates()
        }
    }

    private func handleAction() {
        let step = tourSteps[currentStep]

        if let effectType = step.highlightEffect {
            if !showingEffect {
                withAnimation(.spring(duration: 0.3)) {
                    showingEffect = true
                    demoEffect = effectType
                }
                enableDemoEffect(effectType)
                return
            } else {
                disableDemoEffect(effectType)
            }
        }

        if currentStep < tourSteps.count - 1 {
            withAnimation(.spring(duration: 0.4)) {
                showingEffect = false
                currentStep += 1
            }
            if let previousEffect = tourSteps[currentStep - 1].highlightEffect {
                disableDemoEffect(previousEffect)
            }
        } else {
            restoreEffectStates()
            onComplete()
        }
    }

    private func saveAndBypassAllEffects() {
        savedEffectStates.removeAll()

        for effect in engine.effectsChain {
            savedEffectStates[effect.type] = effect.isEnabled

            if effect.isEnabled {
                engine.toggleEffect(effect)
            }
        }
    }

    private func restoreEffectStates() {
        for effect in engine.effectsChain {
            let shouldBeEnabled = savedEffectStates[effect.type] ?? false
            if effect.isEnabled != shouldBeEnabled {
                engine.toggleEffect(effect)
            }
        }
    }

    private func enableDemoEffect(_ type: EffectType) {
        if let effect = engine.effectsChain.first(where: { $0.type == type }) {
            if !effect.isEnabled {
                engine.toggleEffect(effect)
            }
        } else {
            engine.addEffect(type)
        }
    }

    private func disableDemoEffect(_ type: EffectType) {
        if let effect = engine.effectsChain.first(where: { $0.type == type }) {
            if effect.isEnabled {
                engine.toggleEffect(effect)
            }
        }
    }
}

// MARK: - Tour Step Model

struct TourStep {
    let title: String
    let subtitle: String
    let content: String
    let highlightEffect: EffectType?
    let actionLabel: String
}

// MARK: - Glass Progress Bar

struct GlassProgressBar: View {
    let progress: Double
    let steps: Int
    let currentStep: Int

    var body: some View {
        VStack(spacing: 8) {
            // Step indicators
            HStack(spacing: 0) {
                ForEach(0..<steps, id: \.self) { step in
                    Circle()
                        .fill(step <= currentStep ? Color.cyan : Color.white.opacity(0.3))
                        .frame(width: 8, height: 8)
                        .overlay {
                            if step == currentStep {
                                Circle()
                                    .stroke(Color.cyan, lineWidth: 2)
                                    .frame(width: 14, height: 14)
                            }
                        }

                    if step < steps - 1 {
                        Rectangle()
                            .fill(step < currentStep ? Color.cyan : Color.white.opacity(0.2))
                            .frame(height: 2)
                    }
                }
            }
            .glassEffect(.clear, in: Capsule())

            // Step counter
            Text("Step \(currentStep + 1) of \(steps)")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}

// MARK: - Glass Effect Demo View

struct GlassEffectDemoView: View {
    let effectType: EffectType
    let isActive: Bool
    @Namespace private var demoNamespace

    var body: some View {
        VStack(spacing: 16) {
            // Visual representation of the effect
            ZStack {
                // Background glow
                Circle()
                    .fill(effectType.color.opacity(isActive ? 0.3 : 0.1))
                    .frame(width: 120, height: 120)
                    .blur(radius: isActive ? 20 : 10)

                // Glass effect pedal
                VStack(spacing: 8) {
                    // LED indicator
                    Circle()
                        .fill(isActive ? Color.green : Color.red.opacity(0.5))
                        .frame(width: 10, height: 10)
                        .shadow(color: isActive ? .green : .clear, radius: 6)

                    // Effect abbreviation
                    Text(effectType.abbreviation)
                        .font(.system(size: 20, weight: .bold))

                    // Effect name
                    Text(effectType.rawValue)
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(.secondary)
                }
                .frame(width: 80, height: 100)
                .glassEffect(
                    isActive ? .regular.tint(effectType.color) : .regular,
                    in: RoundedRectangle(cornerRadius: 12)
                )
                .glassEffectID("demoPedal", in: demoNamespace)
                .shadow(color: isActive ? effectType.color.opacity(0.5) : .clear, radius: 10)
            }

            // Waveform visualization
            GlassWaveformDemo(isActive: isActive, color: effectType.color)
                .frame(height: 40)
                .padding(.horizontal, 40)
        }
    }
}

// MARK: - Glass Waveform Demo

struct GlassWaveformDemo: View {
    let isActive: Bool
    let color: Color

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8)
                .fill(.black.opacity(0.2))

            TimelineView(.animation) { timeline in
                Canvas { context, size in
                    let midY = size.height / 2
                    var path = Path()

                    let date = timeline.date.timeIntervalSinceReferenceDate
                    let animatedPhase = isActive ? date * 3 : 0

                    path.move(to: CGPoint(x: 0, y: midY))

                    for x in stride(from: 0, through: size.width, by: 2) {
                        let relativeX = Double(x / size.width)
                        let amplitude = isActive ? Double(size.height) * 0.35 : Double(size.height) * 0.1

                        let wave1 = sin(relativeX * Double.pi * 4 + animatedPhase)
                        let wave2 = isActive ? sin(relativeX * Double.pi * 8 + animatedPhase * 1.5) * 0.3 : 0

                        let y = Double(midY) + (wave1 + wave2) * amplitude
                        path.addLine(to: CGPoint(x: x, y: y))
                    }

                    context.stroke(
                        path,
                        with: .linearGradient(
                            Gradient(colors: [color.opacity(0.8), color]),
                            startPoint: .zero,
                            endPoint: CGPoint(x: size.width, y: 0)
                        ),
                        lineWidth: 2
                    )
                }
            }
            .padding(4)
        }
        .glassEffect(.clear, in: RoundedRectangle(cornerRadius: 8))
    }
}

// MARK: - Glass Tour Navigation

struct GlassTourNavigation: View {
    let currentStep: Int
    let actionLabel: String
    let onBack: () -> Void
    let onNext: () -> Void
    var namespace: Namespace.ID

    var body: some View {
        GlassEffectContainer(spacing: 12) {
            if currentStep > 0 {
                Button(action: onBack) {
                    HStack(spacing: 6) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 14, weight: .semibold))
                        Text("Back")
                            .font(.headline)
                    }
                    .frame(minWidth: 80)
                    .padding(.vertical, 12)
                    .padding(.horizontal, 16)
                }
                .glassEffect(.regular.interactive(), in: Capsule())
                .glassEffectID("backButton", in: namespace)
            }

            Button(action: onNext) {
                HStack(spacing: 6) {
                    Text(actionLabel)
                        .font(.headline)
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .semibold))
                }
                .foregroundStyle(.white)
                .frame(minWidth: 140)
                .padding(.vertical, 12)
                .padding(.horizontal, 20)
                .background {
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [.cyan, .cyan.opacity(0.8)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                }
            }
            .glassEffect(.clear.interactive(), in: Capsule())
            .glassEffectID("nextButton", in: namespace)
        }
    }
}

// MARK: - Legacy Button Styles (for compatibility)

struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundStyle(.white)
            .frame(minWidth: 160)
            .padding(.vertical, 14)
            .background(
                LinearGradient(
                    colors: [.cyan, .cyan.opacity(0.8)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .clipShape(Capsule())
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(.spring(duration: 0.2), value: configuration.isPressed)
    }
}

struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundStyle(.secondary)
            .frame(minWidth: 100)
            .padding(.vertical, 14)
            .background(.ultraThinMaterial)
            .clipShape(Capsule())
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(.spring(duration: 0.2), value: configuration.isPressed)
    }
}

// MARK: - Preview

#Preview {
    GuidedTourView(engine: AudioEngineManager(), onComplete: {})
}
