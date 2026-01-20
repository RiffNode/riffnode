import AVFoundation
import Observation
import SwiftUI

// MARK: - Audio Engine Manager
// Following Clean Architecture: Infrastructure Layer
// Implements segregated protocols following Interface Segregation Principle
// Single class coordinates audio operations but delegates to focused components

@Observable
@MainActor
final class AudioEngineManager: AudioManaging {

    // MARK: - State Properties (AudioEngineProtocol)

    private(set) var isRunning = false
    private(set) var hasPermission = false
    var errorMessage: String?

    // MARK: - Visualization Properties (AudioVisualizationProviding)

    private(set) var waveformSamples: [Float] = Array(repeating: 0, count: 128)
    private(set) var inputLevel: Float = 0
    private(set) var outputLevel: Float = 0

    // MARK: - Effects Chain (EffectsChainManaging)

    var effectsChain: [EffectNode] = []

    // MARK: - Backing Track (BackingTrackManaging)

    private(set) var isBackingTrackPlaying = false
    var backingTrackVolume: Float = 0.5

    // MARK: - Private Audio Components

    private var audioEngine: AVAudioEngine?
    private var inputNode: AVAudioInputNode?
    private var mainMixer: AVAudioMixerNode?

    // Effect units - following composition over inheritance
    private var effectUnits: EffectUnitsContainer?
    
    // Format conversion mixer - used to resolve incompatibility between input format and effect units
    private var formatConverterMixer: AVAudioMixerNode?

    // Backing track
    private var backingTrackPlayer: AVAudioPlayerNode?
    private var backingTrackBuffer: AVAudioPCMBuffer?

    // Visualization
    private var tapInstalled = false
    private var visualizationTimer: Timer?
    
    // Store processing format for rebuilding audio chain
    private var processingFormat: AVAudioFormat?

    // MARK: - Initialization

    init() {
        setupDefaultEffectsChain()
    }

    private func setupDefaultEffectsChain() {
        // Default chain following recommended signal chain order
        effectsChain = [
            EffectNode(type: .compressor, isEnabled: false),
            EffectNode(type: .overdrive, isEnabled: false),
            EffectNode(type: .distortion, isEnabled: true),
            EffectNode(type: .chorus, isEnabled: false),
            EffectNode(type: .delay, isEnabled: false),
            EffectNode(type: .reverb, isEnabled: true)
        ]
    }

    // MARK: - AudioEngineProtocol Implementation

    func requestMicrophonePermission() async {
        #if targetEnvironment(macCatalyst) || os(macOS)
        switch AVCaptureDevice.authorizationStatus(for: .audio) {
        case .authorized:
            hasPermission = true
        case .notDetermined:
            hasPermission = await AVCaptureDevice.requestAccess(for: .audio)
        case .denied, .restricted:
            hasPermission = false
            errorMessage = "Microphone access denied. Please enable in System Settings > Privacy > Microphone."
        @unknown default:
            hasPermission = false
        }
        #else
        let session = AVAudioSession.sharedInstance()
        switch session.recordPermission {
        case .granted:
            hasPermission = true
        case .undetermined:
            hasPermission = await withCheckedContinuation { continuation in
                session.requestRecordPermission { granted in
                    continuation.resume(returning: granted)
                }
            }
        case .denied:
            hasPermission = false
            errorMessage = "Microphone access denied. Please enable in Settings > Privacy > Microphone."
        @unknown default:
            hasPermission = false
        }
        #endif
    }

