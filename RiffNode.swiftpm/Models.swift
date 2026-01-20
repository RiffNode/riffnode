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
    
    // MARK: - Educational Content
    
    /// What this effect does
    var effectDescription: String {
        switch self {
        case .distortion:
            return "Distortion clips the audio signal to create a gritty, aggressive tone. It adds harmonics and sustain to your guitar sound, making it fuller and more powerful."
        case .delay:
            return "Delay repeats your signal after a set time, creating echoes. It adds depth and space to your sound, and can create rhythmic patterns when synced to tempo."
        case .reverb:
            return "Reverb simulates the natural reflections of sound in a space. It makes your guitar sound like it's playing in a room, hall, or cathedral."
        case .equalizer:
            return "EQ (Equalizer) adjusts the balance of frequencies in your signal. Use it to cut muddy frequencies or boost presence in your tone."
        }
    }
    
    /// How to use this effect
    var howToUse: String {
        switch self {
        case .distortion:
            return "Start with low gain and increase until you get the desired amount of crunch. Use the Mix knob to blend distorted and clean signals. Works great for rock, metal, and blues."
        case .delay:
            return "Set the Time to match your song's tempo. Use Feedback to control how many repeats you hear. Lower Mix values create subtle depth, higher values create obvious echoes."
        case .reverb:
            return "Use small amounts (20-40%) for natural room sound. Increase for ambient, atmospheric tones. Too much reverb can make your sound muddy - less is often more!"
        case .equalizer:
            return "Cut frequencies that sound bad before boosting what sounds good. Reduce bass if your tone is muddy, boost mids for cutting through a mix, add treble for clarity."
        }
    }
    
    /// Where this effect should go in the signal chain
    var signalChainPosition: String {
        switch self {
        case .distortion:
            return "EARLY in the chain (1st-2nd position). Distortion should come before time-based effects like delay and reverb for cleaner repeats."
        case .delay:
            return "LATE in the chain (after distortion, before or after reverb). This ensures your echoes are clean and don't get distorted."
        case .reverb:
            return "LAST in the chain. Reverb should be the final effect to create natural-sounding ambience without artifacts."
        case .equalizer:
            return "FLEXIBLE - can go early (tone shaping before effects) or late (final tone adjustment). Try both positions!"
        }
    }
    
    /// Recommended signal chain order (1 = first, higher = later)
    var recommendedOrder: Int {
        switch self {
        case .equalizer: return 1
        case .distortion: return 2
        case .delay: return 3
        case .reverb: return 4
        }
    }
    
    /// Music genres that commonly use this effect
    var commonGenres: [String] {
        switch self {
        case .distortion:
            return ["Rock", "Metal", "Blues", "Punk", "Grunge"]
        case .delay:
            return ["Ambient", "Post-Rock", "Country", "Reggae", "U2-style Rock"]
        case .reverb:
            return ["Ambient", "Shoegaze", "Surf Rock", "Ballads", "Jazz"]
        case .equalizer:
            return ["All genres - essential for tone shaping"]
        }
    }
    
    /// Famous songs/artists known for this effect
    var famousExamples: String {
        switch self {
        case .distortion:
            return "Nirvana 'Smells Like Teen Spirit', AC/DC, Metallica, Jimi Hendrix"
        case .delay:
            return "U2 'Where The Streets Have No Name', Pink Floyd, The Edge"
        case .reverb:
            return "Surf guitar (Dick Dale), Shoegaze (My Bloody Valentine), ambient music"
        case .equalizer:
            return "Used by every professional guitarist to shape their signature tone"
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
