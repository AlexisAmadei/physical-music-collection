import SwiftUI

/// The Profile card: round-brushed silver, like the grooves of a record, with the Profile name, the Collection value
/// and the number of Collection Discs. Mirrors Android `ProfileCard`. Tapping it edits the Profile name.
///
/// Still for now: `tilt` only places the light. To make it move, feed `tilt` (and rotate the card with it).
struct ProfileCard: View {
    let name: String
    /// Collection value, euro cents.
    let value: Int
    let discs: Int
    /// Shown tilt, x and y in -1...1 (Android `Tilt`): the light sits where the card is pushed away.
    var tilt = ProfileCard.stillLight
    let onEditName: () -> Void

    /// Reduced motion (and the still card): no tilt, light fixed here. The Android `StillLight`.
    static let stillLight = CGPoint(x: 0.35, y: -0.3)

    private static let shape = RoundedRectangle(cornerRadius: 18, style: .continuous)
    private static let ink = Color(hex: 0x33363B)
    private static let muted = Color(hex: 0x5F646B)
    private static let rim = LinearGradient(
        colors: [.white.opacity(0.9), Color(hex: 0x9AA0A7, opacity: 0.6)], startPoint: .top, endPoint: .bottom
    )

    var body: some View {
        Button(action: onEditName) {
            content
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                .background { SilverSheen(tilt: tilt, rings: true) }
                .clipShape(Self.shape)
                .overlay { Self.shape.strokeBorder(Self.rim, lineWidth: 1) }
                .aspectRatio(1.586, contentMode: .fit)
                .shadow(color: Color(hex: 0x2A2E33, opacity: 0.35), radius: 14, y: 8)
                .contentShape(Self.shape)
        }
        .buttonStyle(CardPress())
        .accessibilityHint("Modifier ton nom")
    }

    private var content: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .center) {
                HStack(spacing: 6) {
                    if name.isEmpty { Text("Ton nom") } else { Text(verbatim: name) }
                    PencilShape()
                        .stroke(Self.muted, style: StrokeStyle(lineWidth: 1.7, lineCap: .round, lineJoin: .round))
                        .frame(width: 16, height: 16)
                        .accessibilityHidden(true)
                }
                .textStyle(Typography.title)
                .foregroundStyle(name.isEmpty ? Self.muted : Self.ink)
                .lineLimit(1)
                .engraved()
                .padding(.horizontal, 6)
                .frame(minHeight: 44)
                Spacer(minLength: 8)
                DiscMark()
                    .stroke(Self.ink, lineWidth: 1.5 * 40 / 44)
                    .frame(width: 40, height: 40)
                    .accessibilityHidden(true)
            }
            Spacer(minLength: 0)
            HStack(alignment: .bottom, spacing: 0) {
                VStack(alignment: .leading, spacing: 0) {
                    Text("Valeur de la collection")
                        .textStyle(Typography.label)
                        .foregroundStyle(Self.muted)
                    Text(verbatim: Price.format(value))
                        .textStyle(Typography.display)
                        .foregroundStyle(Self.ink)
                        .lineLimit(1)
                        .minimumScaleFactor(0.6)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                Group {
                    if discs <= 1 { Text("\(discs) disque") } else { Text("\(discs) disques") }
                }
                .textStyle(Typography.body)
                .foregroundStyle(Self.ink)
                .padding(.leading, 8)
                .padding(.trailing, 6)
                .padding(.bottom, 5)
            }
            .engraved()
            .padding(.leading, 6)
        }
        .padding(.leading, 14)
        .padding(.trailing, 12)
        .padding(.top, 6)
        .padding(.bottom, 18)
    }
}

/// Pressing the card sinks it a little; no dimming, it is metal.
private struct CardPress: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.985 : 1)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}

private extension View {
    /// Light edge under the letters: reads as engraved in the metal.
    func engraved() -> some View {
        shadow(color: .white.opacity(0.8), radius: 0, x: 0, y: 2)
    }
}

