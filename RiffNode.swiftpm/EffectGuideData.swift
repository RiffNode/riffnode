import SwiftUI

// MARK: - Effect Guide Data Layer
// Following Clean Architecture: Separating Data from Presentation
// Following Single Responsibility Principle: Each struct has one job

// MARK: - Protocols (Interface Segregation & Dependency Inversion)

/// Protocol for providing effect information
/// Following Interface Segregation: Small, focused protocol
protocol EffectInfoProviding {
    var name: String { get }
    var icon: String { get }
    var color: Color { get }
    var function: String { get }
    var sound: String { get }
    var howToUse: String { get }
    var signalChainPosition: String { get }
    var famousUsers: String { get }
}

/// Protocol for effect categories
/// Following Interface Segregation: Separate protocol for categories
protocol EffectCategoryProviding {
    var name: String { get }
    var icon: String { get }
    var color: Color { get }
    var description: String { get }
    var effects: [any EffectInfoProviding] { get }
}

/// Protocol for the effect guide service
/// Following Dependency Inversion: Depend on abstraction, not concretion
protocol EffectGuideServiceProtocol {
    var categories: [any EffectCategoryProviding] { get }
    func category(for id: String) -> (any EffectCategoryProviding)?
}

// MARK: - Domain Models

/// Effect information model
/// Following Single Responsibility: Only holds effect data
struct EffectInfoModel: EffectInfoProviding, Identifiable {
    let id = UUID()
    let name: String
    let icon: String
    let color: Color
    let function: String
    let sound: String
    let howToUse: String
    let signalChainPosition: String
    let famousUsers: String
}

/// Effect category model
/// Following Single Responsibility: Only holds category data
struct EffectCategoryModel: EffectCategoryProviding, Identifiable {
    let id: String
    let name: String
    let icon: String
    let color: Color
    let description: String
    let effects: [any EffectInfoProviding]
}

// MARK: - Effect Guide Service
// Following Single Responsibility: Only provides effect guide data
// Following Open/Closed: Open for extension (new categories), closed for modification

final class EffectGuideService: EffectGuideServiceProtocol {
    
    // MARK: - Singleton (for simplicity in SwiftUI)
    static let shared = EffectGuideService()
    
    // MARK: - Properties
    
    private(set) var categories: [any EffectCategoryProviding]
    
    // MARK: - Initialization
    
    private init() {
        self.categories = Self.buildCategories()
    }
    
    // MARK: - Public Methods
    
    func category(for id: String) -> (any EffectCategoryProviding)? {
        categories.first { ($0 as? EffectCategoryModel)?.id == id }
    }
    
    // MARK: - Private Factory Methods
    // Following Factory Pattern for creating complex objects
    
    private static func buildCategories() -> [EffectCategoryModel] {
        [
            buildDynamicsCategory(),
            buildFilterPitchCategory(),
            buildGainDirtCategory(),
            buildModulationCategory(),
            buildTimeAmbienceCategory(),
            buildUtilityCategory()
        ]
    }
    
