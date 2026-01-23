import SwiftUI

// MARK: - Main Content View
// Following Clean Architecture: View only handles UI, delegates logic to ViewModels

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
            BackgroundView()

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
    let onStartTour: () -> Void
    let onSkipToMain: () -> Void

    @State private var viewModel: SetupViewModel?
    @State private var showContent = false
    @State private var setupComplete = false

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            // App title and story
            VStack(spacing: 20) {
                Text("RiffNode")
                    .font(.system(size: 52, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)

                Text("Your Guitar Effects Playground")
                    .font(.title2)
                    .foregroundStyle(.cyan)

                // Story/narrative
                VStack(spacing: 12) {
                    Text("Ever wondered how guitarists create those iconic sounds?")
                        .font(.body)
                        .foregroundStyle(.secondary)

                    Text("From the crunchy distortion of rock legends to the ethereal reverbs of ambient music - it all starts with understanding effects pedals.")
                        .font(.callout)
                        .foregroundStyle(.secondary.opacity(0.8))
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal, 60)
                .padding(.top, 8)
            }
            .opacity(showContent ? 1 : 0)
            .offset(y: showContent ? 0 : 20)

            Spacer()

            // Setup steps
            if let vm = viewModel {
                VStack(spacing: 12) {
                    ForEach([SetupViewModel.SetupStep.permission, .engine, .ready], id: \.rawValue) { step in
                        SimpleSetupStepRow(
                            step: step,
                            status: vm.stepStatus(for: step)
                        )
                    }
                }
                .padding(.horizontal, 60)
                .opacity(showContent ? 1 : 0)
            }

            Spacer()

            // Action buttons
            if setupComplete {
                // Show tour options after setup
                VStack(spacing: 16) {
                    Button {
                        onStartTour()
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "book.fill")
                            Text("Take the 3-Minute Tour")
                        }
                        .font(.headline)
                        .frame(width: 260)
                        .padding(.vertical, 14)
                        .background(Color.cyan)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .buttonStyle(.plain)

                    Button {
                        onSkipToMain()
                    } label: {
                        Text("Skip to App")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                }
                .transition(.opacity.combined(with: .move(edge: .bottom)))
            } else {
                // Setup button
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
                    HStack(spacing: 8) {
                        if viewModel?.isLoading == true {
                            ProgressView()
                                .controlSize(.small)
                                .tint(.white)
                        }
                        Text(viewModel?.buttonTitle ?? "Continue")
                            .font(.headline)
                    }
                    .frame(width: 200)
                    .padding(.vertical, 14)
                    .background(Color.cyan)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .buttonStyle(.plain)
                .disabled(viewModel?.isLoading == true)
            }

            if let error = viewModel?.errorMessage {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(.red)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }

            Spacer()
        }
        .padding()
        .onAppear {
            viewModel = SetupViewModel(audioEngine: engine)
            withAnimation(.easeOut(duration: 0.5)) {
                showContent = true
            }
        }
    }
}

// MARK: - Simple Setup Step Row

struct SimpleSetupStepRow: View {
    let step: SetupViewModel.SetupStep
    let status: SetupViewModel.StepStatus

