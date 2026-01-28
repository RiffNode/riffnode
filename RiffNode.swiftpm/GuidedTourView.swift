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
                // Progress indicator - cleaner design
                GlassProgressBar(
                    progress: Double(currentStep) / Double(tourSteps.count - 1),
                    steps: tourSteps.count,
                    currentStep: currentStep
                )
                .padding(.horizontal, Spacing.xxl)
                .padding(.top, Spacing.lg)

                Spacer()

                // Main content
                let step = tourSteps[currentStep]

                VStack(spacing: Spacing.xl) {
                    // Effect visualization if applicable
                    if let effectType = step.highlightEffect {
                        GlassEffectDemoView(effectType: effectType, isActive: showingEffect)
                            .frame(height: 180)
                            .transition(.scale.combined(with: .opacity))
                    }

                    // Text content - clean and minimal without heavy glass border
                    VStack(spacing: Spacing.md) {
                        Text(step.title)
                            .font(.system(size: 32, weight: .bold, design: .rounded))
                            .foregroundStyle(.primary)

                        Text(step.subtitle)
                            .font(.title3.weight(.medium))
                            .foregroundStyle(step.highlightEffect?.color ?? Color.riffPrimary)

                        Text(step.content)
                            .font(.body)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                            .lineSpacing(4)
                            .padding(.top, Spacing.sm)
                    }
                    .padding(Spacing.xl)
                    .frame(maxWidth: 500)
                    .background {
                        RoundedRectangle(cornerRadius: CornerRadius.xl)
                            .fill(.ultraThinMaterial)
                    }
                    .padding(.horizontal, Spacing.lg)
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
                    onBack: handleBack,
                    onNext: handleAction,
                    namespace: tourNamespace
                )
                .padding(.bottom, Spacing.xl)

                // Skip option - native glass button
                Button("Skip Tour") {
                    onComplete()
                }
                .buttonStyle(.glass)
                .padding(.bottom, Spacing.lg)
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

        if currentStep < tourSteps.count - 1 {
            // Disable current effect before moving to next step
            if let currentEffect = step.highlightEffect {
                disableDemoEffect(currentEffect)
            }

            // Calculate next step index before updating currentStep
            let nextStepIndex = currentStep + 1
            let nextStep = tourSteps[nextStepIndex]

            withAnimation(.spring(duration: 0.4)) {
                showingEffect = false
                currentStep = nextStepIndex
            }

            // Enable the new step's effect after a short delay for smooth transition
            if let nextEffect = nextStep.highlightEffect {
                Task { @MainActor in
                    try? await Task.sleep(for: .milliseconds(300))
                    enableDemoEffect(nextEffect)
                    withAnimation(.spring(duration: 0.3)) {
                        showingEffect = true
                        demoEffect = nextEffect
                    }
                }
            }
        } else {
            restoreEffectStates()
            onComplete()
        }
    }

    private func handleBack() {
        let step = tourSteps[currentStep]

        // Disable current effect
        if let currentEffect = step.highlightEffect {
            disableDemoEffect(currentEffect)
        }

        // Calculate previous step
        let prevStepIndex = currentStep - 1
        let prevStep = tourSteps[prevStepIndex]

        withAnimation(.spring(duration: 0.4)) {
            showingEffect = false
            currentStep = prevStepIndex
        }

        // Enable the previous step's effect
        if let prevEffect = prevStep.highlightEffect {
            Task { @MainActor in
                try? await Task.sleep(for: .milliseconds(300))
                enableDemoEffect(prevEffect)
                withAnimation(.spring(duration: 0.3)) {
                    showingEffect = true
                    demoEffect = prevEffect
                }
            }
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
        VStack(spacing: Spacing.sm) {
            // Step indicators
            HStack(spacing: 0) {
                ForEach(0..<steps, id: \.self) { step in
                    Circle()
                        .fill(step <= currentStep ? Color.black : Color.white.opacity(0.3))
                        .frame(width: 10, height: 10)
                        .overlay {
                            if step == currentStep {
                                Circle()
                                    .stroke(Color.black, lineWidth: 2)
                                    .frame(width: 18, height: 18)
                            }
                        }

                    if step < steps - 1 {
                        Rectangle()
                            .fill(step < currentStep ? Color.black : Color.white.opacity(0.2))
                            .frame(height: 2)
                    }
                }
            }
            .glassEffect(.clear, in: Capsule())

            // Step counter
            Text("Step \(currentStep + 1) of \(steps)")
                .font(Typography.caption())
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
        HStack(spacing: Spacing.md) {
            if currentStep > 0 {
                Button(action: onBack) {
                    HStack(spacing: Spacing.xs) {
                        Image(systemName: "chevron.left")
                        Text("Back")
                    }
                }
                .buttonStyle(.glass)
            }

            Button(action: onNext) {
                HStack(spacing: Spacing.xs) {
                    Text(actionLabel)
                    Image(systemName: "chevron.right")
                }
            }
            .buttonStyle(.glass)
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
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(.spring(duration: 0.2), value: configuration.isPressed)
    }
}

// MARK: - Preview

#Preview {
    GuidedTourView(engine: AudioEngineManager(), onComplete: {})
}
