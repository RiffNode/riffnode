import SwiftUI

// MARK: - Effect Guide View
// Comprehensive educational guide for guitar effects pedals

struct EffectGuideView: View {
    @State private var selectedCategory: EffectCategory = .dynamics
    @State private var selectedEffect: EffectInfo? = nil
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            GuideHeaderView()
            
            // Category selector
            CategorySelectorView(selectedCategory: $selectedCategory)
            
            // Effects list
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(selectedCategory.effects) { effect in
                        EffectCardView(
                            effect: effect,
                            isExpanded: selectedEffect?.id == effect.id
                        ) {
                            withAnimation(.spring(duration: 0.3)) {
                                selectedEffect = selectedEffect?.id == effect.id ? nil : effect
                            }
                        }
                    }
                }
                .padding()
            }
        }
        .background(Color(red: 0.05, green: 0.05, blue: 0.1))
    }
}

// MARK: - Effect Category

enum EffectCategory: String, CaseIterable, Identifiable {
    case dynamics = "Dynamics"
    case filterPitch = "Filter & Pitch"
    case gainDirt = "Gain / Dirt"
    case modulation = "Modulation"
    case timeAmbience = "Time & Ambience"
    case utility = "Utility"
    
    var id: String { rawValue }
    
    var icon: String {
        switch self {
        case .dynamics: return "waveform.path.ecg"
        case .filterPitch: return "waveform"
        case .gainDirt: return "bolt.fill"
        case .modulation: return "wind"
        case .timeAmbience: return "clock.arrow.2.circlepath"
        case .utility: return "wrench.and.screwdriver"
        }
    }
    
    var color: Color {
        switch self {
        case .dynamics: return .cyan
        case .filterPitch: return .purple
        case .gainDirt: return .orange
        case .modulation: return .green
        case .timeAmbience: return .blue
        case .utility: return .gray
        }
    }
    
    var description: String {
        switch self {
        case .dynamics:
            return "Control the volume and consistency of your signal. Usually placed at the beginning of the chain."
        case .filterPitch:
            return "Alter the frequencies (EQ) or musical pitch of your notes."
        case .gainDirt:
            return "Simulate the sound of an amplifier being pushed to its limit. The core of rock and metal tones."
        case .modulation:
            return "Add movement, width, or a swirling quality to the sound."
        case .timeAmbience:
            return "Simulate physical space and echoes. Almost always placed at the end of the chain."
        case .utility:
            return "Essential tools that don't change the sound but are vital for function."
        }
    }
    