    private static func buildDynamicsCategory() -> EffectCategoryModel {
        EffectCategoryModel(
            id: "dynamics",
            name: "Dynamics",
            icon: "waveform.path.ecg",
            color: .cyan,
            description: "Control the volume and consistency of your signal. Usually placed at the beginning of the chain.",
            effects: [
                EffectInfoModel(
                    name: "Compressor",
                    icon: "rectangle.compress.vertical",
                    color: .cyan,
                    function: "Squashes the dynamic range - makes loud sounds quieter and quiet sounds louder.",
                    sound: "Increases sustain and makes the tone sound 'tight' and percussive. Essential for clean, fast strumming found in J-Pop/Rock.",
                    howToUse: "Use for consistent volume, increased sustain, or to add 'punch' to your clean tone.",
                    signalChainPosition: "FIRST - Place at the very beginning of your chain.",
                    famousUsers: "David Gilmour, Tame Impala, Country players"
                ),
                EffectInfoModel(
                    name: "Noise Gate",
                    icon: "door.left.hand.closed",
                    color: .red,
                    function: "Cuts off the signal when volume drops below a threshold to eliminate hum or hiss.",
                    sound: "Complete silence when you aren't playing. Tight, controlled stops.",
                    howToUse: "Essential for high-gain metal tones to eliminate unwanted noise between riffs.",
                    signalChainPosition: "AFTER GAIN - Place after your distortion/overdrive pedals.",
                    famousUsers: "Metallica, Meshuggah, any metal guitarist"
                ),
                EffectInfoModel(
                    name: "Boost",
                    icon: "arrow.up.circle.fill",
                    color: .yellow,
                    function: "Increases volume without adding distortion (Clean Boost).",
                    sound: "Louder, but clean. Can push amp into natural breakup.",
                    howToUse: "Make solos stand out or push an amplifier into natural overdrive.",
                    signalChainPosition: "FLEXIBLE - Before dirt for more gain, after for volume boost.",
                    famousUsers: "Eric Johnson, Brian May"
                ),
                EffectInfoModel(
                    name: "Volume Pedal",
                    icon: "speaker.wave.3.fill",
                    color: .gray,
                    function: "Controls master volume with your foot.",
                    sound: "No tonal change - just volume control.",
                    howToUse: "Great for 'swells' (fading in notes like a violin) or muting.",
                    signalChainPosition: "FLEXIBLE - Early for swells, late for master volume.",
                    famousUsers: "Ambient guitarists, pedal steel players"
                )
            ]
        )
    }
    
    private static func buildFilterPitchCategory() -> EffectCategoryModel {
        EffectCategoryModel(
            id: "filter_pitch",
            name: "Filter & Pitch",
            icon: "waveform",
            color: .purple,
            description: "Alter the frequencies (EQ) or musical pitch of your notes.",
            effects: [
                EffectInfoModel(
                    name: "Wah-Wah",
                    icon: "mouth.fill",
                    color: .purple,
                    function: "A sweeping bandpass filter controlled by a foot treadle.",
                    sound: "Mimics the human voice saying 'Wah.' Expressive and vocal-like.",
                    howToUse: "Funk rhythms, expressive solos, or as a cocked (fixed) filter for unique tones.",
                    signalChainPosition: "EARLY - Before or after dirt, experiment to taste.",
                    famousUsers: "Jimi Hendrix, John Frusciante, Kirk Hammett"
                ),
                EffectInfoModel(
                    name: "Equalizer (EQ)",
                    icon: "slider.horizontal.3",
                    color: .green,
                    function: "Boosts or cuts specific frequency bands (Bass, Mids, Treble).",
                    sound: "Shape your tone - warmer, brighter, or scoop the mids.",
                    howToUse: "Fix 'muddy' sounds, boost presence, or create mid-scooped metal tones.",
                    signalChainPosition: "FLEXIBLE - Early for tone shaping, late for final adjustments.",
                    famousUsers: "Every professional guitarist"
                ),
                EffectInfoModel(
                    name: "Octave / Pitch Shifter",
                    icon: "music.note",
                    color: .blue,
                    function: "Adds a synthesized note an octave above or below what you play.",
                    sound: "Makes guitar sound like a bass (octave down) or synthesizer.",
                    howToUse: "Bass lines on guitar, thick synth-like tones, or harmonized leads.",
                    signalChainPosition: "EARLY - Before dirt for best tracking.",
                    famousUsers: "Jack White, Royal Blood, Tom Morello"
                ),
                EffectInfoModel(
                    name: "Whammy",
                    icon: "arrow.up.and.down",
                    color: .red,
                    function: "Pitch shifter controlled by treadle for dramatic pitch bends.",
                    sound: "Dive-bombs, harmonized pitch shifts, crazy sound effects.",
                    howToUse: "Extreme pitch bending without a tremolo bar.",
                    signalChainPosition: "EARLY - Before other effects for clean tracking.",
                    famousUsers: "Tom Morello, Dimebag Darrell, Matt Bellamy"
                )
            ]
        )
    }
    