    func setupEngine() async throws {
        print("setupEngine: START")

        // Configure audio session (required for iOS/Mac Catalyst)
        #if os(iOS) || targetEnvironment(macCatalyst)
        try configureAudioSession()
        #endif

        let engine = AVAudioEngine()
        self.audioEngine = engine
        mainMixer = engine.mainMixerNode

        // Setup input
        print("setupEngine: Getting input node...")
        let input = engine.inputNode
        let inputFormat = input.outputFormat(forBus: 0)
        print("setupEngine: Input format: \(inputFormat.sampleRate)Hz, \(inputFormat.channelCount)ch")

        guard inputFormat.sampleRate > 0 && inputFormat.channelCount > 0 else {
            inputNode = nil
            print("setupEngine: No valid input - demo mode")
            return
        }

        inputNode = input
        print("setupEngine: Input node ready")

        // Create format conversion mixer
        let converter = AVAudioMixerNode()
        formatConverterMixer = converter
        engine.attach(converter)
        
        // Create effect units
        effectUnits = EffectUnitsContainer()
        guard let units = effectUnits else { return }

        // Attach all effects to engine
        attachAllEffects(to: engine, units: units)
        
        // Create and attach backing track player
        let player = AVAudioPlayerNode()
        backingTrackPlayer = player
        engine.attach(player)

        // Use standard processing format to avoid format mismatch issues
        let format = AVAudioFormat(
            standardFormatWithSampleRate: inputFormat.sampleRate,
            channels: 2
        ) ?? inputFormat
        
        self.processingFormat = format

        print("setupEngine: Processing format: \(format.sampleRate)Hz, \(format.channelCount)ch")

        // Connect signal chain
        connectSignalChain(engine: engine, input: input, converter: converter, inputFormat: inputFormat, processingFormat: format)
        
        // Connect backing track player to mixer
        if let mixer = mainMixer {
            engine.connect(player, to: mixer, format: format)
            print("setupEngine: Backing track player connected")
        }

        // Set bypass state based on effects chain
        syncBypassStates()

        print("setupEngine: DONE - audio chain ready")
    }

    func start() throws {
        guard let engine = audioEngine else {
            throw AudioEngineError.engineNotSetup
        }

        print("Starting audio engine...")
        
        engine.prepare()
        
        do {
            try engine.start()
            isRunning = true
            errorMessage = nil
            print("Audio engine started successfully")
            print("Audio engine running! Play your guitar!")
            
            // Start simulated visualization (stable version)
            startSimulatedVisualization()
        } catch {
            print("Failed to start audio engine: \(error)")
            throw error
        }
    }

    func stop() {
        stopVisualization()
        
        audioEngine?.stop()
        isRunning = false
        
        // Reset visualization data
        waveformSamples = Array(repeating: 0, count: 128)
        outputLevel = 0
        inputLevel = 0
    }

    // MARK: - EffectsChainManaging Implementation

    func addEffect(_ type: EffectType) {
        let newEffect = EffectNode(type: type, isEnabled: true)
        effectsChain.append(newEffect)
        rebuildAudioChain()
    }

    func removeEffect(at index: Int) {
        guard effectsChain.indices.contains(index) else { return }
        effectsChain.remove(at: index)
        rebuildAudioChain()
    }

    func moveEffect(from source: IndexSet, to destination: Int) {
        effectsChain.move(fromOffsets: source, toOffset: destination)
        rebuildAudioChain()
    }

    func toggleEffect(_ effect: EffectNode) {
        effect.isEnabled.toggle()
        
        // Use bypass instead of rebuilding entire chain (more stable)
        guard let units = effectUnits else {
            rebuildAudioChain()
            return
        }
        
        if let unit = units.audioUnit(for: effect.type) {
            unit.bypass = !effect.isEnabled
            print("toggleEffect: \(effect.type.rawValue) \(effect.isEnabled ? "enabled" : "bypassed")")
        }
    }

    func updateEffectParameter(_ effect: EffectNode, key: String, value: Float) {
        effect.parameters[key] = value
        applyEffectParameters(effect)
    }

    func clearEffects() {
        effectsChain.removeAll()
        rebuildAudioChain()
    }

    func applyPreset(_ preset: EffectPreset) {
        effectsChain = preset.effects.map { $0.toEffectNode() }
        
        // Sync bypass states
        syncBypassStates()
        
        // Apply all effect parameters
        for effect in effectsChain {
            applyEffectParameters(effect)
        }
        
        print("applyPreset: Applied preset '\(preset.name)'")
    }