    var effects: [EffectInfo] {
        switch self {
        case .dynamics:
            return [
                EffectInfo(
                    name: "Compressor",
                    icon: "rectangle.compress.vertical",
                    color: .cyan,
                    function: "Squashes the dynamic range - makes loud sounds quieter and quiet sounds louder.",
                    sound: "Increases sustain and makes the tone sound 'tight' and percussive. Essential for clean, fast strumming found in J-Pop/Rock.",
                    use: "Use for consistent volume, increased sustain, or to add 'punch' to your clean tone.",
                    signalChainPosition: "FIRST - Place at the very beginning of your chain.",
                    famousUsers: "David Gilmour, Tame Impala, Country players"
                ),
                EffectInfo(
                    name: "Noise Gate",
                    icon: "door.left.hand.closed",
                    color: .red,
                    function: "Cuts off the signal when volume drops below a threshold to eliminate hum or hiss.",
                    sound: "Complete silence when you aren't playing. Tight, controlled stops.",
                    use: "Essential for high-gain metal tones to eliminate unwanted noise between riffs.",
                    signalChainPosition: "AFTER GAIN - Place after your distortion/overdrive pedals.",
                    famousUsers: "Metallica, Meshuggah, any metal guitarist"
                ),
                EffectInfo(
                    name: "Boost",
                    icon: "arrow.up.circle.fill",
                    color: .yellow,
                    function: "Increases volume without adding distortion (Clean Boost).",
                    sound: "Louder, but clean. Can push amp into natural breakup.",
                    use: "Make solos stand out or push an amplifier into natural overdrive.",
                    signalChainPosition: "FLEXIBLE - Before dirt for more gain, after for volume boost.",
                    famousUsers: "Eric Johnson, Brian May"
                ),
                EffectInfo(
                    name: "Volume Pedal",
                    icon: "speaker.wave.3.fill",
                    color: .gray,
                    function: "Controls master volume with your foot.",
                    sound: "No tonal change - just volume control.",
                    use: "Great for 'swells' (fading in notes like a violin) or muting.",
                    signalChainPosition: "FLEXIBLE - Early for swells, late for master volume.",
                    famousUsers: "Ambient guitarists, pedal steel players"
                )
            ]
            
        case .filterPitch:
            return [
                EffectInfo(
                    name: "Wah-Wah",
                    icon: "mouth.fill",
                    color: .purple,
                    function: "A sweeping bandpass filter controlled by a foot treadle.",
                    sound: "Mimics the human voice saying 'Wah.' Expressive and vocal-like.",
                    use: "Funk rhythms, expressive solos, or as a cocked (fixed) filter for unique tones.",
                    signalChainPosition: "EARLY - Before or after dirt, experiment to taste.",
                    famousUsers: "Jimi Hendrix, John Frusciante, Kirk Hammett"
                ),
                EffectInfo(
                    name: "Equalizer (EQ)",
                    icon: "slider.horizontal.3",
                    color: .green,
                    function: "Boosts or cuts specific frequency bands (Bass, Mids, Treble).",
                    sound: "Shape your tone - warmer, brighter, or scoop the mids.",
                    use: "Fix 'muddy' sounds, boost presence, or create mid-scooped metal tones.",
                    signalChainPosition: "FLEXIBLE - Early for tone shaping, late for final adjustments.",
                    famousUsers: "Every professional guitarist"
                ),
                EffectInfo(
                    name: "Octave / Pitch Shifter",
                    icon: "music.note",
                    color: .blue,
                    function: "Adds a synthesized note an octave above or below what you play.",
                    sound: "Makes guitar sound like a bass (octave down) or synthesizer.",
                    use: "Bass lines on guitar, thick synth-like tones, or harmonized leads.",
                    signalChainPosition: "EARLY - Before dirt for best tracking.",
                    famousUsers: "Jack White, Royal Blood, Tom Morello"
                ),
                EffectInfo(
                    name: "Whammy",
                    icon: "arrow.up.and.down",
                    color: .red,
                    function: "Pitch shifter controlled by treadle for dramatic pitch bends.",
                    sound: "Dive-bombs, harmonized pitch shifts, crazy sound effects.",
                    use: "Extreme pitch bending without a tremolo bar.",
                    signalChainPosition: "EARLY - Before other effects for clean tracking.",
                    famousUsers: "Tom Morello, Dimebag Darrell, Matt Bellamy"
                )
            ]
            
        case .gainDirt:
            return [
                EffectInfo(
                    name: "Overdrive",
                    icon: "car.fill",
                    color: .green,
                    function: "Soft clipping that simulates a tube amp turned up loud.",
                    sound: "Warm, natural, and dynamic. Responds to your playing dynamics.",
                    use: "Main rhythm tone for rock, blues. Stacks well with other pedals.",
                    signalChainPosition: "EARLY - After dynamics, before modulation and time effects.",
                    famousUsers: "Stevie Ray Vaughan, John Mayer, Mrs. GREEN APPLE"
                ),
                EffectInfo(
                    name: "Distortion",
                    icon: "bolt.fill",
                    color: .orange,
                    function: "Hard clipping for aggressive, compressed, saturated tone.",
                    sound: "More aggressive than overdrive. Consistent gain regardless of dynamics.",
                    use: "Hard rock rhythms, searing leads, heavy riffs.",
                    signalChainPosition: "EARLY - After dynamics, before modulation and time effects.",
                    famousUsers: "Metallica, AC/DC, Van Halen"
                ),
                EffectInfo(
                    name: "Fuzz",
                    icon: "cloud.fill",
                    color: .purple,
                    function: "Square wave clipping for woolly, buzzing, thick tone.",
                    sound: "Sounds like a broken speaker (in a good way). Thick and sustaining.",
                    use: "Psychedelic rock, garage rock, or thick wall-of-sound solos.",
                    signalChainPosition: "VERY EARLY - Often sounds best first in chain, even before tuner.",
                    famousUsers: "Jimi Hendrix, Jack White, The Black Keys"
                )
            ]
            
        case .modulation:
            return [
                EffectInfo(
                    name: "Chorus",
                    icon: "person.3.fill",
                    color: .blue,
                    function: "Simulates multiple instruments playing slightly out of tune.",
                    sound: "Lush, watery, and shimmering. Adds width and depth.",
                    use: "Clean tones, 80s sounds, adding shimmer to cleans.",
                    signalChainPosition: "AFTER DIRT - In the modulation section of your chain.",
                    famousUsers: "Nirvana (Come As You Are), The Police, 80s everything"
                ),
                EffectInfo(
                    name: "Phaser",
                    icon: "circle.hexagongrid.fill",
                    color: .green,
                    function: "Creates a sweeping, whooshing sound by phase cancellation.",
                    sound: "Like a jet plane passing by, but smoother and more musical.",
                    use: "Funky rhythms, psychedelic leads, adding movement.",
                    signalChainPosition: "AFTER DIRT - In the modulation section.",
                    famousUsers: "Van Halen, Pink Floyd, Tame Impala"
                ),
                EffectInfo(
                    name: "Flanger",
                    icon: "airplane",
                    color: .cyan,
                    function: "Similar to phaser but more metallic and intense.",
                    sound: "The 'jet plane' effect - dramatic swooshing.",
                    use: "Special effects, psychedelic moments, dramatic transitions.",
                    signalChainPosition: "AFTER DIRT - In the modulation section.",
                    famousUsers: "Eddie Van Halen, Heart (Barracuda)"
                ),
                EffectInfo(
                    name: "Tremolo",
                    icon: "wave.3.right",
                    color: .red,
                    function: "Rhythmic fluctuation in VOLUME (loud-soft-loud-soft).",
                    sound: "Pulsating, hypnotic volume swells.",
                    use: "Surf rock, ambient textures, rhythmic patterns.",
                    signalChainPosition: "LATE - After modulation, before or after delay/reverb.",
                    famousUsers: "Duane Eddy, Green Day (Boulevard of Broken Dreams)"
                ),
                EffectInfo(
                    name: "Vibrato",
                    icon: "waveform.path.ecg",
                    color: .purple,
                    function: "Rhythmic fluctuation in PITCH (sharp-flat-sharp-flat).",
                    sound: "Wobbly, seasick pitch modulation.",
                    use: "Adding expression, lo-fi textures, unique character.",
                    signalChainPosition: "LATE - Similar to tremolo positioning.",
                    famousUsers: "Robin Guthrie, My Bloody Valentine"
                ),
                EffectInfo(
                    name: "Uni-Vibe",
                    icon: "sun.max.fill",
                    color: .orange,
                    function: "Unique mix of chorus and phaser.",
                    sound: "Throbbing, psychedelic pulse. Warm and organic.",
                    use: "Classic psychedelic tones, expressive leads.",
                    signalChainPosition: "AFTER DIRT - Before time effects.",
                    famousUsers: "Jimi Hendrix, Robin Trower, David Gilmour"
                )
            ]
            
        case .timeAmbience:
            return [
                EffectInfo(
                    name: "Delay",
                    icon: "repeat",
                    color: .blue,
                    function: "Repeats the note you played (Echo).",
                    sound: "Digital: crisp, exact repeats. Analog/Tape: warm, degrading repeats.",
                    use: "Adding depth, rhythmic patterns, ambient textures.",
                    signalChainPosition: "LATE - After dirt and modulation, before or after reverb.",
                    famousUsers: "The Edge (U2), David Gilmour, Radiohead"
                ),
                EffectInfo(
                    name: "Reverb",
                    icon: "waveform.path",
                    color: .purple,
                    function: "Simulates the natural decay of sound in a space.",
                    sound: "Spring: classic surf. Hall: concert space. Plate: studio smooth. Shimmer: ethereal.",
                    use: "Adding space, ambience, depth to any tone.",
                    signalChainPosition: "LAST - Final effect in the chain for natural ambience.",
                    famousUsers: "Dick Dale (surf), My Bloody Valentine, ambient artists"
                )
            ]
            
        case .utility:
            return [
                EffectInfo(
                    name: "Tuner",
                    icon: "tuningfork",
                    color: .white,
                    function: "Keeps your guitar in pitch.",
                    sound: "No sound change - mutes signal while tuning.",
                    use: "Essential for staying in tune during performances.",
                    signalChainPosition: "FIRST - At the very start of your chain.",
                    famousUsers: "Everyone!"
                ),
                EffectInfo(
                    name: "Looper",
                    icon: "repeat.circle",
                    color: .green,
                    function: "Records a phrase and plays it back endlessly.",
                    sound: "Layers of yourself playing together.",
                    use: "Practice, jamming, live solo performances.",
                    signalChainPosition: "LAST - After everything else to capture your full tone.",
                    famousUsers: "Ed Sheeran, KT Tunstall, Tash Sultana"
                ),
                EffectInfo(
                    name: "Buffer",
                    icon: "bolt.horizontal.fill",
                    color: .yellow,
                    function: "Preserves signal strength and high frequencies.",
                    sound: "Restores clarity lost through long cables and many pedals.",
                    use: "When using more than 5-6 pedals or long cable runs.",
                    signalChainPosition: "FIRST and/or LAST - At chain start and end.",
                    famousUsers: "Any guitarist with a large pedalboard"
                )
            ]
        }
    }
}

