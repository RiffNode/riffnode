import SwiftUI
import UniformTypeIdentifiers

// MARK: - Backing Track View (Tape Deck Style)

struct BackingTrackView: View {

    // MARK: - Dependencies

    @Bindable var engine: AudioEngineManager

    // MARK: - State

    @State private var isImporting = false
    @State private var loadedTrackName: String?
    @State private var isLoading = false
    @State private var reelRotation: Double = 0
    @State private var rotationTimer: Timer?

    // MARK: - Body

    var body: some View {
        VStack(spacing: 0) {
            BackingTrackHeader(onImport: { isImporting = true })

            TapeDeckView(
                isPlaying: engine.isBackingTrackPlaying,
                trackName: loadedTrackName,
                rotation: reelRotation
            )
            .padding(.horizontal)

            TransportControlsView(
                volume: Binding(
                    get: { engine.backingTrackVolume },
                    set: { engine.setBackingTrackVolume($0) }
                ),
                isPlaying: engine.isBackingTrackPlaying,
                hasTrack: loadedTrackName != nil,
                isLoading: isLoading,
                onPlay: {
                    engine.playBackingTrack()
                    startReelAnimation()
                },
                onStop: {
                    engine.stopBackingTrack()
                    stopReelAnimation()
                }
            )
            .padding()
        }
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .strokeBorder(Color.purple.opacity(0.3), lineWidth: 1)
                )
        )
        .fileImporter(
            isPresented: $isImporting,
            allowedContentTypes: [.audio, .mp3, .wav, .aiff],
            allowsMultipleSelection: false
        ) { result in
            handleFileImport(result)
        }
        .onChange(of: engine.isBackingTrackPlaying) { _, isPlaying in
            if isPlaying {
                startReelAnimation()
            } else {
                stopReelAnimation()
            }
        }
    }

    // MARK: - Private Methods

    private func startReelAnimation() {
        stopReelAnimation()
        rotationTimer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { _ in
            DispatchQueue.main.async {
                self.reelRotation += 3
            }
        }
    }

    private func stopReelAnimation() {
        rotationTimer?.invalidate()
        rotationTimer = nil
    }

    private func handleFileImport(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            guard let url = urls.first else {
                print("No file selected")
                return
            }

            isLoading = true
            let trackName = url.lastPathComponent
            loadedTrackName = trackName

            Task { @MainActor in
                do {
                    // Start accessing the security-scoped resource
                    let didStartAccessing = url.startAccessingSecurityScopedResource()

                    // Load the track
                    try await engine.loadBackingTrack(url: url)

                    // Stop accessing after load completes
                    if didStartAccessing {
                        url.stopAccessingSecurityScopedResource()
                    }

                    isLoading = false
                    print("Successfully loaded: \(trackName)")
                } catch {
                    isLoading = false
                    loadedTrackName = nil
                    print("Failed to load backing track: \(error.localizedDescription)")
                }
            }

        case .failure(let error):
            print("File import cancelled or failed: \(error.localizedDescription)")
        }
    }
}

// MARK: - Backing Track Header

struct BackingTrackHeader: View {
    let onImport: () -> Void

    var body: some View {
        HStack {
            HStack(spacing: 8) {
                Image(systemName: "opticaldisc.fill")
                    .foregroundStyle(.purple)
                Text("TAPE DECK")
                    .font(.system(size: 14, weight: .bold, design: .monospaced))
                    .foregroundStyle(.white)
            }

            Spacer()

            Button(action: onImport) {
                HStack(spacing: 4) {
                    Image(systemName: "plus")
                    Text("Load Track")
                }
                .font(.system(size: 12, weight: .semibold))
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(.purple.gradient)
                .foregroundStyle(.white)
                .clipShape(Capsule())
            }
            .buttonStyle(.plain)
        }
        .padding()
    }
}

// MARK: - Tape Deck Visualization

struct TapeDeckView: View {
    let isPlaying: Bool
    let trackName: String?
    let rotation: Double

    var body: some View {
        HStack(spacing: 20) {
            TapeReelView(rotation: rotation, isSupply: true)

            TapeWindowView(isPlaying: isPlaying, trackName: trackName)
                .frame(maxWidth: .infinity)

            TapeReelView(rotation: -rotation, isSupply: false)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.black.opacity(0.3))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .strokeBorder(Color.white.opacity(0.1), lineWidth: 1)
                )
        )
    }
}

// MARK: - Tape Window View

struct TapeWindowView: View {
    let isPlaying: Bool
    let trackName: String?

    var body: some View {
        VStack(spacing: 8) {
            // Track name display
            ZStack {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.black.opacity(0.6))
                    .frame(height: 30)

                if let name = trackName {
                    Text(name)
                        .font(.system(size: 11, weight: .medium, design: .monospaced))
                        .foregroundStyle(.green)
                        .lineLimit(1)
                        .padding(.horizontal, 8)
                } else {
                    Text("NO TAPE LOADED")
                        .font(.system(size: 10, weight: .medium, design: .monospaced))
                        .foregroundStyle(.gray)
                }
            }

            // Tape transport visualization
            HStack(spacing: 4) {
                ForEach(0..<8, id: \.self) { i in
                    Rectangle()
                        .fill(
                            isPlaying
                                ? Color.brown.opacity(0.6 + Double(i) * 0.05)
                                : Color.brown.opacity(0.3)
                        )
                        .frame(width: 8, height: 20)
                }
            }
            .padding(.vertical, 4)
            .padding(.horizontal, 8)
            .background(
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.black.opacity(0.4))
            )

