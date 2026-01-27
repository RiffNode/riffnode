import SwiftUI

// MARK: - RiffNode Liquid Glass Design System
// Apple iOS 26+ Liquid Glass design language implementation
// Using native .glassEffect() modifier when available

// MARK: - Adaptive Background

/// Creates an adaptive mesh gradient background that responds to light/dark mode
struct AdaptiveBackground: View {
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Base gradient mesh
                MeshGradient(
                    width: 3,
                    height: 3,
                    points: [
                        [0.0, 0.0], [0.5, 0.0], [1.0, 0.0],
                        [0.0, 0.5], [0.5, 0.5], [1.0, 0.5],
                        [0.0, 1.0], [0.5, 1.0], [1.0, 1.0]
                    ],
                    colors: meshColors
                )

                // Subtle noise texture for depth
                Canvas { context, size in
                    for _ in 0..<100 {
                        let x = CGFloat.random(in: 0...size.width)
                        let y = CGFloat.random(in: 0...size.height)
                        let radius = CGFloat.random(in: 0.5...1.5)
                        let opacity = Double.random(in: 0.01...0.03)

                        context.fill(
                            Path(ellipseIn: CGRect(x: x, y: y, width: radius, height: radius)),
                            with: .color(.white.opacity(opacity))
                        )
                    }
                }
            }
        }
        .ignoresSafeArea()
    }

    private var meshColors: [Color] {
        if colorScheme == .dark {
            return [
                Color(red: 0.08, green: 0.08, blue: 0.12),
                Color(red: 0.10, green: 0.08, blue: 0.14),
                Color(red: 0.06, green: 0.08, blue: 0.12),
                Color(red: 0.08, green: 0.10, blue: 0.16),
                Color(red: 0.10, green: 0.10, blue: 0.14),
                Color(red: 0.08, green: 0.08, blue: 0.12),
                Color(red: 0.06, green: 0.08, blue: 0.14),
                Color(red: 0.08, green: 0.10, blue: 0.16),
                Color(red: 0.10, green: 0.08, blue: 0.12)
            ]
        } else {
            return [
                Color(red: 0.95, green: 0.95, blue: 0.97),
                Color(red: 0.92, green: 0.94, blue: 0.98),
                Color(red: 0.96, green: 0.94, blue: 0.96),
                Color(red: 0.94, green: 0.96, blue: 0.98),
                Color(red: 0.95, green: 0.95, blue: 0.97),
                Color(red: 0.93, green: 0.95, blue: 0.98),
                Color(red: 0.96, green: 0.94, blue: 0.96),
                Color(red: 0.94, green: 0.96, blue: 0.98),
                Color(red: 0.95, green: 0.95, blue: 0.97)
            ]
        }
    }
}

// MARK: - Glass Card Container

/// A glass-morphism card container with blur and subtle border
/// Uses native .glassEffect() on iOS 26+, falls back to material on earlier versions
struct GlassCard<Content: View>: View {
    let content: Content
    var tint: Color?
    var cornerRadius: CGFloat
    var padding: CGFloat

    init(
        tint: Color? = nil,
        cornerRadius: CGFloat = 20,
        padding: CGFloat = 16,
        @ViewBuilder content: () -> Content
    ) {
        self.content = content()
        self.tint = tint
        self.cornerRadius = cornerRadius
        self.padding = padding
    }

    var body: some View {
        content
            .padding(padding)
            .background {
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(.ultraThinMaterial)
                    .overlay {
                        if let tint = tint {
                            RoundedRectangle(cornerRadius: cornerRadius)
                                .fill(tint.opacity(0.1))
                        }
                    }
                    .overlay {
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .strokeBorder(
                                LinearGradient(
                                    colors: [
                                        .white.opacity(0.3),
                                        .white.opacity(0.1),
                                        .white.opacity(0.05)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                    }
                    .shadow(color: .black.opacity(0.1), radius: 10, y: 5)
            }
            .glassEffect(.regular.tint(tint ?? .clear), in: RoundedRectangle(cornerRadius: cornerRadius))
    }
}

// MARK: - Glass Toolbar

/// A floating glass toolbar for navigation and controls
struct GlassToolbar<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .glassEffect(.regular, in: Capsule())
    }
}

// MARK: - Glass Button Style

/// Interactive glass button with scale, bounce, and shimmer effects
struct GlassButtonStyle: ButtonStyle {
    var tint: Color
    var isSmall: Bool

