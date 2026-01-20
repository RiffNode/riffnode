import Foundation

// MARK: - Preset Service
// Following Single Responsibility Principle: Only manages presets
// Following Open/Closed Principle: Can be extended with new preset sources

/// Service for managing effect presets
final class PresetService: PresetProviding {

    // MARK: - Properties

    private(set) var presets: [EffectPreset]

    // MARK: - Initialization

    init(presets: [EffectPreset]? = nil) {
        self.presets = presets ?? PresetService.builtInPresets
    }

    // MARK: - PresetProviding

    func preset(for id: UUID) -> EffectPreset? {
        presets.first { $0.id == id }
    }

    func presets(for category: EffectPreset.PresetCategory) -> [EffectPreset] {
        presets.filter { $0.category == category }
    }

    // MARK: - Preset Management

    func addPreset(_ preset: EffectPreset) {
        presets.append(preset)
    }

    func removePreset(id: UUID) {
        presets.removeAll { $0.id == id }
    }

    // MARK: - Built-in Presets

    static let builtInPresets: [EffectPreset] = [
        EffectPreset(
            name: "Clean & Clear",
            icon: "sparkles",
            description: "Crystal clear tone with subtle reverb",
            effects: [
                EffectPreset.PresetEffect(type: .reverb, isEnabled: true, parameters: ["wetDryMix": 20])
            ],
            category: .clean
        ),
        EffectPreset(
            name: "Warm Blues",
            icon: "sun.max.fill",
            description: "Warm overdrive with smooth delay",
            effects: [
                EffectPreset.PresetEffect(type: .distortion, isEnabled: true, parameters: ["drive": 30, "mix": 40]),
                EffectPreset.PresetEffect(type: .delay, isEnabled: true, parameters: ["time": 0.4, "feedback": 25, "mix": 20]),
                EffectPreset.PresetEffect(type: .reverb, isEnabled: true, parameters: ["wetDryMix": 25])
            ],
            category: .crunch
        ),
        EffectPreset(
            name: "Classic Rock",
            icon: "bolt.fill",
            description: "Punchy distortion for rock tones",
            effects: [
                EffectPreset.PresetEffect(type: .distortion, isEnabled: true, parameters: ["drive": 60, "mix": 60]),
                EffectPreset.PresetEffect(type: .reverb, isEnabled: true, parameters: ["wetDryMix": 30])
            ],
            category: .crunch
        ),
        EffectPreset(
            name: "Metal Zone",
            icon: "flame.fill",
            description: "High gain for heavy riffs",
            effects: [
                EffectPreset.PresetEffect(type: .distortion, isEnabled: true, parameters: ["drive": 85, "mix": 80]),
                EffectPreset.PresetEffect(type: .equalizer, isEnabled: true, parameters: ["bass": 3, "mid": -2, "treble": 4]),
                EffectPreset.PresetEffect(type: .reverb, isEnabled: true, parameters: ["wetDryMix": 15])
            ],
            category: .heavy
        ),
        EffectPreset(
            name: "Ambient Dreams",
            icon: "cloud.fill",
            description: "Spacious delays and lush reverb",
            effects: [
                EffectPreset.PresetEffect(type: .delay, isEnabled: true, parameters: ["time": 0.6, "feedback": 50, "mix": 40]),
                EffectPreset.PresetEffect(type: .reverb, isEnabled: true, parameters: ["wetDryMix": 70])
            ],
            category: .ambient
        ),
        EffectPreset(
            name: "Slapback Echo",
            icon: "waveform.path",
            description: "Vintage rockabilly slapback",
            effects: [
                EffectPreset.PresetEffect(type: .delay, isEnabled: true, parameters: ["time": 0.12, "feedback": 10, "mix": 35])
            ],
            category: .clean
        ),
        EffectPreset(
            name: "Shimmer",
            icon: "star.fill",
            description: "Ethereal ambient soundscape",
            effects: [
                EffectPreset.PresetEffect(type: .delay, isEnabled: true, parameters: ["time": 0.8, "feedback": 60, "mix": 35]),
                EffectPreset.PresetEffect(type: .reverb, isEnabled: true, parameters: ["wetDryMix": 80])
            ],
            category: .ambient
        ),
        EffectPreset(
            name: "Crunch Time",
            icon: "guitars.fill",
            description: "Edge of breakup tone",
            effects: [
                EffectPreset.PresetEffect(type: .distortion, isEnabled: true, parameters: ["drive": 40, "mix": 45]),
                EffectPreset.PresetEffect(type: .equalizer, isEnabled: true, parameters: ["bass": 1, "mid": 2, "treble": 1])
            ],
            category: .crunch
        )
    ]
}

// MARK: - Preset Factory
// Following Factory Pattern for creating presets from effect chains

extension PresetService {

    /// Creates a preset from the current effects chain
    static func createPreset(
        name: String,
        description: String,
        icon: String,
        category: EffectPreset.PresetCategory,
        from effectsChain: [EffectNode]
    ) -> EffectPreset {
        let presetEffects = effectsChain.map { node in
            EffectPreset.PresetEffect(
                type: node.type,
                isEnabled: node.isEnabled,
                parameters: node.parameters
            )
        }

        return EffectPreset(
            name: name,
            icon: icon,
            description: description,
            effects: presetEffects,
            category: category
        )
    }
}
