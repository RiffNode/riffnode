import SwiftUI

// MARK: - Main Content View
// Liquid Glass UI Design - iOS 26+ Design Language

struct ContentView: View {

    // MARK: - Dependencies (Dependency Injection)

    @State private var engine = AudioEngineManager()
    @State private var presetService = PresetService()

    // MARK: - State

    enum AppState {
        case welcome
        case guidedTour
        case main
    }

    @State private var appState: AppState = .welcome

    // MARK: - Body

    var body: some View {
        ZStack {
            AdaptiveBackground()

            switch appState {
            case .welcome:
                WelcomeView(
                    engine: engine,
                    onStartTour: {
                        withAnimation(.spring(duration: 0.5)) {
                            appState = .guidedTour
                        }
                    },
                    onSkipToMain: {
                        withAnimation(.spring(duration: 0.5)) {
                            appState = .main
                        }
                    }
                )

            case .guidedTour:
                GuidedTourView(engine: engine) {
                    withAnimation(.spring(duration: 0.5)) {
                        appState = .main
                    }
                }

            case .main:
                MainInterfaceView(
                    engine: engine,
                    presetService: presetService
                )
            }
        }
        // iOS 26 Liquid Glass: Force light mode to match Apple's design language
        .preferredColorScheme(.light)
        #if os(macOS)
        .frame(minWidth: 1000, minHeight: 700)
        #endif
    }
}

// MARK: - Welcome View

struct WelcomeView: View {
    @Bindable var engine: AudioEngineManager
    let onStartTour: () -> Void
    let onSkipToMain: () -> Void

    @State private var viewModel: SetupViewModel?
    @State private var showContent = false
    @State private var setupComplete = false
    @Namespace private var welcomeNamespace

    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            
            // Hero section with large glass logo
            VStack(spacing: Spacing.xl) {
                // Large glass app icon
                ZStack {
                    // Outer glow
                    Circle()
                        .fill(.white.opacity(0.3))
                        .frame(width: 160, height: 160)
                        .blur(radius: 30)
                    
                    // Glass circle with icon
                    Circle()
                        .glassEffect(.regular.interactive(), in: Circle())
                        .frame(width: 140, height: 140)
                    
                    Image(systemName: "guitars.fill")
                        .font(.system(size: 60, weight: .medium))
                        .foregroundStyle(.primary)
                }
                .scaleEffect(showContent ? 1 : 0.8)
                .opacity(showContent ? 1 : 0)
                
                // App name with subtle gradient
                VStack(spacing: Spacing.sm) {
                    Text("RiffNode")
                        .font(.system(size: 48, weight: .bold, design: .rounded))
                        .foregroundStyle(.primary)
                    
                    Text("Guitar Effects Playground")
                        .font(.title3.weight(.medium))
                        .foregroundStyle(.secondary)
                }
                .opacity(showContent ? 1 : 0)
            }
            
            Spacer()
            
            // Setup card - centered and prominent
            if let vm = viewModel {
                VStack(spacing: Spacing.lg) {
                    ForEach([SetupViewModel.SetupStep.permission, .engine, .ready], id: \.rawValue) { step in
                        HStack(spacing: Spacing.md) {
                            ZStack {
                                Circle()
                                    .glassEffect(.regular, in: Circle())
                                    .frame(width: 40, height: 40)

                                Image(systemName: stepIcon(for: step, status: vm.stepStatus(for: step)))
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundStyle(stepColor(for: vm.stepStatus(for: step)))
                            }

                            Text(step.description)
                                .font(.body)
                                .foregroundStyle(vm.stepStatus(for: step) == .completed ? .primary : .secondary)

                            Spacer()
                        }
                    }
                }
                .padding(Spacing.lg)
                .glassEffect(.regular, in: RoundedRectangle(cornerRadius: CornerRadius.xl))
                .frame(maxWidth: 400)
                .padding(.horizontal, Spacing.xl)
                .opacity(showContent ? 1 : 0)
            }
            
            Spacer()
            