    init(tint: Color = .accentColor, isSmall: Bool = false) {
        self.tint = tint
        self.isSmall = isSmall
    }

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(isSmall ? .subheadline.weight(.medium) : .headline.weight(.semibold))
            .foregroundStyle(tint)
            .padding(.horizontal, isSmall ? 14 : 20)
            .padding(.vertical, isSmall ? 8 : 12)
            .glassEffect(.regular.tint(tint).interactive(), in: Capsule())
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

// MARK: - Glass Pill Button Style

/// Compact pill-shaped glass button for tabs and toggles
struct GlassPillStyle: ButtonStyle {
    var isSelected: Bool
    var tint: Color

    init(isSelected: Bool = false, tint: Color = .accentColor) {
        self.isSelected = isSelected
        self.tint = tint
    }

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 13, weight: .medium))
            .foregroundStyle(isSelected ? .white : .secondary)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background {
                if isSelected {
                    Capsule().fill(tint)
                }
            }
            .glassEffect(isSelected ? .clear : .regular.interactive(), in: Capsule())
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.spring(response: 0.25, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

// MARK: - Glass Icon Button

/// Circular glass button for icons
struct GlassIconButton: View {
    let icon: String
    var tint: Color
    var size: CGFloat
    let action: () -> Void

    init(
        icon: String,
        tint: Color = .primary,
        size: CGFloat = 44,
        action: @escaping () -> Void
    ) {
        self.icon = icon
        self.tint = tint
        self.size = size
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: size * 0.4, weight: .medium))
                .foregroundStyle(tint)
                .frame(width: size, height: size)
                .glassEffect(.regular.interactive(), in: Circle())
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

// MARK: - Scale Button Style

/// Simple scale animation on press
struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.92 : 1.0)
            .animation(.spring(response: 0.25, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

// MARK: - Glass Slider

/// A modern glass-style slider control
struct GlassSlider: View {
    @Binding var value: Float
    var range: ClosedRange<Float>
    var tint: Color
    var label: String
    var showValue: Bool
    var format: String

    init(
        value: Binding<Float>,
        range: ClosedRange<Float> = 0...1,
        tint: Color = .accentColor,
        label: String = "",
        showValue: Bool = true,
        format: String = "%.0f"
    ) {
        self._value = value
        self.range = range
        self.tint = tint
        self.label = label
        self.showValue = showValue
        self.format = format
    }

    private var normalizedValue: CGFloat {
        CGFloat((value - range.lowerBound) / (range.upperBound - range.lowerBound))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if !label.isEmpty || showValue {
                HStack {
                    if !label.isEmpty {
                        Text(label)
                            .font(.caption.weight(.medium))
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    if showValue {
                        Text(String(format: format, value))
                            .font(.caption.weight(.semibold).monospacedDigit())
                            .foregroundStyle(tint)
                    }
                }
            }

            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Track background with glass effect
                    Capsule()
                        .fill(.ultraThinMaterial)
                        .frame(height: 6)

                    // Filled track
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [tint.opacity(0.8), tint],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geometry.size.width * normalizedValue, height: 6)

                    // Thumb with glass effect
                    Circle()
                        .fill(.white)
                        .frame(width: 20, height: 20)
                        .shadow(color: tint.opacity(0.3), radius: 4, y: 2)
                        .overlay {
                            Circle()
                                .fill(tint)
                                .frame(width: 8, height: 8)
                        }
                        .offset(x: (geometry.size.width - 20) * normalizedValue)
                }
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { gesture in
                            let ratio = Float(gesture.location.x / geometry.size.width)
                            let newValue = range.lowerBound + ratio * (range.upperBound - range.lowerBound)
                            value = min(max(newValue, range.lowerBound), range.upperBound)
                        }
                )
            }
            .frame(height: 20)
        }
    }
}

// MARK: - Glass Knob

/// A modern glass circular knob control
struct GlassKnob: View {
    @Binding var value: Float
    var range: ClosedRange<Float>
    var tint: Color
    var label: String
    var format: String
    var size: CGFloat

    @State private var isDragging = false

    init(
        value: Binding<Float>,
        range: ClosedRange<Float> = 0...100,
        tint: Color = .accentColor,
        label: String = "",
        format: String = "%.0f",
        size: CGFloat = 60
    ) {
        self._value = value
        self.range = range
        self.tint = tint
        self.label = label
        self.format = format
        self.size = size
    }

    private var normalizedValue: Double {
        Double((value - range.lowerBound) / (range.upperBound - range.lowerBound))
    }

    private var rotation: Angle {
        .degrees(-135 + normalizedValue * 270)
    }

    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                // Track arc
                Circle()
                    .trim(from: 0, to: 0.75)
                    .stroke(
                        Color.primary.opacity(0.1),
                        style: StrokeStyle(lineWidth: 4, lineCap: .round)
                    )
                    .frame(width: size + 8, height: size + 8)
                    .rotationEffect(.degrees(135))

