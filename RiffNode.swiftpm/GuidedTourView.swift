import SwiftUI

// MARK: - Guided Tour View
// An interactive 3-minute educational experience about guitar effects
// Designed for Swift Student Challenge - demonstrates educational value

struct GuidedTourView: View {
    @Bindable var engine: AudioEngineManager
    let onComplete: () -> Void

    @State private var currentStep = 0
    @State private var showingEffect = false
    @State private var demoEffect: EffectType = .distortion

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
        VStack(spacing: 0) {
            // Progress indicator
            ProgressBar(progress: Double(currentStep) / Double(tourSteps.count - 1))
                .padding(.horizontal, 40)
                .padding(.top, 20)

            Spacer()

            // Main content
            let step = tourSteps[currentStep]

            VStack(spacing: 24) {
                // Effect visualization if applicable
                if let effectType = step.highlightEffect {
                    EffectDemoView(effectType: effectType, isActive: showingEffect)
                        .frame(height: 150)
                        .transition(.scale.combined(with: .opacity))
                }

                // Text content
                VStack(spacing: 12) {
                    Text(step.title)
                        .font(.system(size: 32, weight: .bold))
                        .foregroundStyle(.white)

                    Text(step.subtitle)
                        .font(.title3)
                        .foregroundStyle(.cyan)

                    Text(step.content)
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                        .padding(.top, 8)
                }
            }
            .id(currentStep) // Force view recreation for animation
            .transition(.asymmetric(
                insertion: .move(edge: .trailing).combined(with: .opacity),
                removal: .move(edge: .leading).combined(with: .opacity)
            ))

            Spacer()

            // Navigation
            HStack(spacing: 20) {
                if currentStep > 0 {
                    Button("Back") {
                        withAnimation(.spring(duration: 0.4)) {
                            showingEffect = false
                            currentStep -= 1
                        }
                    }
                    .buttonStyle(SecondaryButtonStyle())
                }

                Button(tourSteps[currentStep].actionLabel) {
                    handleAction()
                }
                .buttonStyle(PrimaryButtonStyle())
            }
            .padding(.bottom, 40)

            // Skip option
            Button("Skip Tour") {
                onComplete()
            }
            .font(.caption)
            .foregroundStyle(.secondary)
            .padding(.bottom, 20)
        }
        .background(BackgroundView())
    }

    private func handleAction() {
        let step = tourSteps[currentStep]

        // If this step has an effect to demonstrate
        if let effectType = step.highlightEffect {
            if !showingEffect {
                // First tap: show/enable the effect
                withAnimation(.spring(duration: 0.3)) {
                    showingEffect = true
                    demoEffect = effectType
                }
                // Enable the effect in the engine
                enableDemoEffect(effectType)
                return
            }
        }

        // Move to next step or complete
        if currentStep < tourSteps.count - 1 {
            withAnimation(.spring(duration: 0.4)) {
                showingEffect = false
                currentStep += 1
            }
        } else {
            onComplete()
        }
    }

    private func enableDemoEffect(_ type: EffectType) {
        // Find and enable the effect in the chain
        if let effect = engine.effectsChain.first(where: { $0.type == type }) {
            if !effect.isEnabled {
                engine.toggleEffect(effect)
            }
        } else {
            // Add the effect if not in chain
            engine.addEffect(type)
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

// MARK: - Progress Bar

struct ProgressBar: View {
    let progress: Double

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.white.opacity(0.2))
                    .frame(height: 4)

                RoundedRectangle(cornerRadius: 4)
                    .fill(
                        LinearGradient(
                            colors: [.cyan, .purple],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: geometry.size.width * progress, height: 4)
                    .animation(.spring(duration: 0.4), value: progress)
            }
        }
        .frame(height: 4)
    }
}

// MARK: - Effect Demo View

struct EffectDemoView: View {
    let effectType: EffectType
    let isActive: Bool

    var body: some View {
        VStack(spacing: 16) {
            // Visual representation of the effect
            ZStack {
                // Background glow
                Circle()
                    .fill(effectType.color.opacity(isActive ? 0.3 : 0.1))
                    .frame(width: 120, height: 120)
                    .blur(radius: isActive ? 20 : 10)

                // Effect pedal representation
                RoundedRectangle(cornerRadius: 12)
                    .fill(
                        LinearGradient(
                            colors: isActive
                                ? [effectType.color, effectType.color.opacity(0.7)]
                                : [Color.gray.opacity(0.5), Color.gray.opacity(0.3)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(width: 80, height: 100)
                    .overlay(
                        VStack(spacing: 8) {
                            Circle()
                                .fill(isActive ? Color.green : Color.red.opacity(0.5))
                                .frame(width: 8, height: 8)
                                .shadow(color: isActive ? .green : .clear, radius: 4)

                            Text(effectType.abbreviation)
                                .font(.system(size: 20, weight: .bold, design: .monospaced))
                                .foregroundStyle(.white)

                            Text(effectType.rawValue)
                                .font(.system(size: 10, weight: .medium))
                                .foregroundStyle(.white.opacity(0.8))
                        }
                    )
                    .shadow(color: isActive ? effectType.color.opacity(0.5) : .clear, radius: 10)
            }

            // Waveform visualization
            WaveformDemo(isActive: isActive, color: effectType.color)
                .frame(height: 40)
                .padding(.horizontal, 40)
        }
    }
}

// MARK: - Waveform Demo

struct WaveformDemo: View {
    let isActive: Bool
    let color: Color

    @State private var phase: Double = 0

    var body: some View {
        TimelineView(.animation) { timeline in
            Canvas { context, size in
                let midY = size.height / 2
                var path = Path()

                let date = timeline.date.timeIntervalSinceReferenceDate
                let animatedPhase = isActive ? date * 3 : 0

                path.move(to: CGPoint(x: 0, y: midY))

                for x in stride(from: 0, through: size.width, by: 2) {
                    let relativeX = Double(x / size.width)
                    let amplitude = isActive ? Double(size.height) * 0.4 : Double(size.height) * 0.1

                    // Create different wave shapes based on whether active
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
    }
}

// MARK: - Button Styles

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
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(.spring(duration: 0.2), value: configuration.isPressed)
    }
}

struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundStyle(.white.opacity(0.8))
            .frame(minWidth: 100)
            .padding(.vertical, 14)
            .background(Color.white.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(.spring(duration: 0.2), value: configuration.isPressed)
    }
}

// MARK: - Preview

#Preview {
    GuidedTourView(engine: AudioEngineManager(), onComplete: {})
}