            // Action buttons - large and prominent
            VStack(spacing: Spacing.md) {
                if setupComplete {
                    Button {
                        onStartTour()
                    } label: {
                        HStack(spacing: Spacing.sm) {
                            Image(systemName: "sparkles")
                                .font(.system(size: 18, weight: .semibold))
                            Text("Take the Tour")
                                .font(.headline)
                        }
                        .foregroundStyle(.primary)
                        .frame(maxWidth: 280)
                        .padding(.vertical, Spacing.md)
                    }
                    .buttonStyle(.glassProminent)
                    
                    Button {
                        onSkipToMain()
                    } label: {
                        Text("Skip")
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                } else {
                    Button {
                        Task {
                            await viewModel?.performNextStep()
                            if viewModel?.currentStep == .ready {
                                withAnimation(.spring(duration: 0.4)) {
                                    setupComplete = true
                                }
                            }
                        }
                    } label: {
                        HStack(spacing: Spacing.sm) {
                            if viewModel?.isLoading == true {
                                ProgressView()
                                    .controlSize(.small)
                            }
                            Text(viewModel?.buttonTitle ?? "Continue")
                                .font(.headline)
                        }
                        .frame(maxWidth: 280)
                        .padding(.vertical, Spacing.md)
                    }
                    .buttonStyle(.glassProminent)
                    .disabled(viewModel?.isLoading == true)
                }
            }
            .padding(.bottom, Spacing.xxl)

            if let error = viewModel?.errorMessage {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(.red)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
        }
        .padding()
        .onAppear {
            viewModel = SetupViewModel(audioEngine: engine)
            withAnimation(.easeOut(duration: 0.5)) {
                showContent = true
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func stepIcon(for step: SetupViewModel.SetupStep, status: SetupViewModel.StepStatus) -> String {
        switch status {
        case .completed: return "checkmark"
        case .active: return "circle.dotted"
        case .pending: return "circle"
        }
    }
    
    private func stepColor(for status: SetupViewModel.StepStatus) -> Color {
        switch status {
        case .completed: return .green
        case .active: return .primary
        case .pending: return .secondary
        }
    }
}

// MARK: - Glass Setup Step Row

struct GlassSetupStepRow: View {
    let step: SetupViewModel.SetupStep
    let status: SetupViewModel.StepStatus

    var body: some View {
        HStack(spacing: 16) {
            // Status indicator
            ZStack {
                Circle()
                    .glassEffect(
                        status == .completed ? .regular.tint(.green) : .regular,
                        in: Circle()
                    )
                    .frame(width: 36, height: 36)

                if status == .completed {
                    Image(systemName: "checkmark")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(.green)
                } else if status == .active {
                    ProgressView()
                        .controlSize(.small)
                        .tint(.accentColor)
                } else {
                    Image(systemName: step.icon)
                        .font(.system(size: 14))
                        .foregroundStyle(.secondary)
                }
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(step.title)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(status == .pending ? .secondary : .primary)

                Text(step.description)
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }

            Spacer()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .glassEffect(
            status == .active ? .regular.tint(.accentColor).interactive() : .clear,
            in: RoundedRectangle(cornerRadius: 10)
        )
    }
}


// MARK: - Main Interface View

struct MainInterfaceView: View {
    @Bindable var engine: AudioEngineManager
    let presetService: PresetProviding

    @State private var showingSettings = false
    @State private var showingPresets = false
    @State private var selectedTab: MainTab = .pedalboard

    // AI Features
    @State private var fftAnalyzer = FFTAnalyzer()
    @State private var chordDetector = ChordDetector()
    @State private var gestureController = VisionGestureController()
    @State private var analysisTask: Task<Void, Never>?

    enum MainTab: String, CaseIterable {
        case pedalboard = "Pedalboard"
        case parametricEQ = "Parametric EQ"
        case aiTools = "AI Tools"
        case learnEffects = "Learn"

        var icon: String {
            switch self {
            case .pedalboard: return "slider.horizontal.below.square.filled.and.square"
            case .parametricEQ: return "slider.horizontal.3"
            case .aiTools: return "brain.head.profile"
            case .learnEffects: return "text.book.closed"
            }
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Floating glass top bar
            GlassTopBarView(
                engine: engine,
                chordDetector: chordDetector,
                showingSettings: $showingSettings,
                showingPresets: $showingPresets
            )
            .padding(.horizontal, Spacing.md)
            .padding(.top, Spacing.sm)

            HStack(spacing: 0) {
                // Left panel
                VStack(spacing: Spacing.md) {
                    AudioVisualizationPanel(engine: engine)

                    // Compact chord display
                    CompactChordBadge(detector: chordDetector)

                    BackingTrackView(engine: engine)
                }
                .padding()
                .frame(width: 380)

                GlassDivider(vertical: true)
                    .padding(.vertical, Spacing.md)

                // Right panel with tab switching
                VStack(spacing: 0) {
                    // Glass tab selector
                    HStack {
                        GlassTabBar(selection: $selectedTab, tint: Color.riffPrimary) { tab in
                            tab.icon
                        }
                        Spacer()
                    }
                    .padding(.horizontal, Spacing.md)
                    .padding(.top, Spacing.md)

                    // Content based on selected tab
                    Group {
                        switch selectedTab {
                        case .pedalboard:
                            EffectsChainView(engine: engine)
                        case .parametricEQ:
                            ScrollView {
                                ParametricEQView(engine: engine)
                                    .padding()
                            }
                        case .aiTools:
                            AIToolsView(
                                fftAnalyzer: fftAnalyzer,
                                chordDetector: chordDetector,
                                gestureController: gestureController,
                                engine: engine
                            )
                        case .learnEffects:
                            EffectGuideView()
                        }
                    }
                    .transition(.opacity)
                }
                .frame(maxWidth: .infinity)
            }
        }
        .sheet(isPresented: $showingSettings) {
            SettingsView(engine: engine)
        }
        .sheet(isPresented: $showingPresets) {
            PresetPickerView(engine: engine, presetService: presetService)
                #if targetEnvironment(macCatalyst)
                .frame(minWidth: 400, minHeight: 500)
                #endif
        }
        .onAppear {
            setupGestureActions()
            setupAudioAnalysis()
        }
    }

    private func setupGestureActions() {
        gestureController.onGestureDetected = { gesture in
            handleGesture(gesture)
        }
    }

    private func setupAudioAnalysis() {
        // Cancel any existing analysis task
        analysisTask?.cancel()

        // Use async Task loop instead of Timer to avoid MainActor capture issues
        analysisTask = Task {
            await runAudioAnalysisLoop()
        }
    }

    private func runAudioAnalysisLoop() async {
        while !Task.isCancelled {
            let samples = engine.latestAudioSamples
            if samples.count >= 2048 {
                fftAnalyzer.analyze(samples: samples)
                chordDetector.analyze(samples: samples)
            }
            try? await Task.sleep(for: .milliseconds(50))
        }
    }

    private func handleGesture(_ gesture: VisionGestureController.Gesture) {
        switch gesture {
        case .headNodDown:
            if let firstEnabled = engine.effectsChain.first(where: { $0.isEnabled }) {
                engine.toggleEffect(firstEnabled)
            }
        case .headNodUp:
            break
        case .headTiltLeft, .headTiltRight:
            if let first = engine.effectsChain.first {
                engine.toggleEffect(first)
            }
        case .mouthOpen:
            break
        case .eyebrowRaise:
            break
        }
    }
}

// MARK: - AI Tools View

struct AIToolsView: View {
    let fftAnalyzer: FFTAnalyzer
    let chordDetector: ChordDetector
    @Bindable var gestureController: VisionGestureController
    @Bindable var engine: AudioEngineManager

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Header
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("AI-Powered Tools")
                            .font(.title2.bold())

                        Text("Machine Learning & Computer Vision for Musicians")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                }
                .padding(.horizontal)

                // Spectrum Analyzer (FFT)
                GlassCard(tint: Color.riffDynamics, cornerRadius: 16) {
                    VStack(alignment: .leading, spacing: 12) {
                        Label("Real-Time Spectrum Analysis", systemImage: "waveform.path.ecg")
                            .font(.headline)
                            .foregroundStyle(Color.riffDynamics)

                        Text("Fast Fourier Transform (FFT) decomposes your audio into frequency components")
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        FFTSpectrumView(analyzer: fftAnalyzer)
                    }
                }
                .padding(.horizontal)

                // Chord Detection
                GlassCard(tint: Color.riffFilter, cornerRadius: 16) {
                    VStack(alignment: .leading, spacing: 12) {
                        Label("AI Chord Detection", systemImage: "pianokeys")
                            .font(.headline)
                            .foregroundStyle(Color.riffFilter)

                        Text("Pitch detection using autocorrelation algorithm identifies notes and chords")
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        ChordDetectorView(detector: chordDetector)
                    }
                }
                .padding(.horizontal)

                // Vision Gesture Control
                GlassCard(tint: Color.riffAmbience, cornerRadius: 16) {
                    VStack(alignment: .leading, spacing: 12) {
                        Label("Hands-Free Gesture Control", systemImage: "hand.raised.fill")
                            .font(.headline)
                            .foregroundStyle(Color.riffAmbience)

                        Text("Computer Vision detects head movements - control effects while playing!")
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        VisionGestureControlView(controller: gestureController) { gesture in
                            print("Gesture: \(gesture.rawValue)")
                        }
                    }
                }
                .padding(.horizontal)

                // Educational note
                TechExplanationCard()
                    .padding(.horizontal)
            }
            .padding(.vertical)
        }
    }
}