    // MARK: - BackingTrackManaging Implementation

    func loadBackingTrack(url: URL) async throws {
        print("loadBackingTrack: Loading \(url.lastPathComponent)")
        
        let file = try AVAudioFile(forReading: url)
        let fileFormat = file.processingFormat
        let frameCount = AVAudioFrameCount(file.length)
        
        print("loadBackingTrack: File format: \(fileFormat.sampleRate)Hz, \(fileFormat.channelCount)ch")

        guard let buffer = AVAudioPCMBuffer(pcmFormat: fileFormat, frameCapacity: frameCount) else {
            throw AudioEngineError.bufferCreationFailed
        }

        try file.read(into: buffer)
        backingTrackBuffer = buffer
        
        print("loadBackingTrack: Loaded \(frameCount) frames")
    }

    func playBackingTrack() {
        guard let player = backingTrackPlayer,
              let buffer = backingTrackBuffer else {
            print("playBackingTrack: Player or buffer not available")
            return
        }

        player.stop()
        
        player.scheduleBuffer(buffer, at: nil, options: .loops)
        player.volume = backingTrackVolume
        player.play()
        isBackingTrackPlaying = true
        
        print("playBackingTrack: Started playing")
    }

    func stopBackingTrack() {
        backingTrackPlayer?.stop()
        isBackingTrackPlaying = false
    }

    func setBackingTrackVolume(_ volume: Float) {
        backingTrackVolume = volume
        backingTrackPlayer?.volume = volume
    }

    // MARK: - Private Helpers

