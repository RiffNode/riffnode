import SwiftUI

// MARK: - Main Content View
// Following Clean Architecture: View only handles UI, delegates logic to ViewModels

struct ContentView: View {

    // MARK: - Dependencies (Dependency Injection)

    @State private var engine = AudioEngineManager()
    @State private var presetService = PresetService()

    // MARK: - State

    @State private var hasCompletedSetup = false

    // MARK: - Body

    var body: some View {
        ZStack {
            BackgroundView()

            if hasCompletedSetup {
                MainInterfaceView(
                    engine: engine,
                    presetService: presetService
                )
            } else {
                WelcomeView(
                    engine: engine,
                    onComplete: {
                        withAnimation(.spring(duration: 0.5)) {
                            hasCompletedSetup = true
                        }
                    }
                )
            }
        }
        #if os(macOS)
        .frame(minWidth: 1000, minHeight: 700)
        #endif
    }
}

// MARK: - Background View
// Extracted for Single Responsibility

struct BackgroundView: View {
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.05, green: 0.05, blue: 0.12),
                    Color(red: 0.08, green: 0.04, blue: 0.15),
                    Color(red: 0.04, green: 0.08, blue: 0.15)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            GridPatternView()
                .opacity(0.03)
        }
        .ignoresSafeArea()
    }
}

// MARK: - Grid Pattern View

struct GridPatternView: View {
    var body: some View {
        Canvas { context, size in
            guard size.width > 0 && size.height > 0 else { return }
            let gridSize: CGFloat = 30
            let lineWidth: CGFloat = 1

            for x in stride(from: 0, through: size.width, by: gridSize) {
                var path = Path()
                path.move(to: CGPoint(x: x, y: 0))
                path.addLine(to: CGPoint(x: x, y: size.height))
                context.stroke(path, with: .color(.white), lineWidth: lineWidth)
            }

            for y in stride(from: 0, through: size.height, by: gridSize) {
                var path = Path()
                path.move(to: CGPoint(x: 0, y: y))
                path.addLine(to: CGPoint(x: size.width, y: y))
                context.stroke(path, with: .color(.white), lineWidth: lineWidth)
            }
        }
    }
}

// MARK: - Welcome View

struct WelcomeView: View {
    @Bindable var engine: AudioEngineManager
    let onComplete: () -> Void

    @State private var viewModel: SetupViewModel?
    @State private var logoScale: CGFloat = 0.5
    @State private var logoOpacity: Double = 0

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            LogoView(scale: logoScale, opacity: logoOpacity)
                .onAppear {
                    withAnimation(.spring(duration: 0.8)) {
                        logoScale = 1.0
                        logoOpacity = 1.0
                    }
                }

            Spacer()

            if let vm = viewModel {
                SetupStepsView(viewModel: vm)
            }

            Spacer()

            SetupActionButton(viewModel: viewModel, onComplete: onComplete)

            if let error = viewModel?.errorMessage {
                ErrorMessageView(message: error)
            }

            Spacer()
        }
        .padding()
        .onAppear {
            viewModel = SetupViewModel(audioEngine: engine)
        }
    }
}

// MARK: - Logo View

struct LogoView: View {
    let scale: CGFloat
    let opacity: Double

    var body: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(.cyan.opacity(0.15))
                    .frame(width: 140, height: 140)
                    .blur(radius: 30)

                Circle()
                    .fill(.purple.opacity(0.2))
                    .frame(width: 100, height: 100)
                    .blur(radius: 20)

                Image(systemName: "guitars.fill")
                    .font(.system(size: 60))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.cyan, .purple, .pink],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .symbolEffect(.pulse)
            }
            .scaleEffect(scale)
            .opacity(opacity)

            Text("RiffNode")
                .font(.system(size: 52, weight: .bold, design: .rounded))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.white, .cyan.opacity(0.8)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )

            Text("Your Visual Guitar Effects Playground")
                .font(.title3)
                .foregroundStyle(.secondary)
        }
    }
}

// MARK: - Setup Steps View

struct SetupStepsView: View {
    @Bindable var viewModel: SetupViewModel

    var body: some View {
        VStack(spacing: 20) {
            ForEach([SetupViewModel.SetupStep.permission, .engine, .ready], id: \.rawValue) { step in
                SetupStepRow(
                    step: step,
                    status: viewModel.stepStatus(for: step)
                )
            }
        }
        .padding(.horizontal, 60)
    }
}

// MARK: - Setup Step Row

struct SetupStepRow: View {
    let step: SetupViewModel.SetupStep
    let status: SetupViewModel.StepStatus