                // Value arc
                Circle()
                    .trim(from: 0, to: normalizedValue * 0.75)
                    .stroke(
                        LinearGradient(
                            colors: [tint.opacity(0.6), tint],
                            startPoint: .leading,
                            endPoint: .trailing
                        ),
                        style: StrokeStyle(lineWidth: 4, lineCap: .round)
                    )
                    .frame(width: size + 8, height: size + 8)
                    .rotationEffect(.degrees(135))

                // Knob body with glass effect
                Circle()
                    .fill(.ultraThinMaterial)
                    .frame(width: size, height: size)
                    .overlay {
                        Circle()
                            .strokeBorder(
                                LinearGradient(
                                    colors: [.white.opacity(0.4), .white.opacity(0.1)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                    }
                    .shadow(color: isDragging ? tint.opacity(0.4) : .black.opacity(0.1), radius: isDragging ? 8 : 4)

                // Indicator line
                RoundedRectangle(cornerRadius: 2)
                    .fill(tint)
                    .frame(width: 3, height: size * 0.25)
                    .offset(y: -size * 0.28)
                    .rotationEffect(rotation)

                // Center value
                Text(String(format: format, value))
                    .font(.system(size: size * 0.2, weight: .bold).monospacedDigit())
                    .foregroundStyle(.primary)
            }
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { gesture in
                        isDragging = true
                        let delta = Float(-gesture.translation.height / 100)
                        let sensitivity: Float = (range.upperBound - range.lowerBound) * 0.01
                        let newValue = value + delta * sensitivity
                        value = min(max(newValue, range.lowerBound), range.upperBound)
                    }
                    .onEnded { _ in
                        isDragging = false
                    }
            )

            if !label.isEmpty {
                Text(label)
                    .font(.caption2.weight(.medium))
                    .foregroundStyle(.secondary)
            }
        }
    }
}

// MARK: - Glass Tab Bar

/// A glass tab bar with morphing selection indicator
struct GlassTabBar<Tab: Hashable & CaseIterable & Sendable>: View where Tab: RawRepresentable, Tab.RawValue == String {
    @Binding var selection: Tab
    var tint: Color
    let icon: (Tab) -> String

    @Namespace private var namespace

    init(
        selection: Binding<Tab>,
        tint: Color = .accentColor,
        icon: @escaping (Tab) -> String
    ) {
        self._selection = selection
        self.tint = tint
        self.icon = icon
    }

    var body: some View {
        GlassEffectContainer(spacing: 4) {
            ForEach(Array(Tab.allCases), id: \.self) { tab in
                Button {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                        selection = tab
                    }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: icon(tab))
                            .font(.system(size: 14, weight: .medium))

                        Text(tab.rawValue)
                            .font(.system(size: 13, weight: .medium))
                    }
                    .foregroundStyle(selection == tab ? .white : .secondary)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background {
                        if selection == tab {
                            Capsule()
                                .fill(tint)
                        }
                    }
                    .glassEffect(
                        selection == tab ? .clear : .regular.interactive(),
                        in: Capsule()
                    )
                    .glassEffectID(tab, in: namespace)
                }
                .buttonStyle(.plain)
            }
        }
    }
}

// MARK: - Glass Status Indicator

/// A minimal glass status indicator (online/offline/loading)
struct GlassStatusIndicator: View {
    enum Status {
        case active, inactive, loading
    }

    let status: Status
    var label: String?

    var body: some View {
        HStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(statusColor.opacity(0.3))
                    .frame(width: 10, height: 10)

                if status == .loading {
                    Circle()
                        .trim(from: 0, to: 0.7)
                        .stroke(statusColor, lineWidth: 2)
                        .frame(width: 10, height: 10)
                        .rotationEffect(.degrees(360))
                        .animation(.linear(duration: 1).repeatForever(autoreverses: false), value: status)
                } else {
                    Circle()
                        .fill(statusColor)
                        .frame(width: 6, height: 6)
                }
            }

            if let label = label {
                Text(label)
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .glassEffect(.regular, in: Capsule())
    }

    private var statusColor: Color {
        switch status {
        case .active: return .green
        case .inactive: return .red
        case .loading: return .orange
        }
    }
}

// MARK: - Glass Divider

/// A subtle glass divider line
struct GlassDivider: View {
    var vertical: Bool

    init(vertical: Bool = false) {
        self.vertical = vertical
    }

    var body: some View {
        if vertical {
            Rectangle()
                .fill(.white.opacity(0.1))
                .frame(width: 1)
        } else {
            Rectangle()
                .fill(.white.opacity(0.1))
                .frame(height: 1)
        }
    }
}

// MARK: - Glass Effect Card (Pedal Style)

