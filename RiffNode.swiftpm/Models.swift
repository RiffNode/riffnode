import SwiftUI
import Observation

// MARK: - Domain Models
// Following Single Responsibility Principle: Each model represents one concept

// MARK: - Effect Type

/// Represents the type of audio effect available in the signal chain
enum EffectType: String, CaseIterable, Identifiable, Codable, Sendable {
    case distortion = "Distortion"
    case delay = "Delay"
    case reverb = "Reverb"
    case equalizer = "EQ"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .distortion: return "bolt.fill"
        case .delay: return "repeat"
        case .reverb: return "waveform.path"
        case .equalizer: return "slider.horizontal.3"
        }
    }

    var color: Color {
        switch self {
        case .distortion: return .orange
        case .delay: return .blue
        case .reverb: return .purple
        case .equalizer: return .green
        }
    }

    var defaultParameters: [String: Float] {
        switch self {
        case .distortion:
            return ["drive": 50, "mix": 50]
        case .delay:
            return ["time": 0.3, "feedback": 40, "mix": 30]
        case .reverb:
            return ["wetDryMix": 40]
        case .equalizer:
            return ["bass": 0, "mid": 0, "treble": 0]
        }
    }
}

// MARK: - Effect Node

/// Represents a single effect in the signal chain
/// Observable to allow UI to react to parameter changes
@Observable
final class EffectNode: Identifiable, @unchecked Sendable {
    let id: UUID
    let type: EffectType
    var isEnabled: Bool
    var parameters: [String: Float]

    init(id: UUID = UUID(), type: EffectType, isEnabled: Bool = true, parameters: [String: Float]? = nil) {
        self.id = id
        self.type = type
        self.isEnabled = isEnabled
        self.parameters = parameters ?? type.defaultParameters
    }

    /// Creates a copy of this effect node
    func copy() -> EffectNode {
        EffectNode(type: type, isEnabled: isEnabled, parameters: parameters)
    }
}

// MARK: - Effect Preset

/// Represents a preset configuration of effects
struct EffectPreset: Identifiable, Hashable {
    let id: UUID
    let name: String
    let icon: String
    let description: String
    let effects: [PresetEffect]
    let category: PresetCategory

    init(
        id: UUID = UUID(),
        name: String,
        icon: String,
        description: String,
        effects: [PresetEffect],
        category: PresetCategory
    ) {
        self.id = id
        self.name = name
        self.icon = icon
        self.description = description
        self.effects = effects
        self.category = category
    }

    enum PresetCategory: String, CaseIterable {
        case clean = "Clean"
        case crunch = "Crunch"
        case heavy = "Heavy"
        case ambient = "Ambient"

        var color: Color {
            switch self {
            case .clean: return .cyan
            case .crunch: return .orange
            case .heavy: return .red
            case .ambient: return .purple
            }
        }
    }

    struct PresetEffect: Hashable {
        let type: EffectType
        let isEnabled: Bool
        let parameters: [String: Float]

        func toEffectNode() -> EffectNode {
            EffectNode(type: type, isEnabled: isEnabled, parameters: parameters)
        }
    }
}

// MARK: - Audio Visualization Data

/// Data structure for audio visualization
struct AudioVisualizationData {
    var waveformSamples: [Float]
    var inputLevel: Float
    var outputLevel: Float

    static let empty = AudioVisualizationData(
        waveformSamples: Array(repeating: 0, count: 128),
        inputLevel: 0,
        outputLevel: 0
    )
}

// MARK: - Waveform Sample (for Charts)

struct WaveformSample: Identifiable {
    let id: Int
    let amplitude: Float
}

// MARK: - Audio Engine State

/// Represents the current state of the audio engine
struct AudioEngineState {
    var isRunning: Bool
    var hasPermission: Bool
    var errorMessage: String?

    static let initial = AudioEngineState(
        isRunning: false,
        hasPermission: false,
        errorMessage: nil
    )
}

// MARK: - Backing Track State

struct BackingTrackState {
    var isPlaying: Bool
    var isLoaded: Bool
    var trackName: String?
    var volume: Float

    static let initial = BackingTrackState(
        isPlaying: false,
        isLoaded: false,
        trackName: nil,
        volume: 0.5
    )
}