// MARK: - Effect Info

struct EffectInfo: Identifiable {
    let id = UUID()
    let name: String
    let icon: String
    let color: Color
    let function: String
    let sound: String
    let use: String
    let signalChainPosition: String
    let famousUsers: String
}

// MARK: - Guide Header View

struct GuideHeaderView: View {
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: "book.fill")
                    .foregroundStyle(.yellow)
                Text("EFFECT PEDAL GUIDE")
                    .font(.system(size: 16, weight: .bold, design: .monospaced))
                Spacer()
            }
            
            Text("Learn about different types of guitar effects and how to use them")
                .font(.caption)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding()
        .background(Color.black.opacity(0.3))
    }
}

// MARK: - Category Selector View

struct CategorySelectorView: View {
    @Binding var selectedCategory: EffectCategory
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(EffectCategory.allCases) { category in
                    Button {
                        withAnimation(.spring(duration: 0.3)) {
                            selectedCategory = category
                        }
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: category.icon)
                                .font(.system(size: 12))
                            Text(category.rawValue)
                                .font(.system(size: 12, weight: .medium))
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(
                            Capsule()
                                .fill(selectedCategory == category ? category.color : Color.gray.opacity(0.3))
                        )
                        .foregroundStyle(selectedCategory == category ? .black : .white)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
        }
        .background(Color.black.opacity(0.2))
    }
}