    private static func buildGainDirtCategory() -> EffectCategoryModel {
        EffectCategoryModel(
            id: "gain_dirt",
            name: "Gain / Dirt",
            icon: "bolt.fill",
            color: .orange,
            description: "Simulate the sound of an amplifier being pushed to its limit. The core of rock and metal tones.",
            effects: [
                EffectInfoModel(
                    name: "Overdrive",
                    icon: "car.fill",
                    color: .green,
                    function: "Soft clipping that simulates a tube amp turned up loud.",
                    sound: "Warm, natural, and dynamic. Responds to your playing dynamics.",
                    howToUse: "Main rhythm tone for rock, blues. Stacks well with other pedals.",
                    signalChainPosition: "EARLY - After dynamics, before modulation and time effects.",
                    famousUsers: "Stevie Ray Vaughan, John Mayer, Mrs. GREEN APPLE"
                ),
                EffectInfoModel(
                    name: "Distortion",
                    icon: "bolt.fill",
                    color: .orange,
                    function: "Hard clipping for aggressive, compressed, saturated tone.",
                    sound: "More aggressive than overdrive. Consistent gain regardless of dynamics.",
                    howToUse: "Hard rock rhythms, searing leads, heavy riffs.",
                    signalChainPosition: "EARLY - After dynamics, before modulation and time effects.",
                    famousUsers: "Metallica, AC/DC, Van Halen"
                ),
                EffectInfoModel(
                    name: "Fuzz",
                    icon: "cloud.fill",
                    color: .purple,
                    function: "Square wave clipping for woolly, buzzing, thick tone.",
                    sound: "Sounds like a broken speaker (in a good way). Thick and sustaining.",
                    howToUse: "Psychedelic rock, garage rock, or thick wall-of-sound solos.",
                    signalChainPosition: "VERY EARLY - Often sounds best first in chain, even before tuner.",
                    famousUsers: "Jimi Hendrix, Jack White, The Black Keys"
                )
            ]
        )
    }
    
    private static func buildModulationCategory() -> EffectCategoryModel {
        EffectCategoryModel(
            id: "modulation",
            name: "Modulation",
            icon: "wind",
            color: .green,
            description: "Add movement, width, or a swirling quality to the sound.",
            effects: [
                EffectInfoModel(
                    name: "Chorus",
                    icon: "person.3.fill",
                    color: .blue,
                    function: "Simulates multiple instruments playing slightly out of tune.",
                    sound: "Lush, watery, and shimmering. Adds width and depth.",
                    howToUse: "Clean tones, 80s sounds, adding shimmer to cleans.",
                    signalChainPosition: "AFTER DIRT - In the modulation section of your chain.",
                    famousUsers: "Nirvana (Come As You Are), The Police, 80s everything"
                ),
                EffectInfoModel(
                    name: "Phaser",
                    icon: "circle.hexagongrid.fill",
                    color: .green,
                    function: "Creates a sweeping, whooshing sound by phase cancellation.",
                    sound: "Like a jet plane passing by, but smoother and more musical.",
                    howToUse: "Funky rhythms, psychedelic leads, adding movement.",
                    signalChainPosition: "AFTER DIRT - In the modulation section.",
                    famousUsers: "Van Halen, Pink Floyd, Tame Impala"
                ),
                EffectInfoModel(
                    name: "Flanger",
                    icon: "airplane",
                    color: .cyan,
                    function: "Similar to phaser but more metallic and intense.",
                    sound: "The 'jet plane' effect - dramatic swooshing.",
                    howToUse: "Special effects, psychedelic moments, dramatic transitions.",
                    signalChainPosition: "AFTER DIRT - In the modulation section.",
                    famousUsers: "Eddie Van Halen, Heart (Barracuda)"
                ),
                EffectInfoModel(
                    name: "Tremolo",
                    icon: "wave.3.right",
                    color: .red,
                    function: "Rhythmic fluctuation in VOLUME (loud-soft-loud-soft).",
                    sound: "Pulsating, hypnotic volume swells.",
                    howToUse: "Surf rock, ambient textures, rhythmic patterns.",
                    signalChainPosition: "LATE - After modulation, before or after delay/reverb.",
                    famousUsers: "Duane Eddy, Green Day (Boulevard of Broken Dreams)"
                ),
                EffectInfoModel(
                    name: "Vibrato",
                    icon: "waveform.path.ecg",
                    color: .purple,
                    function: "Rhythmic fluctuation in PITCH (sharp-flat-sharp-flat).",
                    sound: "Wobbly, seasick pitch modulation.",
                    howToUse: "Adding expression, lo-fi textures, unique character.",
                    signalChainPosition: "LATE - Similar to tremolo positioning.",
                    famousUsers: "Robin Guthrie, My Bloody Valentine"
                ),
                EffectInfoModel(
                    name: "Uni-Vibe",
                    icon: "sun.max.fill",
                    color: .orange,
                    function: "Unique mix of chorus and phaser.",
                    sound: "Throbbing, psychedelic pulse. Warm and organic.",
                    howToUse: "Classic psychedelic tones, expressive leads.",
                    signalChainPosition: "AFTER DIRT - Before time effects.",
                    famousUsers: "Jimi Hendrix, Robin Trower, David Gilmour"
                )
            ]
        )
    }
    
