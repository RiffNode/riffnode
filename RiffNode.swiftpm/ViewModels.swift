import SwiftUI
import Observation

// MARK: - View Models
// Following MVVM pattern within Clean Architecture
// ViewModels handle presentation logic and coordinate between Views and Services

// MARK: - Setup View Model

/// Handles the onboarding/setup flow logic
@Observable
@MainActor
final class SetupViewModel {

    // MARK: - State

    enum SetupStep: Int, CaseIterable {
        case welcome = 0
        case permission = 1
        case engine = 2
        case ready = 3

        var title: String {
            switch self {
            case .welcome: return "Welcome"
            case .permission: return "Microphone Access"
            case .engine: return "Audio Engine"
            case .ready: return "Ready to Rock"
            }
        }

        var description: String {
            switch self {
            case .welcome: return "Let's get started"
            case .permission: return "Connect your guitar through an audio interface"
            case .engine: return "Initialize the effects processing engine"
            case .ready: return "Start creating your sound"
            }
        }

        var icon: String {
            switch self {
            case .welcome: return "hand.wave.fill"
            case .permission: return "mic.fill"
            case .engine: return "waveform.path.ecg"
            case .ready: return "guitars.fill"
            }
        }
    }

    private(set) var currentStep: SetupStep = .welcome
    private(set) var isLoading = false
    var isSetupComplete = false

    // MARK: - Dependencies

    private let audioEngine: AudioEngineProtocol

    // MARK: - Initialization

    init(audioEngine: AudioEngineProtocol) {
        self.audioEngine = audioEngine
    }

    // MARK: - Computed Properties

    var buttonTitle: String {
        switch currentStep {
        case .welcome: return "Get Started"
        case .permission: return "Allow Access"
        case .engine: return "Start Engine"
        case .ready: return "Let's Rock!"
        }
    }

    var hasPermission: Bool {
        audioEngine.hasPermission
    }

    var isEngineRunning: Bool {
        audioEngine.isRunning
    }

    var errorMessage: String? {
        get { audioEngine.errorMessage }
        set { audioEngine.errorMessage = newValue }
    }

    // MARK: - Actions

