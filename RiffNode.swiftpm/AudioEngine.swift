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
            
            // 暫時禁用可視化 tap 以測試穩定性
            // Temporarily disable visualization tap to test stability
            // 如果這樣不崩潰，問題在可視化處理中
            // If this doesn't crash, the problem is in visualization processing
            
            // Task { @MainActor in
            //     try? await Task.sleep(for: .milliseconds(500))
            //     self.installVisualizationTap()
            // }
        } catch {
            print("Failed to start audio engine: \(error)")
            throw error
        }
    }

    func stop() {
        // 移除可視化 tap
        // Remove visualization tap
        if tapInstalled, let mixer = mainMixer {
            mixer.removeTap(onBus: 0)
            tapInstalled = false
        }
        
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
        let file = try AVAudioFile(forReading: url)
        let format = file.processingFormat
        let frameCount = AVAudioFrameCount(file.length)

        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount) else {
            throw AudioEngineError.bufferCreationFailed
        }

        try file.read(into: buffer)
        backingTrackBuffer = buffer
    }

    func playBackingTrack() {
        guard let player = backingTrackPlayer,
              let buffer = backingTrackBuffer else { return }

        player.scheduleBuffer(buffer, at: nil, options: .loops)
        player.volume = backingTrackVolume
        player.play()
        isBackingTrackPlaying = true
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

        // 安全地斷開所有節點 - 使用 try-catch 避免崩潰
        // Safely disconnect all nodes - use do-catch to prevent crashes
        do {
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
        } catch {
            print("rebuildAudioChain: Error disconnecting nodes: \(error)")
        }

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

    private func installVisualizationTap() {
        guard let mixer = mainMixer, inputNode != nil else {
            print("Skipping visualization tap (demo mode)")
            return
        }
        
        // 如果已經安裝，先移除再重新安裝
        // If already installed, remove first then reinstall
        if tapInstalled {
            mixer.removeTap(onBus: 0)
            tapInstalled = false
        }

        let format = mixer.outputFormat(forBus: 0)

        guard format.sampleRate > 0 && format.channelCount > 0 else {
            print("Invalid mixer format, skipping visualization tap")
            return
        }

        // 使用較大的緩衝區來減少 CPU 負載
        // Use larger buffer size to reduce CPU load
        let bufferSize: AVAudioFrameCount = 4096

        // 使用閉包內直接處理，避免跨線程問題
        // Process directly in closure to avoid cross-thread issues
        mixer.installTap(onBus: 0, bufferSize: bufferSize, format: nil) { [weak self] buffer, _ in
            // 安全檢查
            // Safety checks
            guard buffer.frameLength > 0,
                  let floatChannelData = buffer.floatChannelData,
                  buffer.format.channelCount > 0 else {
                return
            }

            let channelData = floatChannelData[0]
            let frameCount = Int(buffer.frameLength)

            guard frameCount > 0 && frameCount < 100000 else { return }

            // Calculate RMS level
            var sum: Float = 0
            let safeFrameCount = min(frameCount, 4096)
            
            for i in 0..<safeFrameCount {
                let sample = max(-1.0, min(1.0, channelData[i]))
                sum += sample * sample
            }
            let rms = sqrt(sum / Float(safeFrameCount))

            // Downsample for waveform display
            let bucketCount = 128
            var samples = [Float](repeating: 0, count: bucketCount)

            if safeFrameCount >= bucketCount {
                let samplesPerBucket = safeFrameCount / bucketCount
                guard samplesPerBucket > 0 else { return }

                for i in 0..<bucketCount {
                    let startIdx = i * samplesPerBucket
                    var maxSample: Float = 0
                    for j in 0..<samplesPerBucket {
                        let idx = startIdx + j
                        if idx < safeFrameCount {
                            maxSample = max(maxSample, min(abs(channelData[idx]), 1.0))
                        }
                    }
                    samples[i] = maxSample
                }
            }

            // 捕獲本地變數
            // Capture local variables
            let finalRms = rms
            let finalSamples = samples
            
            // Update UI on main thread
            Task { @MainActor in
                guard let self = self else { return }
                self.outputLevel = finalRms
                self.waveformSamples = finalSamples
            }
        }

        tapInstalled = true
        print("Visualization tap installed with buffer size: \(bufferSize)")
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