/// A glass effect card specifically designed for effect pedals
struct GlassEffectPedal: View {
    let effect: EffectNode
    var isSelected: Bool = false
    let onTap: () -> Void
    let onDoubleTap: () -> Void
    let onDelete: () -> Void

    @State private var isHovering = false

    var body: some View {
        VStack(spacing: 8) {
            // LED indicator
            Circle()
                .fill(effect.isEnabled ? Color.green : Color.red.opacity(0.4))
                .frame(width: 8, height: 8)
                .shadow(color: effect.isEnabled ? .green.opacity(0.8) : .clear, radius: 4)

            // Effect icon
            Image(systemName: effect.type.icon)
                .font(.system(size: 24, weight: .medium))
                .foregroundStyle(effect.isEnabled ? effect.type.color : .secondary)

            // Effect name
            Text(effect.type.abbreviation)
                .font(.system(size: 12, weight: .bold, design: .rounded))
                .foregroundStyle(effect.isEnabled ? .primary : .secondary)

            Text(effect.type.rawValue)
                .font(.system(size: 9, weight: .medium))
                .foregroundStyle(.secondary)
                .lineLimit(1)
        }
        .frame(width: 80, height: 110)
        .glassEffect(
            .regular.tint(effect.isEnabled ? effect.type.color : .clear).interactive(),
            in: RoundedRectangle(cornerRadius: 16)
        )
        .overlay {
            if isSelected {
                RoundedRectangle(cornerRadius: 16)
                    .strokeBorder(effect.type.color, lineWidth: 2)
            }
        }
        .overlay {
            // Delete button on hover
            if isHovering {
                VStack {
                    HStack {
                        Spacer()
                        Button(action: onDelete) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 16))
                                .foregroundStyle(.white, .red)
                        }
                        .buttonStyle(.plain)
                    }
                    Spacer()
                }
                .padding(6)
            }
        }
        .onTapGesture(count: 2) { onDoubleTap() }
        .onTapGesture { onTap() }
        .onHover { isHovering = $0 }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(effect.type.rawValue) pedal, \(effect.isEnabled ? "enabled" : "bypassed")")
        .accessibilityHint("Tap to select, double-tap to toggle")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

// MARK: - Color Extensions

extension Color {
    // Effect category colors (softer, adapted for glass)
    static let dynamicsColor = Color.cyan.opacity(0.8)
    static let filterColor = Color.purple.opacity(0.8)
    static let gainColor = Color.orange.opacity(0.8)
    static let modulationColor = Color.green.opacity(0.8)
    static let timeColor = Color.blue.opacity(0.8)
}

// MARK: - View Extensions

extension View {
    /// Apply glass card styling
    func glassCard(tint: Color? = nil, cornerRadius: CGFloat = 20, padding: CGFloat = 16) -> some View {
        self
            .padding(padding)
            .glassEffect(.regular.tint(tint ?? .clear), in: RoundedRectangle(cornerRadius: cornerRadius))
    }

    /// Apply glass pill styling
    func glassPill() -> some View {
        self
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .glassEffect(.regular, in: Capsule())
    }
}

// MARK: - Preview

#Preview("Design System Components") {
    ZStack {
        AdaptiveBackground()

        ScrollView {
            VStack(spacing: 24) {
                // Glass Card
                GlassCard(tint: .cyan) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Glass Card")
                            .font(.headline)
                        Text("A translucent container with blur effect")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }

                // Buttons
                HStack(spacing: 16) {
                    Button("Primary") {}
                        .buttonStyle(GlassButtonStyle(tint: .cyan))

                    Button("Small") {}
                        .buttonStyle(GlassButtonStyle(tint: .orange, isSmall: true))

                    GlassIconButton(icon: "gear", tint: .primary) {}
                }

                // Tab Pills
                HStack(spacing: 8) {
                    Button("Selected") {}
                        .buttonStyle(GlassPillStyle(isSelected: true, tint: .cyan))

                    Button("Unselected") {}
                        .buttonStyle(GlassPillStyle(isSelected: false))
                }

                // Status Indicators
                HStack(spacing: 16) {
                    GlassStatusIndicator(status: .active, label: "Running")
                    GlassStatusIndicator(status: .inactive, label: "Stopped")
                }

                // Knobs
                HStack(spacing: 32) {
                    GlassKnob(
                        value: .constant(75),
                        tint: .cyan,
                        label: "GAIN"
                    )

                    GlassKnob(
                        value: .constant(50),
                        tint: .orange,
                        label: "TONE"
                    )
                }

                // Slider
                GlassSlider(
                    value: .constant(0.7),
                    tint: .green,
                    label: "Volume"
                )
                .padding(.horizontal)
            }
            .padding()
        }
    }
}