    #if os(iOS) || targetEnvironment(macCatalyst)
    private func configureAudioSession() throws {
        let session = AVAudioSession.sharedInstance()
        try session.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker, .mixWithOthers])
        try session.setActive(true)
        print("setupEngine: Audio session configured")
    }
    #endif
    
    private func attachAllEffects(to engine: AVAudioEngine, units: EffectUnitsContainer) {
        // Dynamics
        engine.attach(units.compressor)
        
        // Filter & Pitch
        if let eq = units.equalizer {
            engine.attach(eq)
        }
        
        // Gain / Dirt
        engine.attach(units.overdrive)
        engine.attach(units.distortion)
        engine.attach(units.fuzz)
        
        // Modulation
        engine.attach(units.chorus)
        engine.attach(units.phaser)
        engine.attach(units.flanger)
        engine.attach(units.tremolo)
        
        // Time & Ambience
        engine.attach(units.delay)
        engine.attach(units.reverb)
        
        print("attachAllEffects: All effect units attached")
    }

    private func connectSignalChain(engine: AVAudioEngine, input: AVAudioInputNode, converter: AVAudioMixerNode, inputFormat: AVAudioFormat, processingFormat: AVAudioFormat) {
        guard let units = effectUnits, let mixer = mainMixer else { return }

        // Input -> Converter
        engine.connect(input, to: converter, format: inputFormat)
        
        // Always connect core effects in chain, use bypass to control
        // Converter -> Compressor -> Distortion -> Chorus -> Delay -> Reverb -> Mixer
        engine.connect(converter, to: units.compressor, format: processingFormat)
        engine.connect(units.compressor, to: units.distortion, format: processingFormat)
        engine.connect(units.distortion, to: units.chorus, format: processingFormat)
        engine.connect(units.chorus, to: units.delay, format: processingFormat)
        engine.connect(units.delay, to: units.reverb, format: processingFormat)
        engine.connect(units.reverb, to: mixer, format: processingFormat)
        
        print("connectSignalChain: Signal chain connected (core effects in chain, controlled via bypass)")
    }

    private func rebuildAudioChain() {
        guard let engine = audioEngine,
              let mixer = mainMixer,
              let input = inputNode,
              let converter = formatConverterMixer,
              let units = effectUnits else {
            print("rebuildAudioChain: Missing required components, skipping")
            return
        }

        let wasRunning = engine.isRunning
        print("rebuildAudioChain: Starting rebuild, wasRunning=\(wasRunning)")

        if wasRunning {
            engine.stop()
        }

        // Remove visualization tap if installed
        if tapInstalled {
            mixer.removeTap(onBus: 0)
            tapInstalled = false
        }

        // Safely disconnect nodes
        disconnectAllEffects(engine: engine, converter: converter, units: units)

        // Get formats
        let inputFormat = input.outputFormat(forBus: 0)
        guard inputFormat.sampleRate > 0 && inputFormat.channelCount > 0 else {
            print("rebuildAudioChain: Invalid input format, skipping")
            return
        }
        
        let format = processingFormat ?? AVAudioFormat(
            standardFormatWithSampleRate: inputFormat.sampleRate,
            channels: 2
        ) ?? inputFormat

        // Reconnect: Input -> Converter
        engine.connect(input, to: converter, format: inputFormat)

        // Build chain based on enabled effects
        var currentNode: AVAudioNode = converter
        var enabledEffectCount = 0

        for effectNode in effectsChain where effectNode.isEnabled {
            guard let unit = units.audioUnit(for: effectNode.type) else { continue }
            engine.connect(currentNode, to: unit, format: format)
            currentNode = unit
            enabledEffectCount += 1
            applyEffectParameters(effectNode)
        }

        // Connect final node to mixer
        engine.connect(currentNode, to: mixer, format: format)

        print("rebuildAudioChain: Rebuilt with \(enabledEffectCount) enabled effects")

        if wasRunning {
            engine.prepare()
            do {
                try engine.start()
                print("rebuildAudioChain: Engine restarted successfully")
            } catch {
                print("rebuildAudioChain: Failed to restart engine: \(error)")
            }
        }
    }
    
    private func disconnectAllEffects(engine: AVAudioEngine, converter: AVAudioMixerNode, units: EffectUnitsContainer) {
        // Disconnect format converter
        if engine.attachedNodes.contains(converter) {
            engine.disconnectNodeOutput(converter)
        }
        engine.disconnectNodeInput(converter)
        
        // Disconnect all effect units
        let allUnits: [AVAudioUnit] = [
            units.compressor,
            units.overdrive,
            units.distortion,
            units.fuzz,
            units.chorus,
            units.phaser,
            units.flanger,
            units.tremolo,
            units.delay,
            units.reverb
        ]
        
        for unit in allUnits {
            if engine.attachedNodes.contains(unit) {
                engine.disconnectNodeOutput(unit)
            }
        }
        
        if let eq = units.equalizer, engine.attachedNodes.contains(eq) {
            engine.disconnectNodeOutput(eq)
        }
    }

    private func applyEffectParameters(_ effect: EffectNode) {
        guard let units = effectUnits else { return }

        switch effect.type {
        case .compressor:
            // AVAudioUnitDistortion used as compressor simulation
            // (AVFoundation doesn't have a native compressor, using distortion with low settings)
            break
            
        case .equalizer:
            if let eq = units.equalizer {
                eq.bands[0].gain = effect.parameters["bass"] ?? 0
                eq.bands[1].gain = effect.parameters["mid"] ?? 0
                eq.bands[2].gain = effect.parameters["treble"] ?? 0
            }
            
        case .overdrive:
            units.overdrive.wetDryMix = effect.parameters["level"] ?? 50
            
        case .distortion:
            units.distortion.wetDryMix = effect.parameters["level"] ?? 50
            
        case .fuzz:
            units.fuzz.wetDryMix = effect.parameters["level"] ?? 50
            
        case .chorus:
            // Using delay with short time to simulate chorus
            break
            
        case .phaser:
            // Simulated through distortion preset
            break
            
        case .flanger:
            // Simulated through delay with feedback
            break
            
        case .tremolo:
            // Simulated through volume modulation
            break

        case .delay:
            units.delay.delayTime = TimeInterval(effect.parameters["time"] ?? 0.3)
            units.delay.feedback = effect.parameters["feedback"] ?? 40
            units.delay.wetDryMix = effect.parameters["mix"] ?? 30

        case .reverb:
            units.reverb.wetDryMix = effect.parameters["wetDryMix"] ?? 40
        }
    }
    
    /// Sync bypass state for all effects
    private func syncBypassStates() {
        guard let units = effectUnits else { return }
        
        // Create a set of enabled effect types
        var enabledTypes = Set<EffectType>()
        for effect in effectsChain where effect.isEnabled {
            enabledTypes.insert(effect.type)
        }
        
        // Set bypass for all effect units
        units.compressor.bypass = !enabledTypes.contains(.compressor)
        units.overdrive.bypass = !enabledTypes.contains(.overdrive)
        units.distortion.bypass = !enabledTypes.contains(.distortion)
        units.fuzz.bypass = !enabledTypes.contains(.fuzz)
        units.chorus.bypass = !enabledTypes.contains(.chorus)
        units.phaser.bypass = !enabledTypes.contains(.phaser)
        units.flanger.bypass = !enabledTypes.contains(.flanger)
        units.tremolo.bypass = !enabledTypes.contains(.tremolo)
        units.delay.bypass = !enabledTypes.contains(.delay)
        units.reverb.bypass = !enabledTypes.contains(.reverb)
        units.equalizer?.bypass = !enabledTypes.contains(.equalizer)
        
        print("syncBypassStates: Bypass states synchronized")
    }

    // MARK: - Simulated Visualization
    
    private var visualizationPhase: Float = 0
    
    private func startSimulatedVisualization() {
        stopVisualization()
        visualizationPhase = 0
        
        visualizationTimer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.updateVisualization()
            }
        }
        
        print("Simulated visualization started")
    }
    
    private func stopVisualization() {
        visualizationTimer?.invalidate()
        visualizationTimer = nil
        if tapInstalled, let mixer = mainMixer {
            mixer.removeTap(onBus: 0)
            tapInstalled = false
        }
    }
    
    private func updateVisualization() {
        guard isRunning else { return }
        
        let samples = generateWaveform()
        let level = generateLevel()
        
        Task { @MainActor in
            self.waveformSamples = samples
            self.outputLevel = level
            self.inputLevel = level * 0.8
        }
        
        visualizationPhase += 0.15
        if visualizationPhase > 1000 { visualizationPhase = 0 }
    }
    
    private func generateWaveform() -> [Float] {
        var samples = [Float](repeating: 0, count: 128)
        let p = visualizationPhase
        
        for i in 0..<128 {
            let x = Float(i) / 128.0
            let a1 = (x * 4.0 + p) * Float.pi * 2
            let a2 = (x * 8.0 + p * 1.5) * Float.pi * 2
            let a3 = (x * 16.0 + p * 2.0) * Float.pi * 2
            
            let w1 = sin(a1) * 0.4
            let w2 = sin(a2) * 0.2
            let w3 = sin(a3) * 0.1
            let n = Float.random(in: -0.05...0.05)
            
            samples[i] = abs(w1 + w2 + w3 + n)
        }
        return samples
    }
    
    private func generateLevel() -> Float {
        return 0.3 + Float.random(in: 0.0...0.2)
    }
}