// MARK: - Tech Explanation Card

struct TechExplanationCard: View {
    var body: some View {
        GlassCard(tint: .green, cornerRadius: 16) {
            VStack(alignment: .leading, spacing: 12) {
                Label("The Science Behind", systemImage: "brain")
                    .font(.headline)
                    .foregroundStyle(.green)

                VStack(alignment: .leading, spacing: 16) {
                    TechBullet(
                        framework: "Accelerate (vDSP)",
                        description: "Apple's high-performance math library for FFT calculations"
                    )

                    TechBullet(
                        framework: "Vision Framework",
                        description: "Real-time face landmark detection for gesture recognition"
                    )

                    TechBullet(
                        framework: "Autocorrelation",
                        description: "Signal processing algorithm to detect fundamental pitch frequency"
                    )

                    TechBullet(
                        framework: "Swift Charts",
                        description: "Native data visualization for spectrum display"
                    )
                }
            }
        }
    }
}

struct TechBullet: View {
    let framework: String
    let description: String

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(.green)
                .font(.system(size: 12))

            VStack(alignment: .leading, spacing: 2) {
                Text(framework)
                    .font(.system(size: 12, weight: .semibold, design: .monospaced))
                    .foregroundStyle(.primary)

                Text(description)
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
            }
        }
    }
}