            // Status indicator
            HStack(spacing: 8) {
                Circle()
                    .fill(isPlaying ? Color.red : Color.red.opacity(0.3))
                    .frame(width: 8, height: 8)
                    .shadow(color: isPlaying ? .red : .clear, radius: 4)

                Text(isPlaying ? "PLAYING" : "STOPPED")
                    .font(.system(size: 9, weight: .bold, design: .monospaced))
                    .foregroundStyle(isPlaying ? .green : .gray)
            }
        }
    }
}

// MARK: - Tape Reel View

struct TapeReelView: View {
    let rotation: Double
    let isSupply: Bool

    var body: some View {
        ZStack {
            // Reel base
            Circle()
                .fill(
                    RadialGradient(
                        colors: [Color.gray.opacity(0.6), Color.gray.opacity(0.3)],
                        center: .center,
                        startRadius: 0,
                        endRadius: 35
                    )
                )
                .frame(width: 70, height: 70)

            // Tape spool
            Circle()
                .fill(
                    LinearGradient(
                        colors: [Color.brown.opacity(0.8), Color.brown.opacity(0.4)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: isSupply ? 50 : 40, height: isSupply ? 50 : 40)

            // Reel hub
            Circle()
                .fill(Color.gray.opacity(0.8))
                .frame(width: 20, height: 20)

            // Spokes
            ForEach(0..<3, id: \.self) { i in
                Rectangle()
                    .fill(Color.gray.opacity(0.6))
                    .frame(width: 2, height: 30)
                    .rotationEffect(.degrees(Double(i) * 120 + rotation))
            }

            // Center hole
            Circle()
                .fill(Color.black)
                .frame(width: 8, height: 8)
        }
    }
}

// MARK: - Transport Controls View

struct TransportControlsView: View {
    @Binding var volume: Float
    let isPlaying: Bool
    let hasTrack: Bool
    let isLoading: Bool
    let onPlay: () -> Void
    let onStop: () -> Void

    var body: some View {
        HStack(spacing: 16) {
            // Rewind (placeholder)
            TransportButton(icon: "backward.fill", isActive: false, color: .gray) {}
                .disabled(true)
                .opacity(0.5)

            // Stop
            TransportButton(icon: "stop.fill", isActive: !isPlaying && hasTrack, color: .gray) {
                onStop()
            }
            .disabled(!hasTrack || !isPlaying)

            // Play
            ZStack {
                if isLoading {
                    ProgressView()
                        .controlSize(.regular)
                        .tint(.green)
                } else {
                    TransportButton(
                        icon: isPlaying ? "pause.fill" : "play.fill",
                        isActive: isPlaying,
                        color: .green,
                        isLarge: true
                    ) {
                        if isPlaying { onStop() } else { onPlay() }
                    }
                    .disabled(!hasTrack)
                }
            }
            .frame(width: 60, height: 60)

            // Fast forward (placeholder)
            TransportButton(icon: "forward.fill", isActive: false, color: .gray) {}
                .disabled(true)
                .opacity(0.5)

            Spacer()

            VolumeKnobView(volume: $volume)
        }
    }
}

// MARK: - Transport Button

struct TransportButton: View {
    let icon: String
    let isActive: Bool
    let color: Color
    var isLarge: Bool = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                isActive ? color.opacity(0.8) : Color.gray.opacity(0.4),
                                isActive ? color.opacity(0.4) : Color.gray.opacity(0.2)
                            ],
                            center: .center,
                            startRadius: 0,
                            endRadius: isLarge ? 30 : 20
                        )
                    )
                    .frame(width: isLarge ? 60 : 44, height: isLarge ? 60 : 44)
                    .overlay(
                        Circle()
                            .strokeBorder(Color.black.opacity(0.3), lineWidth: 2)
                    )
                    .shadow(color: isActive ? color.opacity(0.5) : .clear, radius: 5)

                Image(systemName: icon)
                    .font(.system(size: isLarge ? 24 : 16, weight: .bold))
                    .foregroundStyle(isActive ? .white : .gray)
            }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Volume Knob View

struct VolumeKnobView: View {
    @Binding var volume: Float
    @State private var isDragging = false

    private var rotation: Angle {
        .degrees(-135 + Double(volume) * 270)
    }

    var body: some View {
        VStack(spacing: 4) {
            ZStack {
                // Background
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [Color.gray.opacity(0.4), Color.gray.opacity(0.2)],
                            center: .center,
                            startRadius: 0,
                            endRadius: 20
                        )
                    )
                    .frame(width: 40, height: 40)
                    .overlay(
                        Circle()
                            .strokeBorder(Color.black.opacity(0.5), lineWidth: 2)
                    )

                // Knob cap
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color.gray.opacity(0.8), Color.gray.opacity(0.4)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 32, height: 32)
                    .overlay(
                        Rectangle()
                            .fill(Color.purple)
                            .frame(width: 2, height: 10)
                            .offset(y: -8)
                    )
                    .rotationEffect(rotation)
                    .shadow(color: isDragging ? Color.purple.opacity(0.5) : .clear, radius: 3)

                // Volume arc
                Circle()
                    .trim(from: 0, to: CGFloat(volume) * 0.75)
                    .stroke(Color.purple, style: StrokeStyle(lineWidth: 2, lineCap: .round))
                    .frame(width: 46, height: 46)
                    .rotationEffect(.degrees(135))
            }
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { gesture in
                        isDragging = true
                        let delta = Float(-gesture.translation.height / 100)
                        let newValue = volume + delta * 0.1
                        volume = min(max(newValue, 0), 1)
                    }
                    .onEnded { _ in
                        isDragging = false
                    }
            )

            Text("VOL")
                .font(.system(size: 8, weight: .bold, design: .monospaced))
                .foregroundStyle(.secondary)
        }
    }
}

// MARK: - Preview

#Preview {
    BackingTrackView(engine: AudioEngineManager())
        .padding()
        .frame(width: 400)
        .background(Color.black)
}
