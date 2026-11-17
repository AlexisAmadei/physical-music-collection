import SwiftUI

/// The Profile card: round-brushed silver, like the grooves of a vinyl Disc, with the Profile name, the Collection value
/// and the number of Collection Discs. Mirrors Android `ProfileCard`. Tapping it edits the Profile name.
///
/// Tilts (10° at most) with the phone, and with the finger while it touches; the light sits where the card is
/// pushed away (`CardTiltDriver`). Reduce Motion: no tilt, light fixed at `stillLight`.
struct ProfileCard: View {
    let name: String
    /// Collection value, euro cents.
    let value: Int
    let discs: Int
    let onEditName: () -> Void

    /// Reduce Motion: no tilt, light fixed here. The Android `StillLight`.
    static let stillLight = CGPoint(x: 0.35, y: -0.3)
    private static let maxDegrees = 10.0

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var driver = CardTiltDriver()
    /// The card in window coordinates, to read the finger.
    @State private var frame = CGRect.zero

    private static let shape = RoundedRectangle(cornerRadius: 18, style: .continuous)
    private static let ink = Color(hex: 0x33363B)
    private static let muted = Color(hex: 0x5F646B)
    private static let rim = LinearGradient(
        colors: [.white.opacity(0.9), Color(hex: 0x9AA0A7, opacity: 0.6)], startPoint: .top, endPoint: .bottom
    )

    var body: some View {
        let tilt = reduceMotion ? Self.stillLight : driver.shown
        let turn = reduceMotion ? CGPoint.zero : tilt
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
        .gesture(FingerWatcher { [driver, frame, reduceMotion] point in
            driver.finger = reduceMotion ? nil : point.map { Tilt(finger: $0, on: frame) }
        })
        .onGeometryChange(for: CGRect.self) { $0.frame(in: .global) } action: { frame = $0 }
        .rotation3DEffect(.degrees(turn.x * Self.maxDegrees), axis: (x: 0, y: 1, z: 0))
        .rotation3DEffect(.degrees(-turn.y * Self.maxDegrees), axis: (x: 1, y: 0, z: 0))
        .onAppear { if !reduceMotion { driver.start() } }
        .onDisappear { driver.stop() }
        .onChange(of: reduceMotion) { _, still in
            if still { driver.stop() } else { driver.start() }
        }
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
                GlyphView(glyph: Glyphs.disc, tint: Self.ink, size: 40)
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
            // A few soft dark bands, like the gaps between tracks on a vinyl Disc.
            for _ in 0..<5 {
                context.stroke(ring(max * (0.3 + 0.7 * random.nextUnit())), with: .color(.black.opacity(0.05)), lineWidth: 2.5)
            }
        }
        .drawingGroup()
    }
}

#Preview {
    VStack(spacing: 32) {
        ProfileCard(name: "Alexis", value: 124_050, discs: 42) {}
        ProfileCard(name: "", value: 0, discs: 0) {}
    }
    .padding(20)
}