    var body: some View {
        HStack(spacing: 16) {
            // Status indicator
            ZStack {
                Circle()
                    .fill(statusColor.opacity(0.2))
                    .frame(width: 36, height: 36)

                if status == .completed {
                    Image(systemName: "checkmark")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(.green)
                } else if status == .active {
                    ProgressView()
                        .controlSize(.small)
                        .tint(.cyan)
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
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(status == .active ? 0.1 : 0.05))
        )
    }

    private var statusColor: Color {
        switch status {
        case .pending: return .gray
        case .active: return .cyan
        case .completed: return .green
        }
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
            TopBarView(
                engine: engine,
                chordDetector: chordDetector,
                showingSettings: $showingSettings,
                showingPresets: $showingPresets
            )

            HStack(spacing: 0) {
                // Left panel
                VStack(spacing: 16) {
                    AudioVisualizationPanel(engine: engine)

                    // Compact chord display
                    CompactChordBadge(detector: chordDetector)

                    BackingTrackView(engine: engine)
                }
                .padding()
                .frame(width: 380)

                Rectangle()
                    .fill(Color.white.opacity(0.08))
                    .frame(width: 1)

                // Right panel with tab switching
                VStack(spacing: 0) {
                    // Tab selector
                    HStack(spacing: 0) {
                        ForEach(MainTab.allCases, id: \.rawValue) { tab in
                            Button {
                                withAnimation(.spring(duration: 0.3)) {
                                    selectedTab = tab
                                }
                            } label: {
                                HStack(spacing: 6) {
                                    Image(systemName: tab.icon)
                                    Text(tab.rawValue)
                                }
                                .font(.system(size: 13, weight: .medium))
                                .padding(.horizontal, 16)
                                .padding(.vertical, 10)
                                .background(
                                    selectedTab == tab
                                        ? Color.white.opacity(0.1)
                                        : Color.clear
                                )
                                .foregroundStyle(selectedTab == tab ? .white : .secondary)
                            }
                            .buttonStyle(.plain)
                        }
                        Spacer()
                    }
                    .background(Color.black.opacity(0.2))

                    // Content based on selected tab
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
                .frame(maxWidth: .infinity)
            }
        }
        .sheet(isPresented: $showingSettings) {
            SettingsView(engine: engine)
        }
        .sheet(isPresented: $showingPresets) {
            PresetPickerView(engine: engine, presetService: presetService)
        }
        .onAppear {
            setupGestureActions()
        }
    }

    private func setupGestureActions() {
        gestureController.onGestureDetected = { gesture in
            handleGesture(gesture)
        }
    }

    private func handleGesture(_ gesture: VisionGestureController.Gesture) {
        switch gesture {
        case .headNodDown:
            // Next preset - cycle through effects
            if let firstEnabled = engine.effectsChain.first(where: { $0.isEnabled }) {
                engine.toggleEffect(firstEnabled)
            }
        case .headNodUp:
            // Previous action
            break
        case .headTiltLeft, .headTiltRight:
            // Toggle first effect
            if let first = engine.effectsChain.first {
                engine.toggleEffect(first)
            }
        case .mouthOpen:
            // Could trigger wah effect
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

                // Spectrum Analyzer (FFT)
                VStack(alignment: .leading, spacing: 8) {
                    Label("Real-Time Spectrum Analysis", systemImage: "waveform.path.ecg")
                        .font(.headline)
                        .foregroundStyle(.cyan)

                    Text("Fast Fourier Transform (FFT) decomposes your audio into frequency components")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    SpectrumAnalyzerView(analyzer: fftAnalyzer)
                }

                // Chord Detection
                VStack(alignment: .leading, spacing: 8) {
                    Label("AI Chord Detection", systemImage: "pianokeys")
                        .font(.headline)
                        .foregroundStyle(.yellow)

                    Text("Pitch detection using autocorrelation algorithm identifies notes and chords")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    ChordDetectorView(detector: chordDetector)
                }

                // Vision Gesture Control
                VStack(alignment: .leading, spacing: 8) {
                    Label("Hands-Free Gesture Control", systemImage: "hand.raised.fill")
                        .font(.headline)
                        .foregroundStyle(.purple)

                    Text("Computer Vision detects head movements - control effects while playing!")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    VisionGestureControlView(controller: gestureController) { gesture in
                        // Handle gesture
                        print("Gesture: \(gesture.rawValue)")
                    }
                }

                // Educational note
                TechExplanationCard()
            }
            .padding()
        }
        .background(Color(red: 0.05, green: 0.05, blue: 0.08))
    }
}

// MARK: - Tech Explanation Card

struct TechExplanationCard: View {
    var body: some View {
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
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.green.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .strokeBorder(Color.green.opacity(0.3), lineWidth: 1)
                )
        )
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
                    .foregroundStyle(.white)

                Text(description)
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
            }
        }
    }
}

// MARK: - Top Bar View

struct TopBarView: View {
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

            // Audio Input Device indicator
            AudioInputDeviceBadge(
                deviceName: engine.currentInputDeviceName,
                deviceType: engine.currentInputDeviceType,
                onRefresh: {
                    engine.refreshInputDevices()
                }
            )

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

// MARK: - Audio Input Device Badge

struct AudioInputDeviceBadge: View {
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
                        .frame(width: 24, height: 24)

                    Image(systemName: deviceType.icon)
                        .font(.system(size: 11, weight: .semibold))
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
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .strokeBorder(deviceType.color.opacity(0.3), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(.plain)
        .help("Click to refresh audio input devices")
    }

    private func formatDeviceName(_ name: String) -> String {
        // Shorten common device names for cleaner display
        var displayName = name
            .replacingOccurrences(of: "MacBook Pro Microphone", with: "MacBook Pro Mic")
            .replacingOccurrences(of: "Built-in Microphone", with: "Built-in Mic")
            .replacingOccurrences(of: "USB Audio Device", with: "USB Audio")

        // Truncate if still too long
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

                // Effect chain preview - using abbreviations
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