    func performNextStep() async {
        isLoading = true

        do {
            switch currentStep {
            case .welcome:
                advanceStep()

            case .permission:
                await audioEngine.requestMicrophonePermission()
                if audioEngine.hasPermission {
                    advanceStep()
                } else if audioEngine.errorMessage == nil {
                    audioEngine.errorMessage = "Microphone permission is required to continue."
                }

            case .engine:
                try await audioEngine.setupEngine()
                try audioEngine.start()
                advanceStep()
                audioEngine.errorMessage = nil

            case .ready:
                isSetupComplete = true
            }
        } catch {
            audioEngine.errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    private func advanceStep() {
        withAnimation(.spring(duration: 0.3)) {
            if let nextStep = SetupStep(rawValue: currentStep.rawValue + 1) {
                currentStep = nextStep
            }
        }
    }

    func stepStatus(for step: SetupStep) -> StepStatus {
        if step.rawValue < currentStep.rawValue {
            return .completed
        } else if step == currentStep {
            return .active
        }
        return .pending
    }

    enum StepStatus {
        case pending, active, completed
    }
}

// MARK: - Preset Picker View Model

/// Handles preset selection and filtering logic
@Observable
@MainActor
final class PresetPickerViewModel {

    // MARK: - State

    var selectedCategory: EffectPreset.PresetCategory?
    var selectedPreset: EffectPreset?

    // MARK: - Dependencies

    private let presetService: PresetProviding
    private let effectsManager: EffectsChainManaging

    // MARK: - Initialization

    init(presetService: PresetProviding, effectsManager: EffectsChainManaging) {
        self.presetService = presetService
        self.effectsManager = effectsManager
    }

    // MARK: - Computed Properties

    var filteredPresets: [EffectPreset] {
        if let category = selectedCategory {
            return presetService.presets(for: category)
        }
        return presetService.presets
    }

    var categories: [EffectPreset.PresetCategory] {
        EffectPreset.PresetCategory.allCases
    }

    // MARK: - Actions

    func selectCategory(_ category: EffectPreset.PresetCategory?) {
        withAnimation {
            selectedCategory = category
        }
    }

    func selectPreset(_ preset: EffectPreset) {
        selectedPreset = preset
        effectsManager.applyPreset(preset)
    }

    func isPresetSelected(_ preset: EffectPreset) -> Bool {
        selectedPreset?.id == preset.id
    }
}

// MARK: - Effects Chain View Model

/// Handles effects chain manipulation logic
@Observable
@MainActor
final class EffectsChainViewModel {

    // MARK: - State

    var selectedEffect: EffectNode?

    // MARK: - Dependencies

    private let effectsManager: EffectsChainManaging

    // MARK: - Initialization

    init(effectsManager: EffectsChainManaging) {
        self.effectsManager = effectsManager
    }

    // MARK: - Computed Properties

    var effects: [EffectNode] {
        effectsManager.effectsChain
    }

    var availableEffectTypes: [EffectType] {
        EffectType.allCases
    }

    // MARK: - Actions

    func addEffect(_ type: EffectType) {
        withAnimation(.spring(duration: 0.3)) {
            effectsManager.addEffect(type)
        }
    }

    func removeEffect(at index: Int) {
        withAnimation {
            if selectedEffect?.id == effects[safe: index]?.id {
                selectedEffect = nil
            }
            effectsManager.removeEffect(at: index)
        }
    }

    func moveEffect(from source: IndexSet, to destination: Int) {
        withAnimation(.spring(duration: 0.3)) {
            effectsManager.moveEffect(from: source, to: destination)
        }
    }

    func toggleEffect(_ effect: EffectNode) {
        effectsManager.toggleEffect(effect)
    }

    func updateParameter(_ effect: EffectNode, key: String, value: Float) {
        effectsManager.updateEffectParameter(effect, key: key, value: value)
    }

    func selectEffect(_ effect: EffectNode?) {
        withAnimation(.spring(duration: 0.3)) {
            if selectedEffect?.id == effect?.id {
                selectedEffect = nil
            } else {
                selectedEffect = effect
            }
        }
    }

    func isSelected(_ effect: EffectNode) -> Bool {
        selectedEffect?.id == effect.id
    }

    func parameterBinding(for effect: EffectNode, key: String) -> Binding<Float> {
        Binding(
            get: { effect.parameters[key] ?? 0 },
            set: { [weak self] newValue in
                self?.updateParameter(effect, key: key, value: newValue)
            }
        )
    }
}

// MARK: - Backing Track View Model

/// Handles backing track playback logic
@Observable
@MainActor
final class BackingTrackViewModel {

    // MARK: - State

    var loadedTrackName: String?
    var isLoading = false
    var reelRotation: Double = 0

    // MARK: - Dependencies

    private let backingTrackManager: BackingTrackManaging

    // MARK: - Initialization

    init(backingTrackManager: BackingTrackManaging) {
        self.backingTrackManager = backingTrackManager
    }

    // MARK: - Computed Properties

    var isPlaying: Bool {
        backingTrackManager.isBackingTrackPlaying
    }

    var hasTrack: Bool {
        loadedTrackName != nil
    }

    var volume: Float {
        get { backingTrackManager.backingTrackVolume }
        set { backingTrackManager.setBackingTrackVolume(newValue) }
    }

    // MARK: - Actions

    func loadTrack(url: URL) async {
        isLoading = true
        loadedTrackName = url.lastPathComponent

        do {
            let accessing = url.startAccessingSecurityScopedResource()
            defer {
                if accessing {
                    url.stopAccessingSecurityScopedResource()
                }
            }

            try await backingTrackManager.loadBackingTrack(url: url)
        } catch {
            loadedTrackName = nil
            print("Failed to load backing track: \(error)")
        }

        isLoading = false
    }

    func play() {
        backingTrackManager.playBackingTrack()
        startReelAnimation()
    }

    func stop() {
        backingTrackManager.stopBackingTrack()
        stopReelAnimation()
    }

    func togglePlayback() {
        if isPlaying {
            stop()
        } else {
            play()
        }
    }

    // MARK: - Reel Animation

    private var reelAnimationTask: Task<Void, Never>?

    func startReelAnimation() {
        stopReelAnimation()
        reelAnimationTask = Task {
            await runReelAnimationLoop()
        }
    }

    private func runReelAnimationLoop() async {
        while !Task.isCancelled && isPlaying {
            withAnimation(.linear(duration: 0.03)) {
                reelRotation += 2
            }
            try? await Task.sleep(for: .milliseconds(30))
        }
    }

    func stopReelAnimation() {
        reelAnimationTask?.cancel()
        reelAnimationTask = nil
    }
}

// MARK: - Array Safe Subscript Extension

extension Array {
    subscript(safe index: Index) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
