# RiffNode

<p align="center">
  <img src="https://img.shields.io/badge/Swift-6.0-orange.svg" alt="Swift 6.0">
  <img src="https://img.shields.io/badge/SwiftUI-Liquid%20Glass-blue.svg" alt="SwiftUI">
  <img src="https://img.shields.io/badge/Platform-iOS%2026%20%7C%20macOS%2026-lightgrey.svg" alt="Platform">
  <img src="https://img.shields.io/badge/License-MIT-green.svg" alt="License">
</p>

<p align="center">
  <b>Visual Guitar Effects Playground</b><br>
  A real-time guitar effects processor featuring Apple's Liquid Glass design
</p>

---

## Features

### Real-Time Effects Processing
- **11 Effect Types** organized by category:
  - Dynamics: Compressor
  - Filter & Pitch: EQ
  - Gain/Dirt: Overdrive, Distortion, Fuzz
  - Modulation: Chorus, Phaser, Flanger, Tremolo
  - Time & Ambience: Delay, Reverb

### Liquid Glass Design
- Modern iOS 26 / macOS 26 Liquid Glass aesthetic
- Fluid animations and morphing transitions
- Interactive glass effects throughout the UI
- Clean, minimal interface without clutter

### Educational Content
- Learn what each effect does
- Signal chain positioning guidance
- Famous usage examples
- Genre recommendations

### Visual Effects Chain
- Drag-and-drop pedal interface
- Real-time bypass toggle
- Intuitive rotary knobs
- Signal flow visualization

### Professional Parametric EQ
- 8-band parametric equalizer
- Draggable frequency points
- Real-time curve visualization
- Filter types: HP, LS, Peak, HS, LP

### Audio Visualization
- Waveform display
- Bar spectrum analyzer
- Radial visualization
- Input/output level metering

### Backing Track Support
- Load audio files (MP3, WAV, AIFF)
- Transport controls
- Volume control
- For users without audio interface

### Preset System
- 16 built-in presets
- Categories: Clean, Crunch, Heavy, Ambient
- Quick switching

---

## Architecture

RiffNode follows **Clean Architecture** principles with **SOLID** design patterns:

```
+----------------------------------------------------------+
|                      Views (SwiftUI)                      |
|  ContentView, EffectsChainView, ParametricEQView, etc.   |
+----------------------------------------------------------+
|                      ViewModels                           |
|     SetupViewModel, EffectsChainViewModel, etc.          |
+----------------------------------------------------------+
|                      Protocols                            |
|  AudioManaging, EffectsChainManaging, PresetProviding    |
+----------------------------------------------------------+
|                      Services                             |
|      AudioEngineManager, PresetService, GuideService     |
+----------------------------------------------------------+
|                      Models                               |
|          EffectNode, EffectPreset, EffectType            |
+----------------------------------------------------------+
```

### SOLID Principles

- **Single Responsibility** - Each class/struct has one job
- **Open/Closed** - Open for extension, closed for modification
- **Liskov Substitution** - Derived types are substitutable
- **Interface Segregation** - Small, focused protocols
- **Dependency Inversion** - Depend on abstractions

---

## Technical Stack

| Component | Technology |
|-----------|------------|
| Language | Swift 6 |
| UI Framework | SwiftUI with Liquid Glass |
| Audio Engine | AVAudioEngine |
| Audio Effects | AVAudioUnit Effects |
| State Management | Observation Framework |
| Architecture | Clean Architecture + MVVM |

---

## Requirements

- **iOS 26.0+** / **macOS 26.0+**
- **Xcode 16.0+**
- **Swift 6.0+**
- Audio input device (microphone or audio interface)

---

## Getting Started

### Installation

1. Clone the repository:
```bash
git clone https://github.com/RiffNode/riffnode.git
cd riffnode
```

2. Open the project in Xcode:
```bash
open RiffNode.swiftpm
```

3. Build and run on your device or simulator

### Usage

1. **Grant Microphone Permission** - The app needs access to your audio input
2. **Start the Audio Engine** - Click "Start Engine" to begin processing
3. **Connect Your Guitar** - Use an audio interface to connect your instrument
4. **Add Effects** - Use "Add Pedal" to add effects to your chain
5. **Toggle Effects** - Double-click pedals to enable/disable
6. **Adjust Parameters** - Use the knobs to fine-tune your sound
7. **Learn** - Visit the "Learn" tab for educational content
8. **Try Presets** - Browse the preset library for inspiration

---

## Project Structure

```
RiffNode.swiftpm/
├── MyApp.swift              # App entry point
├── ContentView.swift        # Main view with Liquid Glass design
├── AudioEngine.swift        # Core audio processing
├── EffectsChainView.swift   # Effects pedal board UI
├── EffectGuideView.swift    # Educational effect guide
├── EffectGuideData.swift    # Effect guide data service
├── ParametricEQView.swift   # Parametric equalizer UI
├── BackingTrackView.swift   # Audio player interface
├── WaveformView.swift       # Audio visualization
├── ViewModels.swift         # Presentation logic
├── Models.swift             # Data models
├── Protocols.swift          # Interface definitions
├── PresetService.swift      # Preset management
└── Package.swift            # Swift Package configuration
```

---

## Swift Student Challenge 2026

This project was built for the **Apple Swift Student Challenge 2026**, showcasing:

- Modern Swift 6 features
- iOS 26 Liquid Glass design language
- Real-time audio processing
- Clean code architecture
- Educational content about guitar effects

---

## Changelog

### v1.5.0 (2026-01-28)
- **External Audio Interface Support** - Full Scarlett Solo USB compatibility
- **Multi-channel Audio Visualization** - Properly reads from all input channels
- **Vibrant Animated Background** - Dynamic mesh gradient with pink/lavender/blue/teal
- **Audio Route Change Detection** - Automatically reinstalls visualization when switching devices
- **UI Polish** - Removed harsh colored borders, cleaner glass effects
- **Tour Button** - Now uses transparent glass styling
- **Bug Fixes** - Fixed Mac Catalyst popover orientation crash

### v1.4.0 (2026-01-20)
- Complete UI redesign with Apple's Liquid Glass design
- Removed unnecessary icons and emojis for cleaner interface
- Updated to iOS 26 / macOS 26 minimum requirements
- GlassEffectContainer for fluid morphing animations
- Interactive glass effects on all buttons and controls
- Minimal, professional aesthetic throughout

### v1.3.0 (2026-01-20)
- Added 11 effect pedal types
- Organized effects by category
- Added 16 built-in presets
- Educational content for each effect

### v1.2.0 (2026-01-20)
- Refactored to Clean Architecture and SOLID principles
- Separated Data Layer from Presentation Layer

### v1.1.0 (2026-01-20)
- Added Effect Pedal Guide
- Added Parametric EQ
- Backing track improvements

### v1.0.0 (2026-01-20)
- Initial release

---

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

---

## License

This project is licensed under the MIT License.

---

## Author

**Jesse**

---

<p align="center">
  Made with Swift for WWDC 2026
</p>