// MARK: - Effect Card View

struct EffectCardView: View {
    let effect: EffectInfo
    let isExpanded: Bool
    let onTap: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            Button(action: onTap) {
                HStack(spacing: 12) {
                    // Icon
                    ZStack {
                        Circle()
                            .fill(effect.color.opacity(0.2))
                            .frame(width: 44, height: 44)
                        Image(systemName: effect.icon)
                            .font(.system(size: 18))
                            .foregroundStyle(effect.color)
                    }
                    
                    // Name
                    Text(effect.name)
                        .font(.headline)
                        .foregroundStyle(.white)
                    
                    Spacer()
                    
                    // Expand indicator
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .foregroundStyle(.secondary)
                        .font(.caption)
                }
                .padding()
            }
            .buttonStyle(.plain)
            
            // Expanded content
            if isExpanded {
                VStack(alignment: .leading, spacing: 16) {
                    Divider()
                        .background(effect.color.opacity(0.3))
                    
                    EffectDetailRow(
                        title: "Function",
                        content: effect.function,
                        icon: "gearshape.fill",
                        color: .cyan
                    )
                    
                    EffectDetailRow(
                        title: "Sound",
                        content: effect.sound,
                        icon: "speaker.wave.3.fill",
                        color: .green
                    )
                    
                    EffectDetailRow(
                        title: "How to Use",
                        content: effect.use,
                        icon: "hand.point.up.fill",
                        color: .yellow
                    )
                    
                    EffectDetailRow(
                        title: "Signal Chain Position",
                        content: effect.signalChainPosition,
                        icon: "arrow.right.circle.fill",
                        color: .orange
                    )
                    
                    EffectDetailRow(
                        title: "Famous Users",
                        content: effect.famousUsers,
                        icon: "star.fill",
                        color: .purple
                    )
                }
                .padding()
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .strokeBorder(isExpanded ? effect.color.opacity(0.5) : Color.white.opacity(0.1), lineWidth: 1)
                )
        )
        .animation(.spring(duration: 0.3), value: isExpanded)
    }
}

// MARK: - Effect Detail Row

struct EffectDetailRow: View {
    let title: String
    let content: String
    let icon: String
    let color: Color
    
    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: icon)
                .foregroundStyle(color)
                .frame(width: 20)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.caption.bold())
                    .foregroundStyle(color)
                
                Text(content)
                    .font(.callout)
                    .foregroundStyle(.white.opacity(0.9))
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

// MARK: - Preview

#Preview {
    EffectGuideView()
}
