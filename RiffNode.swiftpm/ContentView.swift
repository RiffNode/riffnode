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
// Clean gradient background with subtle depth

struct BackgroundView: View {
    var body: some View {
        ZStack {
            // Base gradient - deep, professional tones
            LinearGradient(
                colors: [
                    Color(red: 0.06, green: 0.06, blue: 0.12),
                    Color(red: 0.04, green: 0.04, blue: 0.10),
                    Color(red: 0.08, green: 0.06, blue: 0.14)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            
            // Subtle ambient glow
            RadialGradient(
                colors: [
                    Color.cyan.opacity(0.08),
                    Color.clear
                ],
                center: .topTrailing,
                startRadius: 100,
                endRadius: 500
            )
            
            RadialGradient(
                colors: [
                    Color.purple.opacity(0.06),
                    Color.clear
                ],
                center: .bottomLeading,
                startRadius: 50,
                endRadius: 400
            )
        }
        .ignoresSafeArea()
    }
}

// MARK: - Welcome View

struct WelcomeView: View {
    @Bindable var engine: AudioEngineManager
    let onComplete: () -> Void

    @State private var viewModel: SetupViewModel?
    @State private var logoScale: CGFloat = 0.5
    @State private var logoOpacity: Double = 0
    @Namespace private var namespace

    var body: some View {
        GlassEffectContainer(spacing: 24) {
            VStack(spacing: 40) {
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
        }
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
        VStack(spacing: 20) {
            // Clean, minimal logo
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [.cyan.opacity(0.3), .purple.opacity(0.2)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 120, height: 120)
                    .blur(radius: 30)

                Image(systemName: "waveform.path")
                    .font(.system(size: 56, weight: .light))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.cyan, .white],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }
            .scaleEffect(scale)
            .opacity(opacity)

            VStack(spacing: 8) {
                Text("RiffNode")
                    .font(.system(size: 48, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white)

                Text("Visual Guitar Effects Playground")
                    .font(.title3)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

// MARK: - Setup Steps View

struct SetupStepsView: View {
    @Bindable var viewModel: SetupViewModel
    @Namespace private var glassNamespace

    var body: some View {
        GlassEffectContainer(spacing: 16) {
            VStack(spacing: 16) {
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
            }
        }
        .padding()
        .glassEffect(.regular.tint(status == .active ? .cyan : .clear), in: .rect(cornerRadius: 16))
        .animation(.spring(duration: 0.3), value: status)
    }
}

// MARK: - Step Indicator

struct StepIndicator: View {
    let icon: String
    let status: SetupViewModel.StepStatus

    var body: some View {
        ZStack {
            if status == .completed {
                Image(systemName: "checkmark")
                    .font(.title2.bold())
                    .foregroundStyle(.white)
            } else {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundStyle(status == .active ? .white : .secondary)
            }
        }
        .frame(width: 44, height: 44)
        .glassEffect(
            .regular.tint(status == .completed ? .green : (status == .active ? .cyan : .clear)),
            in: .circle
        )
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
                }
                Text(viewModel?.buttonTitle ?? "Continue")
                    .font(.headline)
            }
            .frame(width: 200)
            .padding(.vertical, 16)
        }
        .buttonStyle(.glassProminent)
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
    @State private var selectedTab: MainTab = .pedalboard
    @Namespace private var tabNamespace

    enum MainTab: String, CaseIterable {
        case pedalboard = "Pedalboard"
        case parametricEQ = "Parametric EQ"
        case learnEffects = "Learn"

        var icon: String {
            switch self {
            case .pedalboard: return "slider.horizontal.below.square.filled.and.square"
            case .parametricEQ: return "slider.horizontal.3"
            case .learnEffects: return "text.book.closed"
            }
        }
    }

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
                .frame(width: 380)

                Rectangle()
                    .fill(Color.white.opacity(0.08))
                    .frame(width: 1)

                // Right panel with tab switching
                VStack(spacing: 0) {
                    // Tab selector with Liquid Glass
                    GlassEffectContainer(spacing: 8) {
                        HStack(spacing: 4) {
                            ForEach(MainTab.allCases, id: \.rawValue) { tab in
                                TabButton(
                                    tab: tab,
                                    isSelected: selectedTab == tab,
                                    namespace: tabNamespace
                                ) {
                                    withAnimation(.spring(duration: 0.3)) {
                                        selectedTab = tab
                                    }
                                }
                            }
                            Spacer()
                        }
                        .padding(8)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)

                    // Content based on selected tab
                    switch selectedTab {
                    case .pedalboard:
                        EffectsChainView(engine: engine)
                    case .parametricEQ:
                        ScrollView {
                            ParametricEQView(engine: engine)
                                .padding()
                        }
                    case .learnEffects:
                        EffectGuideView()
                    }
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

// MARK: - Tab Button

struct TabButton: View {
    let tab: MainInterfaceView.MainTab
    let isSelected: Bool
    let namespace: Namespace.ID
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: tab.icon)
                Text(tab.rawValue)
            }
            .font(.system(size: 13, weight: .medium))
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .foregroundStyle(isSelected ? .white : .secondary)
        }
        .buttonStyle(.plain)
        .glassEffect(
            isSelected ? .regular.interactive() : .regular.tint(.clear),
            in: .capsule
        )
        .glassEffectID(tab.rawValue, in: namespace)
    }
}

// MARK: - Top Bar View

struct TopBarView: View {
    @Bindable var engine: AudioEngineManager
    @Binding var showingSettings: Bool
    @Binding var showingPresets: Bool
    @Namespace private var topBarNamespace

    var body: some View {
        GlassEffectContainer(spacing: 12) {
            HStack(spacing: 16) {
                // Logo - minimal
                HStack(spacing: 8) {
                    Image(systemName: "waveform.path")
                        .font(.title2)
                        .foregroundStyle(.cyan)

                    Text("RiffNode")
                        .font(.title3.bold())
                }

                Spacer()

                // Action buttons with Liquid Glass
                HStack(spacing: 8) {
                    Button { showingPresets = true } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "square.stack.3d.up")
                            Text("Presets")
                        }
                        .font(.system(size: 13, weight: .medium))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                    }
                    .buttonStyle(.glass)

                    EngineStatusBadge(isRunning: engine.isRunning)

                    // Play/Stop button
                    Button {
                        if engine.isRunning {
                            engine.stop()
                        } else {
                            try? engine.start()
                        }
                    } label: {
                        Image(systemName: engine.isRunning ? "stop.fill" : "play.fill")
                            .font(.system(size: 14))
                            .foregroundStyle(engine.isRunning ? .red : .green)
                            .frame(width: 36, height: 36)
                    }
                    .buttonStyle(.glass)

                    Button { showingSettings = true } label: {
                        Image(systemName: "gearshape")
                            .font(.system(size: 14))
                            .frame(width: 36, height: 36)
                    }
                    .buttonStyle(.glass)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
        }
    }
}

// MARK: - Engine Status Badge

struct EngineStatusBadge: View {
    let isRunning: Bool