/// Brushed silver as Android `drawSilver`: soft bands, two bright lobes turning with the tilt, a slight rainbow
/// kept around the light, and glare. `rings`: the fine concentric brush lines (off on small things, like the
/// Color sticker). The lines never depend on the tilt, so they are not redrawn when it changes.
struct SilverSheen: View {
    /// Shown tilt, x and y in -1...1.
    let tilt: CGPoint
    var rings = false

    private static let base = Gradient(colors: [
        Color(hex: 0xC6CACF), Color(hex: 0xEEF0F2), Color(hex: 0xB6BBC1), Color(hex: 0xE2E5E8), Color(hex: 0xC2C6CB),
    ])
    private static let rainbow = Gradient(colors: [
        Color(hex: 0xFF9AA2), Color(hex: 0xFFD58A), Color(hex: 0xB5F0A0), Color(hex: 0x9EE6F0), Color(hex: 0xA9B4FF),
        Color(hex: 0xE0A8FF),
    ])

    var body: some View {
        ZStack {
            Canvas { context, size in drawBase(&context, size) }
            if rings { BrushedRings() }
            Canvas { context, size in drawLight(&context, size) }
        }
        .accessibilityHidden(true)
    }

    private var reach: CGFloat { min(1, hypot(tilt.x, tilt.y)) }

    private func shift(_ size: CGSize) -> CGFloat {
        tilt.x * size.width * 0.3 + tilt.y * size.height * 0.3
    }

    /// Cool silver with wide soft bands that slide with the tilt.
    private func drawBase(_ context: inout GraphicsContext, _ size: CGSize) {
        let s = shift(size)
        context.fill(
            Path(CGRect(origin: .zero, size: size)),
            with: .linearGradient(
                Self.base, startPoint: CGPoint(x: s, y: 0), endPoint: CGPoint(x: size.width + s, y: size.height),
                options: .mirror
            )
        )
    }

    private func drawLight(_ context: inout GraphicsContext, _ size: CGSize) {
        let w = size.width, h = size.height
        let rect = Path(CGRect(origin: .zero, size: size))
        let center = CGPoint(x: w / 2, y: h / 2)
        let s = shift(size)

        // Round brushing reflects as two bright lobes through the center; they turn with the tilt.
        let bright = Color.white.opacity(0.45 + 0.35 * reach)
        let dark = Color.black.opacity(0.1)
        let clear = Color.white.opacity(0)
        // The sweep wraps at 0 / 1: keep that in a clear zone, or it shows as a thin seam.
        let lobes = Gradient(stops: [
            .init(color: clear, location: 0), .init(color: clear, location: 0.045), .init(color: bright, location: 0.125),
            .init(color: clear, location: 0.205), .init(color: dark, location: 0.375), .init(color: clear, location: 0.545),
            .init(color: bright, location: 0.625), .init(color: clear, location: 0.705), .init(color: dark, location: 0.875),
            .init(color: clear, location: 0.96), .init(color: clear, location: 1),
        ])
        let turn = Angle.degrees(-15 + tilt.x * 70 + tilt.y * 45)
        context.fill(rect, with: .conicGradient(lobes, center: center, angle: turn))

        // Slight rainbow, kept only around the light.
        let light = CGPoint(x: (0.5 + 0.5 * tilt.x) * w, y: (0.5 + 0.5 * tilt.y) * h)
        context.drawLayer { layer in
            layer.opacity = 0.12 + 0.2 * reach
            layer.fill(
                rect,
                with: .linearGradient(
                    Self.rainbow, startPoint: CGPoint(x: s * 1.5 - w * 0.2, y: 0),
                    endPoint: CGPoint(x: s * 1.5 + w * 0.6, y: h), options: .mirror
                )
            )
            layer.blendMode = .destinationIn
            layer.opacity = 1
            layer.fill(
                rect,
                with: .radialGradient(
                    Gradient(colors: [.black, .clear]), center: light, startRadius: 0, endRadius: w * 0.6
                )
            )
        }

        // Glare.
        context.opacity = 0.5 + 0.5 * reach
        context.fill(
            rect,
            with: .radialGradient(
                Gradient(colors: [.white.opacity(0.5), .white.opacity(0.12), .clear]),
                center: light, startRadius: 0, endRadius: w * 0.7
            )
        )
    }
}