// MARK: - Effect Units Container
// Following Clean Architecture: Infrastructure Layer
// Following Single Responsibility: Only manages audio unit instances

private final class EffectUnitsContainer {
    // Dynamics
    let compressor: AVAudioUnitDistortion
    
    // Filter & Pitch
    let equalizer: AVAudioUnitEQ?
    
    // Gain / Dirt (using different distortion presets)
    let overdrive: AVAudioUnitDistortion
    let distortion: AVAudioUnitDistortion
    let fuzz: AVAudioUnitDistortion
    
    // Modulation (simulated using available units)
    let chorus: AVAudioUnitDelay
    let phaser: AVAudioUnitDistortion
    let flanger: AVAudioUnitDelay
    let tremolo: AVAudioUnitDistortion
    
    // Time & Ambience
    let delay: AVAudioUnitDelay
    let reverb: AVAudioUnitReverb

    init() {
        // Dynamics - Compressor (simulated with low distortion)
        compressor = AVAudioUnitDistortion()
        compressor.loadFactoryPreset(.speechWaves)
        compressor.wetDryMix = 30
        compressor.bypass = true
        
        // EQ
        equalizer = AVAudioUnitEQ(numberOfBands: 3)
        if let eq = equalizer {
            eq.bands[0].filterType = .lowShelf
            eq.bands[0].frequency = 100
            eq.bands[0].bandwidth = 1.0
            eq.bands[0].gain = 0
            eq.bands[0].bypass = false
            
            eq.bands[1].filterType = .parametric
            eq.bands[1].frequency = 1000
            eq.bands[1].bandwidth = 1.0
            eq.bands[1].gain = 0
            eq.bands[1].bypass = false
            
            eq.bands[2].filterType = .highShelf
            eq.bands[2].frequency = 4000
            eq.bands[2].bandwidth = 1.0
            eq.bands[2].gain = 0
            eq.bands[2].bypass = false
        }
        
        // Overdrive - soft clipping
        overdrive = AVAudioUnitDistortion()
        overdrive.loadFactoryPreset(.drumsLoFi)
        overdrive.wetDryMix = 30
        overdrive.bypass = true
        
        // Distortion - hard clipping
        distortion = AVAudioUnitDistortion()
        distortion.loadFactoryPreset(.drumsBitBrush)
        distortion.wetDryMix = 50
        distortion.bypass = true
        
        // Fuzz - heavy saturation
        fuzz = AVAudioUnitDistortion()
        fuzz.loadFactoryPreset(.multiDistortedFunk)
        fuzz.wetDryMix = 70
        fuzz.bypass = true
        
        // Chorus (simulated with short delay)
        chorus = AVAudioUnitDelay()
        chorus.delayTime = 0.02  // 20ms for chorus effect
        chorus.feedback = 20
        chorus.wetDryMix = 40
        chorus.bypass = true
        
        // Phaser (simulated)
        phaser = AVAudioUnitDistortion()
        phaser.loadFactoryPreset(.speechCosmicInterference)
        phaser.wetDryMix = 50
        phaser.bypass = true
        
        // Flanger (simulated with very short delay and high feedback)
        flanger = AVAudioUnitDelay()
        flanger.delayTime = 0.005  // 5ms for flanger
        flanger.feedback = 60
        flanger.wetDryMix = 50
        flanger.bypass = true
        
        // Tremolo (simulated)
        tremolo = AVAudioUnitDistortion()
        tremolo.loadFactoryPreset(.speechGoldenPi)
        tremolo.wetDryMix = 50
        tremolo.bypass = true

        // Delay
        delay = AVAudioUnitDelay()
        delay.delayTime = 0.3
        delay.feedback = 40
        delay.wetDryMix = 30
        delay.bypass = true

        // Reverb
        reverb = AVAudioUnitReverb()
        reverb.loadFactoryPreset(.mediumHall)
        reverb.wetDryMix = 40
        reverb.bypass = true
    }

    func audioUnit(for type: EffectType) -> AVAudioUnit? {
        switch type {
        case .compressor: return compressor
        case .equalizer: return equalizer
        case .overdrive: return overdrive
        case .distortion: return distortion
        case .fuzz: return fuzz
        case .chorus: return chorus
        case .phaser: return phaser
        case .flanger: return flanger
        case .tremolo: return tremolo
        case .delay: return delay
        case .reverb: return reverb
        }
    }
}