// MARK: - Glass Top Bar View

struct GlassTopBarView: View {
    @Bindable var engine: AudioEngineManager
    let chordDetector: ChordDetector?
    @Binding var showingSettings: Bool
    @Binding var showingPresets: Bool

    init(engine: AudioEngineManager, chordDetector: ChordDetector? = nil, showingSettings: Binding<Bool>, showingPresets: Binding<Bool>) {
        self.engine = engine
        self.chordDetector = chordDetector
        self._showingSettings = showingSettings
        self._showingPresets = showingPresets
    }

    var body: some View {
        HStack(spacing: 16) {
            // Logo
            HStack(spacing: 10) {
                Image(systemName: "guitars.fill")
                    .font(.title2)
                    .foregroundStyle(.linearGradient(
                        colors: [.cyan, .blue],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))

                Text("RiffNode")
                    .font(.title2.bold())
            }

            Spacer()

            // Audio Input Device indicator
            GlassAudioInputBadge(
                deviceName: engine.currentInputDeviceName,
                deviceType: engine.currentInputDeviceType,
                onRefresh: {
                    engine.refreshInputDevices()
                }
            )

            // Presets button
            Button {
                showingPresets = true
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "square.stack.3d.up.fill")
                    Text("Presets")
                }
            }
            .buttonStyle(.glass)

            // Engine status
            GlassStatusIndicator(
                status: engine.isRunning ? .active : .inactive,
                label: engine.isRunning ? "Running" : "Stopped"
            )

            // Controls
            HStack(spacing: 12) {
                GlassIconButton(
                    icon: engine.isRunning ? "stop.fill" : "play.fill",
                    tint: engine.isRunning ? .red : .green
                ) {
                    if engine.isRunning {
                        engine.stop()
                    } else {
                        try? engine.start()
                    }
                }

                GlassIconButton(icon: "gear", tint: .primary) {
                    showingSettings = true
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
        // iOS 26 Liquid Glass: Use native glassEffect for toolbar
        .glassEffect(.regular.interactive(), in: RoundedRectangle(cornerRadius: 20))
    }
}

// MARK: - Glass Audio Input Badge

struct GlassAudioInputBadge: View {
    let deviceName: String
    let deviceType: AudioInputDeviceType
    let onRefresh: () -> Void

