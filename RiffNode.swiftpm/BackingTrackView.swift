import SwiftUI
import UniformTypeIdentifiers

// MARK: - Backing Track View (Glass Media Player)
// Liquid Glass UI Design - iOS 26+

struct BackingTrackView: View {

    // MARK: - Dependencies

    @Bindable var engine: AudioEngineManager

    // MARK: - State

    @State private var isImporting = false
    @State private var loadedTrackName: String?
    @State private var isLoading = false

    // MARK: - Body

    var body: some View {
        GlassCard(cornerRadius: 16) {
            VStack(spacing: 16) {
                // Header
                GlassMediaPlayerHeader(
                    hasTrack: loadedTrackName != nil,
                    onImport: { isImporting = true }
                )

                // Track info and waveform preview
                GlassTrackInfoView(
                    trackName: loadedTrackName,
                    isPlaying: engine.isBackingTrackPlaying,
                    isLoading: isLoading
                )

                // Transport controls
                GlassTransportControls(
                    volume: Binding(
                        get: { engine.backingTrackVolume },
                        set: { engine.setBackingTrackVolume($0) }
                    ),
                    isPlaying: engine.isBackingTrackPlaying,
                    hasTrack: loadedTrackName != nil,
                    isLoading: isLoading,
                    onPlay: { engine.playBackingTrack() },
                    onStop: { engine.stopBackingTrack() }
                )
            }
        }
        .fileImporter(
            isPresented: $isImporting,
            allowedContentTypes: [.audio, .mp3, .wav, .aiff],
            allowsMultipleSelection: false
        ) { result in
            handleFileImport(result)
        }
    }

    // MARK: - Private Methods

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

// MARK: - Glass Media Player Header

struct GlassMediaPlayerHeader: View {
    let hasTrack: Bool
    let onImport: () -> Void

    var body: some View {
        HStack {
            HStack(spacing: 8) {
                Image(systemName: "music.note.list")
                    .foregroundStyle(.secondary)
                Text("Backing Track")
                    .font(.headline)
            }

            Spacer()

            Button(action: onImport) {
                HStack(spacing: 6) {
                    Image(systemName: hasTrack ? "arrow.triangle.2.circlepath" : "plus")
                    Text(hasTrack ? "Change" : "Import")
                }
            }
            .buttonStyle(.glass)
        }
    }
}

// MARK: - Glass Track Info View

struct GlassTrackInfoView: View {
    let trackName: String?
    let isPlaying: Bool
    let isLoading: Bool

    var body: some View {
        HStack(spacing: 16) {
            // Album art placeholder / waveform indicator
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(.clear) // Native glass applied via .glassEffect()
                    .frame(width: 64, height: 64)

                if isLoading {
                    ProgressView()
                        .controlSize(.regular)
                        .tint(.primary)
                } else if trackName != nil {
                    // Mini waveform animation when playing
                    MiniWaveformView(isPlaying: isPlaying)
                } else {
                    Image(systemName: "waveform")
                        .font(.title2)
                        .foregroundStyle(.secondary)
                }
            }
            .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 12))

            // Track info
            VStack(alignment: .leading, spacing: 6) {
                if let name = trackName {
                    Text(formatTrackName(name))
                        .font(.subheadline.weight(.semibold))
                        .lineLimit(1)

                    HStack(spacing: 8) {
                        // Status indicator
                        HStack(spacing: 4) {
                            Circle()
                                .fill(isPlaying ? .green : .secondary)
                                .frame(width: 6, height: 6)
                            Text(isPlaying ? "Playing" : "Ready")
                                .font(.caption)
                                .foregroundStyle(isPlaying ? .green : .secondary)
                        }
                    }
                } else {
                    Text("No track loaded")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    Text("Import an audio file to jam along")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
            }

            Spacer()
        }
    }

    private func formatTrackName(_ name: String) -> String {
        // Remove file extension for cleaner display
        var displayName = name
        if let dotIndex = displayName.lastIndex(of: ".") {
            displayName = String(displayName[..<dotIndex])
        }
        // Truncate if too long
        if displayName.count > 30 {
            displayName = String(displayName.prefix(27)) + "..."
        }
        return displayName
    }
}

// MARK: - Mini Waveform View

/// Extracted waveform visualization with stable bar heights
private struct MiniWaveformView: View {
    let isPlaying: Bool

    // Stable heights per bar - computed once
    private static let barHeights: [CGFloat] = [20, 28, 16, 32, 24]

    var body: some View {
        HStack(spacing: 3) {
            ForEach(0..<5, id: \.self) { i in
                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [.primary.opacity(0.6), .primary.opacity(0.3)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(width: 4, height: isPlaying ? Self.barHeights[i] : 8)
                    .animation(
                        isPlaying
                            ? .easeInOut(duration: 0.3 + Double(i) * 0.1)
                                .repeatForever(autoreverses: true)
                            : .default,
                        value: isPlaying
                    )
            }
        }
    }
}

// MARK: - Glass Transport Controls

struct GlassTransportControls: View {
    @Binding var volume: Float
    let isPlaying: Bool
    let hasTrack: Bool
    let isLoading: Bool
    let onPlay: () -> Void
    let onStop: () -> Void

    @Namespace private var transportNamespace

    var body: some View {
        HStack(spacing: 16) {
            // Transport buttons
            GlassEffectContainer(spacing: 8) {
                // Stop button
                Button {
                    onStop()
                } label: {
                    Image(systemName: "stop.fill")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(hasTrack && isPlaying ? .primary : .secondary)
                        .frame(width: 40, height: 40)
                }
                .glassEffect(.regular.interactive(), in: Circle())
                .disabled(!hasTrack || !isPlaying)

                // Play/Pause button (larger)
                Button {
                    if isPlaying { onStop() } else { onPlay() }
                } label: {
                    ZStack {
                        if isLoading {
                            ProgressView()
                                .controlSize(.small)
                                .tint(.white)
                        } else {
                            Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundStyle(.white)
                        }
                    }
                    .frame(width: 52, height: 52)
                    .background {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: hasTrack ? [Color.riffPrimary, Color.riffPrimary.opacity(0.8)] : [.gray, .gray.opacity(0.8)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    }
                }
                .glassEffect(.clear.interactive(), in: Circle())
                .glassEffectID("playButton", in: transportNamespace)
                .disabled(!hasTrack)
            }

            // Volume slider
            HStack(spacing: 10) {
                Image(systemName: "speaker.fill")
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)

                GlassSlider(
                    value: $volume,
                    range: 0...1,
                    tint: Color.riffPrimary,
                    label: "",
                    showValue: false
                )
                .frame(maxWidth: .infinity)

                Image(systemName: "speaker.wave.3.fill")
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
            .glassEffect(.regular, in: Capsule())
        }
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        AdaptiveBackground()

        BackingTrackView(engine: AudioEngineManager())
            .padding()
            .frame(width: 400)
    }
}
