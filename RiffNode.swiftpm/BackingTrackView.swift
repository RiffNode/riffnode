import SwiftUI
import UniformTypeIdentifiers

// MARK: - Backing Track View (Clean Liquid Glass Style)

struct BackingTrackView: View {

    // MARK: - Dependencies

    @Bindable var engine: AudioEngineManager

    // MARK: - State

    @State private var isImporting = false
    @State private var loadedTrackName: String?
    @State private var isLoading = false
    @State private var reelRotation: Double = 0
    @State private var rotationTimer: Timer?
    @Namespace private var trackNamespace

    // MARK: - Body

    var body: some View {
        GlassEffectContainer(spacing: 12) {
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
                    namespace: trackNamespace,
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
        }
        .glassEffect(.regular.tint(.purple.opacity(0.2)), in: .rect(cornerRadius: 20))
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
        rotationTimer?.invalidate()
        rotationTimer = Timer.scheduledTimer(withTimeInterval: 0.03, repeats: true) { [self] _ in
            Task { @MainActor in
                withAnimation(.linear(duration: 0.03)) {
                    reelRotation += 2
                }
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
            guard let url = urls.first else { return }

            isLoading = true
            loadedTrackName = url.lastPathComponent

            Task {
                do {
                    let accessing = url.startAccessingSecurityScopedResource()
                    defer {
                        if accessing {
                            url.stopAccessingSecurityScopedResource()
                        }
                    }

                    try await engine.loadBackingTrack(url: url)
                    isLoading = false
                } catch {
                    isLoading = false
                    loadedTrackName = nil
                    print("Failed to load backing track: \(error)")
                }
            }

        case .failure(let error):
            print("File import failed: \(error)")
        }
    }
}

// MARK: - Backing Track Header

struct BackingTrackHeader: View {
    let onImport: () -> Void

    var body: some View {
        HStack {
            HStack(spacing: 8) {
                Image(systemName: "music.note.list")
                    .foregroundStyle(.purple)
                Text("BACKING TRACK")
                    .font(.system(size: 14, weight: .bold, design: .monospaced))
                    .foregroundStyle(.white)
            }

            Spacer()

            Button(action: onImport) {
                HStack(spacing: 4) {
                    Image(systemName: "plus")
                    Text("Load")
                }
                .font(.system(size: 12, weight: .semibold))
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
            }
            .buttonStyle(.glassProminent)
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
        HStack(spacing: 16) {
            TapeReelView(rotation: rotation, isSupply: true)

            TapeWindowView(isPlaying: isPlaying, trackName: trackName)
                .frame(maxWidth: .infinity)

            TapeReelView(rotation: -rotation, isSupply: false)
        }
        .padding()
        .glassEffect(in: .rect(cornerRadius: 12))
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
                if let name = trackName {
                    Text(name)
                        .font(.system(size: 11, weight: .medium, design: .monospaced))
                        .foregroundStyle(.green)
                        .lineLimit(1)
                        .padding(.horizontal, 8)
                } else {
                    Text("NO TRACK LOADED")
                        .font(.system(size: 10, weight: .medium, design: .monospaced))
                        .foregroundStyle(.secondary)
                }
            }
            .frame(height: 28)
            .frame(maxWidth: .infinity)
            .glassEffect(in: .rect(cornerRadius: 6))

            // Tape transport visualization
            HStack(spacing: 3) {
                ForEach(0..<8, id: \.self) { i in
                    Rectangle()
                        .fill(
                            isPlaying
                                ? Color.brown.opacity(0.5 + Double(i) * 0.06)
                                : Color.brown.opacity(0.2)
                        )
                        .frame(width: 6, height: 16)
                        .clipShape(RoundedRectangle(cornerRadius: 1))
                }
            }

            // Status indicator
            HStack(spacing: 6) {
                Circle()
                    .fill(isPlaying ? Color.green : Color.secondary.opacity(0.3))
                    .frame(width: 6, height: 6)

                Text(isPlaying ? "PLAYING" : "STOPPED")
                    .font(.system(size: 9, weight: .bold, design: .monospaced))
                    .foregroundStyle(isPlaying ? .green : .secondary)
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
            // Tape spool
            Circle()
                .fill(Color.brown.opacity(0.4))
                .frame(width: isSupply ? 44 : 36, height: isSupply ? 44 : 36)

            // Reel hub
            Circle()
                .fill(Color.white.opacity(0.2))
                .frame(width: 16, height: 16)

            // Spokes
            ForEach(0..<3, id: \.self) { i in
                Rectangle()
                    .fill(Color.white.opacity(0.3))
                    .frame(width: 2, height: 24)
                    .rotationEffect(.degrees(Double(i) * 120 + rotation))
            }

            // Center hole
            Circle()
                .fill(Color.black.opacity(0.6))
                .frame(width: 6, height: 6)
        }
        .frame(width: 56, height: 56)
        .glassEffect(in: .circle)
    }
}

// MARK: - Transport Controls View

struct TransportControlsView: View {
    @Binding var volume: Float
    let isPlaying: Bool
    let hasTrack: Bool
    let isLoading: Bool
    let namespace: Namespace.ID
    let onPlay: () -> Void
    let onStop: () -> Void

    var body: some View {
        GlassEffectContainer(spacing: 8) {
            HStack(spacing: 12) {
                // Stop
                Button {
                    onStop()
                } label: {
                    Image(systemName: "stop.fill")
                        .font(.system(size: 14))
                        .frame(width: 36, height: 36)
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.glass)
                .disabled(!hasTrack || !isPlaying)
                .opacity(hasTrack && isPlaying ? 1 : 0.5)

                // Play/Pause
                ZStack {
                    if isLoading {
                        ProgressView()
                            .controlSize(.regular)
                    } else {
                        Button {
                            if isPlaying { onStop() } else { onPlay() }
                        } label: {
                            Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                                .font(.system(size: 20))
                                .frame(width: 50, height: 50)
                                .foregroundStyle(hasTrack ? (isPlaying ? .white : .green) : .secondary)
                        }
                        .buttonStyle(.glassProminent)
                        .disabled(!hasTrack)
                        .glassEffectID("play-button", in: namespace)
                    }
                }

                Spacer()

                // Volume control
                VolumeControlView(volume: $volume)
            }
        }
    }
}

// MARK: - Volume Control View

struct VolumeControlView: View {
    @Binding var volume: Float
    @State private var isDragging = false

    private var rotation: Angle {
        .degrees(-135 + Double(volume) * 270)
    }

    var body: some View {
        VStack(spacing: 4) {
            ZStack {
                // Knob cap with indicator
                Circle()
                    .fill(Color.white.opacity(0.1))
                    .frame(width: 36, height: 36)
                    .overlay(
                        Rectangle()
                            .fill(Color.purple)
                            .frame(width: 2, height: 10)
                            .offset(y: -10)
                    )
                    .rotationEffect(rotation)

                // Volume arc
                Circle()
                    .trim(from: 0, to: CGFloat(volume) * 0.75)
                    .stroke(Color.purple, style: StrokeStyle(lineWidth: 2, lineCap: .round))
                    .frame(width: 42, height: 42)
                    .rotationEffect(.degrees(135))
            }
            .glassEffect(.regular.interactive(), in: .circle)
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
        .frame(width: 380)
        .background(Color(red: 0.05, green: 0.05, blue: 0.1))
}