    var body: some View {
        Button(action: onRefresh) {
            HStack(spacing: 8) {
                // Device type icon
                ZStack {
                    Circle()
                        .fill(deviceType.color.opacity(0.2))
                        .frame(width: 28, height: 28)

                    Image(systemName: deviceType.icon)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(deviceType.color)
                }

                // Device info
                VStack(alignment: .leading, spacing: 1) {
                    Text(deviceType.rawValue)
                        .font(.system(size: 9, weight: .medium))
                        .foregroundStyle(.secondary)

                    Text(formatDeviceName(deviceName))
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(.primary)
                        .lineLimit(1)
                }

                // Signal indicator
                Image(systemName: "waveform")
                    .font(.system(size: 10))
                    .foregroundStyle(deviceType == .none ? Color.secondary : Color.green)
                    .symbolEffect(.pulse, options: .repeating, value: deviceType != .none)
            }
        }
        .buttonStyle(.plain)
        .glassPill()
        .help("Click to refresh audio input devices")
    }

    private func formatDeviceName(_ name: String) -> String {
        var displayName = name
            .replacingOccurrences(of: "MacBook Pro Microphone", with: "MacBook Pro Mic")
            .replacingOccurrences(of: "Built-in Microphone", with: "Built-in Mic")
            .replacingOccurrences(of: "USB Audio Device", with: "USB Audio")

        if displayName.count > 22 {
            displayName = String(displayName.prefix(20)) + "..."
        }
        return displayName
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
            ZStack {
                AdaptiveBackground()

                VStack(spacing: 0) {
                    GlassPresetCategoryBar(selectedCategory: $selectedCategory)

                    ScrollView {
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                            ForEach(filteredPresets) { preset in
                                GlassPresetCard(
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

// MARK: - Glass Preset Category Bar

struct GlassPresetCategoryBar: View {
    @Binding var selectedCategory: EffectPreset.PresetCategory?

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                Button("All") {
                    withAnimation { selectedCategory = nil }
                }
                .buttonStyle(GlassPillStyle(isSelected: selectedCategory == nil, tint: .accentColor))

                ForEach(EffectPreset.PresetCategory.allCases, id: \.self) { category in
                    Button(category.rawValue) {
                        withAnimation { selectedCategory = category }
                    }
                    .buttonStyle(GlassPillStyle(isSelected: selectedCategory == category, tint: category.color))
                }
            }
            .padding()
        }
    }
}

// MARK: - Glass Preset Card

struct GlassPresetCard: View {
    let preset: EffectPreset
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text(preset.name)
                        .font(.headline)
                        .foregroundStyle(.primary)

                    Spacer()

                    Text(preset.category.rawValue)
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(preset.category.color.opacity(0.2))
                        .foregroundStyle(preset.category.color)
                        .clipShape(Capsule())
                }

                Text(preset.description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)

                // Effect chain preview
                HStack(spacing: 4) {
                    ForEach(Array(preset.effects.enumerated()), id: \.offset) { _, effect in
                        Text(effect.type.abbreviation)
                            .font(.system(size: 9, weight: .bold, design: .monospaced))
                            .foregroundStyle(effect.type.color)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 4)
                            .background(effect.type.color.opacity(0.2))
                            .clipShape(Capsule())
                    }
                }
            }
            .glassCard(
                tint: isSelected ? preset.category.color : nil,
                cornerRadius: 16,
                padding: 16
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
            ZStack {
                AdaptiveBackground()

                Form {
                    Section("Audio") {
                        GlassStatusRow(label: "Status", value: engine.isRunning ? "Running" : "Stopped", isPositive: engine.isRunning)
                        GlassStatusRow(label: "Permission", value: engine.hasPermission ? "Granted" : "Denied", isPositive: engine.hasPermission)
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
                .scrollContentBackground(.hidden)
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

// MARK: - Glass Status Row

struct GlassStatusRow: View {
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
