import AVFoundation
import Observation
import SwiftUI

// MARK: - Audio Engine Manager
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
    
    // 格式轉換混音器 - 用於解決輸入格式與效果單元之間的不兼容問題
    // Format conversion mixer - used to resolve incompatibility between input format and effect units
    private var formatConverterMixer: AVAudioMixerNode?

    // Backing track
    private var backingTrackPlayer: AVAudioPlayerNode?
    private var backingTrackBuffer: AVAudioPCMBuffer?

    // Visualization
    private var tapInstalled = false
    private var visualizationTimer: Timer?
    
    // 儲存處理格式供重建音頻鏈使用
    // Store processing format for rebuilding audio chain
    private var processingFormat: AVAudioFormat?

    // MARK: - Initialization

    init() {
        setupDefaultEffectsChain()
    }

    private func setupDefaultEffectsChain() {
        effectsChain = [
            EffectNode(type: .distortion, isEnabled: true),
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

        // 創建格式轉換混音器 - 這會處理輸入格式到效果處理格式的轉換
        // Create format conversion mixer - handles input to processing format conversion
        let converter = AVAudioMixerNode()
        formatConverterMixer = converter
        engine.attach(converter)
        
        // Create effect units
        effectUnits = EffectUnitsContainer()
        guard let units = effectUnits else { return }

        // Attach effects to engine
        engine.attach(units.distortion)
        engine.attach(units.delay)
        engine.attach(units.reverb)
        
        // 創建並附加伴奏播放器
        // Create and attach backing track player
        let player = AVAudioPlayerNode()
        backingTrackPlayer = player
        engine.attach(player)

        // 使用標準處理格式（立體聲 44.1kHz/48kHz）來避免格式不匹配
        // Use a standard processing format to avoid format mismatch issues
        let format = AVAudioFormat(
            standardFormatWithSampleRate: inputFormat.sampleRate,
            channels: 2
        ) ?? inputFormat
        
        // 儲存處理格式供後續使用
        // Store processing format for later use
        self.processingFormat = format

        print("setupEngine: Processing format: \(format.sampleRate)Hz, \(format.channelCount)ch")

        // Connect signal chain with format converter
        connectSignalChain(engine: engine, input: input, converter: converter, inputFormat: inputFormat, processingFormat: format)
        
        // 連接伴奏播放器到混音器
        // Connect backing track player to mixer
        if let mixer = mainMixer {
            engine.connect(player, to: mixer, format: format)
            print("setupEngine: Backing track player connected")
        }

        // 根據效果鏈設置 bypass 狀態
        // Set bypass state based on effects chain
        syncBypassStates()

        print("setupEngine: DONE - audio chain ready")
    }

    func start() throws {
        guard let engine = audioEngine else {
            throw AudioEngineError.engineNotSetup
        }

        print("Starting audio engine...")
        
        // 在引擎啟動前準備所有節點
        // Prepare all nodes before starting the engine
        engine.prepare()
        
        do {
            try engine.start()
            isRunning = true
            errorMessage = nil
            print("Audio engine started successfully")
            print("Audio engine running! Play your guitar!")
            
            // 啟動模擬可視化（穩定版本）
            // Start simulated visualization (stable version)
            startSimulatedVisualization()
        } catch {
            print("Failed to start audio engine: \(error)")
            throw error
        }
    }

    func stop() {
        // 停止可視化
        // Stop visualization
        stopVisualization()
        
        audioEngine?.stop()
        isRunning = false
        
        // 重置可視化數據
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
        
        // 使用 bypass 而不是重建整個音頻鏈（更穩定）
        // Use bypass instead of rebuilding entire chain (more stable)
        guard let units = effectUnits else {
            rebuildAudioChain()
            return
        }
        
        switch effect.type {
        case .distortion:
            units.distortion.bypass = !effect.isEnabled
        case .delay:
            units.delay.bypass = !effect.isEnabled
        case .reverb:
            units.reverb.bypass = !effect.isEnabled
        case .equalizer:
            units.equalizer?.bypass = !effect.isEnabled
        }
        
        print("toggleEffect: \(effect.type.rawValue) \(effect.isEnabled ? "enabled" : "bypassed")")
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
        
        // 同步 bypass 狀態而不是重建音頻鏈
        // Sync bypass states instead of rebuilding chain
        syncBypassStates()
        
        // 應用所有效果參數
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

        // 停止任何正在播放的內容
        // Stop any currently playing content
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

    private func connectSignalChain(engine: AVAudioEngine, input: AVAudioInputNode, converter: AVAudioMixerNode, inputFormat: AVAudioFormat, processingFormat: AVAudioFormat) {
        guard let units = effectUnits, let mixer = mainMixer else { return }

        // 使用格式轉換混音器作為中間節點
        // Use format conversion mixer as intermediate node
        // Input -> Converter (原生格式轉為處理格式)
        // Input -> Converter (native format to processing format)
        engine.connect(input, to: converter, format: inputFormat)
        
        // 始終連接所有效果器，使用 bypass 屬性控制是否啟用
        // Always connect all effects, use bypass property to control enable/disable
        // Converter -> Distortion -> Delay -> Reverb -> Mixer
        engine.connect(converter, to: units.distortion, format: processingFormat)
        engine.connect(units.distortion, to: units.delay, format: processingFormat)
        engine.connect(units.delay, to: units.reverb, format: processingFormat)
        engine.connect(units.reverb, to: mixer, format: processingFormat)
        
        print("connectSignalChain: Signal chain connected (all effects in chain, controlled via bypass)")
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

        // 移除可視化 tap（如果已安裝）
        // Remove visualization tap if installed
        if tapInstalled {
            mixer.removeTap(onBus: 0)
            tapInstalled = false
        }

        // 安全地斷開所有節點
        // Safely disconnect all nodes
        // 只斷開已連接的節點
        // Only disconnect nodes that are connected
        if engine.attachedNodes.contains(converter) {
            engine.disconnectNodeOutput(converter)
        }
        if engine.attachedNodes.contains(units.distortion) {
            engine.disconnectNodeOutput(units.distortion)
        }
        if engine.attachedNodes.contains(units.delay) {
            engine.disconnectNodeOutput(units.delay)
        }
        if engine.attachedNodes.contains(units.reverb) {
            engine.disconnectNodeOutput(units.reverb)
        }
        if let eq = units.equalizer, engine.attachedNodes.contains(eq) {
            engine.disconnectNodeOutput(eq)
        }
        // 不要斷開 inputNode - 它是引擎的內建節點
        // Don't disconnect inputNode - it's a built-in engine node
        engine.disconnectNodeInput(converter)

        // 獲取格式
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

        // 重新連接信號鏈
        // Reconnect signal chain
        
        // Input -> Converter
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

    private func applyEffectParameters(_ effect: EffectNode) {
        guard let units = effectUnits else { return }

        switch effect.type {
        case .distortion:
            units.distortion.wetDryMix = effect.parameters["mix"] ?? 50

        case .delay:
            units.delay.delayTime = TimeInterval(effect.parameters["time"] ?? 0.3)
            units.delay.feedback = effect.parameters["feedback"] ?? 40
            units.delay.wetDryMix = effect.parameters["mix"] ?? 30

        case .reverb:
            units.reverb.wetDryMix = effect.parameters["wetDryMix"] ?? 40

        case .equalizer:
            if let eq = units.equalizer {
                eq.bands[0].gain = effect.parameters["bass"] ?? 0
                eq.bands[1].gain = effect.parameters["mid"] ?? 0
                eq.bands[2].gain = effect.parameters["treble"] ?? 0
            }
        }
    }
    
    /// 同步所有效果器的 bypass 狀態
    /// Sync bypass state for all effects
    private func syncBypassStates() {
        guard let units = effectUnits else { return }
        
        for effect in effectsChain {
            switch effect.type {
            case .distortion:
                units.distortion.bypass = !effect.isEnabled
            case .delay:
                units.delay.bypass = !effect.isEnabled
            case .reverb:
                units.reverb.bypass = !effect.isEnabled
            case .equalizer:
                units.equalizer?.bypass = !effect.isEnabled
            }
        }
        
        print("syncBypassStates: Bypass states synchronized")
    }

    // MARK: - Simulated Visualization
    // 使用模擬數據展示可視化效果
    // Use simulated data for visualization display
    
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
// Following Single Responsibility: Only manages audio unit instances

private final class EffectUnitsContainer {
    let distortion: AVAudioUnitDistortion
    let delay: AVAudioUnitDelay
    let reverb: AVAudioUnitReverb
    let equalizer: AVAudioUnitEQ?

    init() {
        distortion = AVAudioUnitDistortion()
        distortion.loadFactoryPreset(.drumsBitBrush)
        distortion.wetDryMix = 50

        delay = AVAudioUnitDelay()
        delay.delayTime = 0.3
        delay.feedback = 40
        delay.wetDryMix = 30

        reverb = AVAudioUnitReverb()
        reverb.loadFactoryPreset(.mediumHall)
        reverb.wetDryMix = 40

        // EQ is optional - create lazily if needed
        equalizer = nil
    }

    func audioUnit(for type: EffectType) -> AVAudioUnit? {
        switch type {
        case .distortion: return distortion
        case .delay: return delay
        case .reverb: return reverb
        case .equalizer: return equalizer
        }
    }
}