    var body: some View {
        HStack(spacing: 16) {
            StepIndicator(icon: step.icon, status: status)

            VStack(alignment: .leading, spacing: 4) {
                Text(step.title)
                    .font(.headline)
                    .foregroundStyle(status == .pending ? .secondary : .primary)

                Text(step.description)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            if status == .active {
                Circle()
                    .fill(.cyan)
                    .frame(width: 8, height: 8)
                    .shadow(color: .cyan, radius: 4)
            }
        }
        .padding()
        .background(stepBackground)
        .animation(.spring(duration: 0.3), value: status)
    }

    private var stepBackground: some View {
        RoundedRectangle(cornerRadius: 16)
            .fill(status == .active ? Color.cyan.opacity(0.1) : Color.white.opacity(0.02))
            .strokeBorder(
                status == .active ? Color.cyan.opacity(0.4) : Color.white.opacity(0.05),
                lineWidth: 1
            )
    }
}

// MARK: - Step Indicator

struct StepIndicator: View {
    let icon: String
    let status: SetupViewModel.StepStatus

    var body: some View {
        ZStack {
            Circle()
                .fill(backgroundColor)
                .frame(width: 50, height: 50)
                .shadow(color: status == .active ? .cyan.opacity(0.5) : .clear, radius: 8)

            if status == .completed {
                Image(systemName: "checkmark")
                    .font(.title2.bold())
                    .foregroundStyle(.white)
            } else {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundStyle(status == .active ? .white : .gray)
            }
        }
    }

    private var backgroundColor: Color {
        switch status {
        case .pending: return .gray.opacity(0.3)
        case .active: return .cyan
        case .completed: return .green
        }
    }
}

// MARK: - Setup Action Button

struct SetupActionButton: View {
    let viewModel: SetupViewModel?
    let onComplete: () -> Void

    var body: some View {
        Button {
            Task {
                if viewModel?.currentStep == .ready {
                    onComplete()
                } else {
                    await viewModel?.performNextStep()
                }
            }
        } label: {
            HStack(spacing: 8) {
                if viewModel?.isLoading == true {
                    ProgressView()
                        .controlSize(.small)
                        .tint(.black)
                }
                Text(viewModel?.buttonTitle ?? "Continue")
                    .font(.headline)
            }
            .frame(width: 240, height: 54)
            .background(
                LinearGradient(
                    colors: [.cyan, .purple],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .foregroundStyle(.white)
            .clipShape(Capsule())
            .shadow(color: .cyan.opacity(0.4), radius: 10, y: 5)
        }
        .buttonStyle(.plain)
        .disabled(viewModel?.isLoading == true)
        .scaleEffect(viewModel?.isLoading == true ? 0.98 : 1.0)
        .animation(.default, value: viewModel?.isLoading)
    }
}

// MARK: - Error Message View

struct ErrorMessageView: View {
    let message: String

    var body: some View {
        Text(message)
            .font(.caption)
            .foregroundStyle(.red)
            .multilineTextAlignment(.center)
            .padding(.horizontal)
            .transition(.opacity)
    }
}

// MARK: - Main Interface View

struct MainInterfaceView: View {
    @Bindable var engine: AudioEngineManager
    let presetService: PresetProviding

    @State private var showingSettings = false
    @State private var showingPresets = false

    var body: some View {
        VStack(spacing: 0) {
            TopBarView(
                engine: engine,
                showingSettings: $showingSettings,
                showingPresets: $showingPresets
            )

            HStack(spacing: 0) {
                // Left panel
                VStack(spacing: 16) {
                    AudioVisualizationPanel(engine: engine)
                    BackingTrackView(engine: engine)
                }
                .padding()
                .frame(width: 400)

                Rectangle()
                    .fill(Color.white.opacity(0.1))
                    .frame(width: 1)

                // Right panel
                VStack(spacing: 0) {
                    EffectsChainView(engine: engine)
                }
                .frame(maxWidth: .infinity)
            }
        }
        .sheet(isPresented: $showingSettings) {
            SettingsView(engine: engine)
        }
        .sheet(isPresented: $showingPresets) {
            PresetPickerView(engine: engine, presetService: presetService)
        }
    }
}

// MARK: - Top Bar View

struct TopBarView: View {
    @Bindable var engine: AudioEngineManager
    @Binding var showingSettings: Bool
    @Binding var showingPresets: Bool

    var body: some View {
        HStack {
            // Logo
            HStack(spacing: 8) {
                Image(systemName: "guitars.fill")
                    .font(.title2)
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.cyan, .purple],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )

                Text("RiffNode")
                    .font(.title2.bold())
            }

            Spacer()

            // Presets button
            Button { showingPresets = true } label: {
                HStack(spacing: 6) {
                    Image(systemName: "square.stack.3d.up.fill")
                    Text("Presets")
                }
                .font(.system(size: 13, weight: .medium))
            }
            .buttonStyle(.bordered)

            // Engine status
            EngineStatusBadge(isRunning: engine.isRunning)

            // Controls
            HStack(spacing: 12) {
                Button {
                    if engine.isRunning {
                        engine.stop()
                    } else {
                        try? engine.start()
                    }
                } label: {
                    Image(systemName: engine.isRunning ? "stop.fill" : "play.fill")
                        .foregroundStyle(engine.isRunning ? .red : .green)
                }
                .buttonStyle(.bordered)

                Button { showingSettings = true } label: {
                    Image(systemName: "gear")
                }
                .buttonStyle(.bordered)
            }
        }
        .padding()
        .background(.ultraThinMaterial)
    }
}

// MARK: - Engine Status Badge

struct EngineStatusBadge: View {
    let isRunning: Bool