    var body: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(isRunning ? .green : .orange)
                .frame(width: 6, height: 6)

            Text(isRunning ? "Running" : "Stopped")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .glassEffect(in: .capsule)
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
                PresetCategoryFilterBar(selectedCategory: $selectedCategory)

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
            .background(Color(red: 0.05, green: 0.05, blue: 0.1))
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

// MARK: - Preset Category Filter Bar

struct PresetCategoryFilterBar: View {
    @Binding var selectedCategory: EffectPreset.PresetCategory?

    var body: some View {
        GlassEffectContainer(spacing: 8) {
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
        }
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
                .foregroundStyle(isSelected ? .white : .secondary)
        }
        .buttonStyle(.plain)
        .glassEffect(
            isSelected ? .regular.tint(.cyan).interactive() : .regular,
            in: .capsule
        )
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
                    Text(preset.category.rawValue)
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .glassEffect(.regular.tint(preset.category.color), in: .capsule)

                    Spacer()
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

                // Effect chain preview - simple dots
                HStack(spacing: 6) {
                    ForEach(Array(preset.effects.enumerated()), id: \.offset) { _, effect in
                        Circle()
                            .fill(effect.type.color)
                            .frame(width: 8, height: 8)
                    }
                }
            }
            .padding()
            .glassEffect(
                isSelected ? .regular.tint(preset.category.color).interactive() : .regular.interactive(),
                in: .rect(cornerRadius: 16)
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