/// Fine concentric brush lines, one pixel wide. Fixed seed: same metal every time.
private struct BrushedRings: View {
    @Environment(\.displayScale) private var scale

    var body: some View {
        Canvas { context, size in
            var random = SeededRandom(seed: 7)
            let center = CGPoint(x: size.width / 2, y: size.height / 2)
            let max = hypot(size.width, size.height) / 2
            let pixel = 1 / scale
            func ring(_ r: CGFloat) -> Path {
                Path(ellipseIn: CGRect(x: center.x - r, y: center.y - r, width: 2 * r, height: 2 * r))
            }
            var r = 1.5 * pixel
            while r < max {
                let a = random.nextUnit()
                let color = random.nextBool()
                    ? Color.white.opacity(0.05 + 0.22 * a) : Color.black.opacity(0.02 + 0.07 * a)
                context.stroke(ring(r), with: .color(color), lineWidth: pixel)
                r += 1.4 * pixel
            }
            // A few soft dark bands, like the gaps between tracks on a record.
            for _ in 0..<5 {
                context.stroke(ring(max * (0.3 + 0.7 * random.nextUnit())), with: .color(.black.opacity(0.05)), lineWidth: 2.5)
            }
        }
        .drawingGroup()
    }
}

/// SplitMix64: a tiny random generator with a fixed seed, so the brush lines never change.
private struct SeededRandom {
    var state: UInt64

    init(seed: UInt64) { state = seed }

    mutating func next() -> UInt64 {
        state &+= 0x9E37_79B9_7F4A_7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58_476D_1CE4_E5B9
        z = (z ^ (z >> 27)) &* 0x94D0_49BB_1331_11EB
        return z ^ (z >> 31)
    }

    /// In 0..<1.
    mutating func nextUnit() -> CGFloat { CGFloat(next() >> 11) / CGFloat(1 << 53) }
    mutating func nextBool() -> Bool { next() >> 63 == 1 }
}

/// Android `Glyphs.Pencil`, 24 × 24 viewBox scaled to the frame: "M4 20l1-4L16 5a2.1 2.1 0 0 1 3 3L8 19l-4 1zM14 7l3 3".
private struct PencilShape: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: 4, y: 20))
        p.addLine(to: CGPoint(x: 5, y: 16))
        p.addLine(to: CGPoint(x: 16, y: 5))
        // The SVG arc's radius is a touch under half the chord, so it is drawn as the half circle.
        p.addArc(
            center: CGPoint(x: 17.5, y: 6.5), radius: hypot(1.5, 1.5),
            startAngle: .degrees(-135), endAngle: .degrees(45), clockwise: false
        )
        p.addLine(to: CGPoint(x: 8, y: 19))
        p.addLine(to: CGPoint(x: 4, y: 20))
        p.closeSubpath()
        p.move(to: CGPoint(x: 14, y: 7))
        p.addLine(to: CGPoint(x: 17, y: 10))
        return p.applying(CGAffineTransform(scaleX: rect.width / 24, y: rect.height / 24))
    }
}

/// Android `Glyphs.Disc` (two rings in a 44 × 44 box), scaled to the frame.
private struct DiscMark: Shape {
    func path(in rect: CGRect) -> Path {
        let k = rect.width / 44
        var p = Path()
        p.addEllipse(in: CGRect(x: 12 * k, y: 12 * k, width: 20 * k, height: 20 * k))
        p.addEllipse(in: CGRect(x: 20 * k, y: 20 * k, width: 4 * k, height: 4 * k))
        return p
    }
}

#Preview {
    VStack(spacing: 32) {
        ProfileCard(name: "Alexis", value: 124_050, discs: 42) {}
        ProfileCard(name: "", value: 0, discs: 0) {}
    }
    .padding(20)
}