    var body: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(isRunning ? .green : .red)
                .frame(width: 8, height: 8)
                .shadow(color: isRunning ? .green : .red, radius: 4)

            Text(isRunning ? "Running" : "Stopped")
                .font(.system(size: 12, weight: .medium, design: .monospaced))
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(.ultraThinMaterial)
        .clipShape(Capsule())
    }
}

// MARK: - Preset Picker View

struct PresetPickerView: View {
    @Bindable var engine: AudioEngineManager
    let presetService: PresetProviding
    @Environment(\.dismiss) private var dismiss

    @State private var selectedCategory: EffectPreset.PresetCategory?
    @State private var selectedPreset: EffectPreset?

    private var filteredPresets: [EffectPreset] {
        if let category = selectedCategory {
            return presetService.presets(for: category)
        }
        return presetService.presets
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                CategoryFilterBar(selectedCategory: $selectedCategory)

                ScrollView {
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                        ForEach(filteredPresets) { preset in
                            PresetCardView(
                                preset: preset,
                                isSelected: selectedPreset?.id == preset.id
                            ) {
                                selectedPreset = preset
                                engine.applyPreset(preset)
                                dismiss()
                            }
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Effect Presets")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
        #if os(macOS)
        .frame(width: 500, height: 500)
        #endif
    }
}

// MARK: - Category Filter Bar

struct CategoryFilterBar: View {
    @Binding var selectedCategory: EffectPreset.PresetCategory?

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                CategoryChip(title: "All", isSelected: selectedCategory == nil) {
                    withAnimation { selectedCategory = nil }
                }

                ForEach(EffectPreset.PresetCategory.allCases, id: \.self) { category in
                    CategoryChip(title: category.rawValue, isSelected: selectedCategory == category) {
                        withAnimation { selectedCategory = category }
                    }
                }
            }
            .padding()
        }
        .background(.ultraThinMaterial)
    }
}

// MARK: - Category Chip

struct CategoryChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 13, weight: .medium))
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(isSelected ? Color.cyan : Color.gray.opacity(0.2))
                .foregroundStyle(isSelected ? .white : .secondary)
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Preset Card View

struct PresetCardView: View {
    let preset: EffectPreset
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: preset.icon)
                        .font(.title2)
                        .foregroundStyle(preset.category.color)

                    Spacer()

                    Text(preset.category.rawValue)
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(preset.category.color.opacity(0.2))
                        .foregroundStyle(preset.category.color)
                        .clipShape(Capsule())
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(preset.name)
                        .font(.headline)
                        .foregroundStyle(.primary)

                    Text(preset.description)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }

                HStack(spacing: 4) {
                    ForEach(Array(preset.effects.enumerated()), id: \.offset) { _, effect in
                        Image(systemName: effect.type.icon)
                            .font(.caption)
                            .foregroundStyle(effect.type.color)
                            .padding(6)
                            .background(effect.type.color.opacity(0.2))
                            .clipShape(Circle())
                    }
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .strokeBorder(
                                isSelected ? preset.category.color : Color.white.opacity(0.1),
                                lineWidth: isSelected ? 2 : 1
                            )
                    )
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Settings View

struct SettingsView: View {
    @Bindable var engine: AudioEngineManager
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section("Audio") {
                    StatusRow(label: "Status", value: engine.isRunning ? "Running" : "Stopped", isPositive: engine.isRunning)
                    StatusRow(label: "Permission", value: engine.hasPermission ? "Granted" : "Denied", isPositive: engine.hasPermission)
                }

                Section("Effects Chain") {
                    LabeledContent("Active Effects") {
                        Text("\(engine.effectsChain.filter { $0.isEnabled }.count)")
                    }
                    LabeledContent("Total Effects") {
                        Text("\(engine.effectsChain.count)")
                    }
                }

                Section("About") {
                    LabeledContent("Version", value: "1.0")
                    LabeledContent("Built with", value: "Swift 6 & SwiftUI")
                    LabeledContent("Architecture", value: "Clean Architecture + SOLID")

                    Text("RiffNode is a visual guitar effects playground built for the Swift Student Challenge 2026. Connect your guitar through an audio interface and explore a world of effects!")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Settings")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
        #if os(macOS)
        .frame(width: 400, height: 400)
        #endif
    }
}

// MARK: - Status Row

struct StatusRow: View {
    let label: String
    let value: String
    let isPositive: Bool

    var body: some View {
        LabeledContent(label) {
            HStack(spacing: 6) {
                Circle()
                    .fill(isPositive ? .green : .red)
                    .frame(width: 8, height: 8)
                Text(value)
                    .foregroundStyle(isPositive ? .green : .red)
            }
        }
    }
}

// MARK: - Preview

#Preview {
    ContentView()
}