    private static func buildTimeAmbienceCategory() -> EffectCategoryModel {
        EffectCategoryModel(
            id: "time_ambience",
            name: "Time & Ambience",
            icon: "clock.arrow.2.circlepath",
            color: .blue,
            description: "Simulate physical space and echoes. Almost always placed at the end of the chain.",
            effects: [
                EffectInfoModel(
                    name: "Delay",
                    icon: "repeat",
                    color: .blue,
                    function: "Repeats the note you played (Echo).",
                    sound: "Digital: crisp, exact repeats. Analog/Tape: warm, degrading repeats.",
                    howToUse: "Adding depth, rhythmic patterns, ambient textures.",
                    signalChainPosition: "LATE - After dirt and modulation, before or after reverb.",
                    famousUsers: "The Edge (U2), David Gilmour, Radiohead"
                ),
                EffectInfoModel(
                    name: "Reverb",
                    icon: "waveform.path",
                    color: .purple,
                    function: "Simulates the natural decay of sound in a space.",
                    sound: "Spring: classic surf. Hall: concert space. Plate: studio smooth. Shimmer: ethereal.",
                    howToUse: "Adding space, ambience, depth to any tone.",
                    signalChainPosition: "LAST - Final effect in the chain for natural ambience.",
                    famousUsers: "Dick Dale (surf), My Bloody Valentine, ambient artists"
                )
            ]
        )
    }
    
    private static func buildUtilityCategory() -> EffectCategoryModel {
        EffectCategoryModel(
            id: "utility",
            name: "Utility",
            icon: "wrench.and.screwdriver",
            color: .gray,
            description: "Essential tools that don't change the sound but are vital for function.",
            effects: [
                EffectInfoModel(
                    name: "Tuner",
                    icon: "tuningfork",
                    color: .white,
                    function: "Keeps your guitar in pitch.",
                    sound: "No sound change - mutes signal while tuning.",
                    howToUse: "Essential for staying in tune during performances.",
                    signalChainPosition: "FIRST - At the very start of your chain.",
                    famousUsers: "Everyone!"
                ),
                EffectInfoModel(
                    name: "Looper",
                    icon: "repeat.circle",
                    color: .green,
                    function: "Records a phrase and plays it back endlessly.",
                    sound: "Layers of yourself playing together.",
                    howToUse: "Practice, jamming, live solo performances.",
                    signalChainPosition: "LAST - After everything else to capture your full tone.",
                    famousUsers: "Ed Sheeran, KT Tunstall, Tash Sultana"
                ),
                EffectInfoModel(
                    name: "Buffer",
                    icon: "bolt.horizontal.fill",
                    color: .yellow,
                    function: "Preserves signal strength and high frequencies.",
                    sound: "Restores clarity lost through long cables and many pedals.",
                    howToUse: "When using more than 5-6 pedals or long cable runs.",
                    signalChainPosition: "FIRST and/or LAST - At chain start and end.",
                    famousUsers: "Any guitarist with a large pedalboard"
                )
            ]
        )
    }
}
