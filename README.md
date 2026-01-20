# RiffNode

<p align="center">
  <img src="https://img.shields.io/badge/Swift-6.0-orange.svg" alt="Swift 6.0">
  <img src="https://img.shields.io/badge/SwiftUI-5.0-blue.svg" alt="SwiftUI">
  <img src="https://img.shields.io/badge/Platform-iOS%20%7C%20macOS-lightgrey.svg" alt="Platform">
  <img src="https://img.shields.io/badge/License-MIT-green.svg" alt="License">
</p>

<p align="center">
  <b>Your Visual Guitar Effects Playground</b><br>
  A real-time guitar effects processor built with Swift and SwiftUI
</p>

---

## Features

### Real-Time Effects Processing
- **Distortion** - Add grit and crunch to your tone
- **Delay** - Create echo and ambient effects
- **Reverb** - Add space and depth to your sound
- **EQ** - Shape your tone with bass, mid, and treble controls

### Visual Effects Chain
- Drag-and-drop effect pedal interface
- Real-time bypass toggle for each effect
- Adjustable parameters with intuitive knobs

### Audio Visualization
- Real-time waveform display
- Input/output level metering
- Visual feedback for your playing

### Backing Track Support
- Load audio files (MP3, WAV, AIFF)
- Vintage tape deck-style interface
- Volume control and transport controls

### Preset System
- Built-in effect presets (Clean, Crunch, Heavy, Ambient)
- Quick preset switching
- Category-based organization

---

## Architecture

RiffNode follows **Clean Architecture** principles with **SOLID** design patterns:

```
+----------------------------------------------------------+
|                      Views (SwiftUI)                      |
|  ContentView, EffectsChainView, BackingTrackView, etc.   |
+----------------------------------------------------------+
|                      ViewModels                           |
|     SetupViewModel, EffectsChainViewModel, etc.          |
+----------------------------------------------------------+
|                      Protocols                            |
|  AudioManaging, EffectsChainManaging, PresetProviding    |
+----------------------------------------------------------+
|                      Services                             |
|         AudioEngineManager, PresetService                |
+----------------------------------------------------------+
|                      Models                               |
|          EffectNode, EffectPreset, EffectType            |
+----------------------------------------------------------+
```

### Key Design Patterns

- **Interface Segregation** - Protocols split by responsibility
- **Dependency Injection** - ViewModels receive dependencies
- **Observable Pattern** - Using Swift's `@Observable` macro
- **Composition over Inheritance** - Effect units container

---

## Technical Stack

| Component | Technology |
|-----------|------------|
| Language | Swift 6 |
| UI Framework | SwiftUI |
| Audio Engine | AVAudioEngine |
| Audio Effects | AVAudioUnitDistortion, AVAudioUnitDelay, AVAudioUnitReverb |
| State Management | Observation Framework |
| Architecture | Clean Architecture + MVVM |

---

## Requirements

- **iOS 17.0+** / **macOS 14.0+**
- **Xcode 15.0+**
- **Swift 6.0+**
- Audio input device (microphone or audio interface)

---

## Getting Started

### Installation

1. Clone the repository:
```bash
git clone https://github.com/YOUR_USERNAME/RiffNode.git
cd RiffNode
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
4. **Toggle Effects** - Click on effect pedals to enable/disable them
5. **Adjust Parameters** - Use the knobs to fine-tune your sound
6. **Try Presets** - Browse the preset library for inspiration

---

## Project Structure

```
RiffNode.swiftpm/
├── MyApp.swift              # App entry point
├── ContentView.swift        # Main view & setup wizard
├── AudioEngine.swift        # Core audio processing
├── EffectsChainView.swift   # Effects pedal board UI
├── BackingTrackView.swift   # Tape deck interface
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
- Real-time audio processing
- Beautiful SwiftUI interface
- Clean code architecture
- Accessibility considerations

---

## Changelog

### v1.0.0 (2026-01-20)
- Initial release
- Real-time effects processing (Distortion, Delay, Reverb)
- Visual effects chain with bypass control
- Backing track support with tape deck UI
- Preset system with categories
- Audio visualization

---

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

1. Fork the project
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

---

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

## Author

**Jesse**

---

## Acknowledgments

- Apple for AVAudioEngine and SwiftUI
- The Swift community for inspiration

---

<p align="center">
  Made with Swift
</p>
