import SwiftUI

/// The Profile card: a portrait silver card, brushed in diagonal lines, with the Profile name and the
/// `CollectionStats`. Mirrors Android `ProfileCard`. Tapping it edits the Profile name.
///
/// Tilts (10° at most) with the phone, and with the finger while it touches; the light sits where the card is
/// pushed away (`CardTiltDriver`). Reduce Motion: no tilt, light fixed at `stillLight`.
struct ProfileCard: View {
    let name: String
    let stats: CollectionStats
    let onEditName: () -> Void

    /// Reduce Motion: no tilt, light fixed here. The Android `StillLight`.
    static let stillLight = CGPoint(x: 0.35, y: -0.3)
    private static let maxDegrees = 10.0
    /// Portrait, like a trading card.
    private static let ratio = 0.63
    /// Shown when no Collection Disc has a year.
    private static let noYear = "–"

    @Environment(\.locale) private var locale
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var driver = CardTiltDriver()
    /// The card in window coordinates, to read the finger.
    @State private var frame = CGRect.zero
    /// Width the card is centered in; the card takes 70% of it, 320 at most.
    @State private var available: CGFloat = 0

    private static let shape = RoundedRectangle(cornerRadius: 18, style: .continuous)
    private static let ink = Color(hex: 0x33363B)
    private static let muted = Color(hex: 0x5F646B)
    private static let rim = LinearGradient(
        colors: [.white.opacity(0.9), Color(hex: 0x9AA0A7, opacity: 0.6)], startPoint: .top, endPoint: .bottom
    )

    var body: some View {
        let width = min(available * 0.7, 320)
        card
            .frame(width: width, height: width / Self.ratio)
            .frame(maxWidth: .infinity)
            .onGeometryChange(for: CGFloat.self) { $0.size.width } action: { available = $0 }
    }

    private var card: some View {
        let tilt = reduceMotion ? Self.stillLight : driver.shown
        let turn = reduceMotion ? CGPoint.zero : tilt
        return Button(action: onEditName) {
            content
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                .background { SilverSheen(tilt: tilt, lines: true) }
                .clipShape(Self.shape)
                .overlay { Self.shape.strokeBorder(Self.rim, lineWidth: 1) }
                .shadow(color: Color(hex: 0x2A2E33, opacity: 0.35), radius: 14, y: 8)
                .contentShape(Self.shape)
        }
        .buttonStyle(CardPress())
        .accessibilityHint(Text("Modifier ton nom"))
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
            VStack(alignment: .leading, spacing: 0) {
                Text("Valeur")
                    .textStyle(Typography.label)
                    .foregroundStyle(Self.muted)
                Text(verbatim: Price.format(stats.value, locale: locale))
                    .textStyle(Typography.display)
                    .foregroundStyle(Self.ink)
                    .lineLimit(1)
                    .minimumScaleFactor(0.55)
                if stats.unpriced > 0 {
                    Text("\(stats.unpriced) sans prix")
                        .textStyle(Typography.label)
                        .foregroundStyle(Self.muted)
                }
                Grid(alignment: .leading, horizontalSpacing: 8, verticalSpacing: 14) {
                    GridRow {
                        stat("Vinyles", "\(stats.vinyls)")
                        stat("Nombre de CD", "\(stats.cds)")
                    }
                    GridRow {
                        stat("Disques colorés", "\(stats.colored)")
                        stat("Plus ancien", stats.oldestYear.map { "\($0)" } ?? Self.noYear)
                    }
                }
                .padding(.top, 20)
            }
            .engraved()
            .padding(.horizontal, 6)
        }
        .padding(.leading, 14)
        .padding(.trailing, 12)
        .padding(.top, 6)
        .padding(.bottom, 18)
    }

    /// A small muted label over its number, read as one: "Vinyles, 12".
    private func stat(_ label: LocalizedStringKey, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(label)
                .textStyle(Typography.label)
                .foregroundStyle(Self.muted)
                .lineLimit(1)
            Text(verbatim: value)
                .textStyle(Typography.title)
                .foregroundStyle(Self.ink)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
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

/// Along the brush lines, on screen: from bottom left to top right.
private let grain = CGPoint(x: 0.7071, y: -0.7071)

/// Brushed silver as Android `drawSilver`: soft bands, one streak of light across the lines that slides along them
/// with the tilt, a slight rainbow kept around the light, and glare. `lines`: the fine diagonal brush lines. The
/// lines never depend on the tilt, so they are not redrawn when it changes.
struct SilverSheen: View {
    /// Shown tilt, x and y in -1...1.
    let tilt: CGPoint
    var lines = false

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
            if lines { BrushedLines() }
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
        let diagonal = hypot(w, h)
        let s = shift(size)

        // Straight brushing reflects as one streak across the lines; the tilt slides it along them.
        let along = (tilt.x * grain.x + tilt.y * grain.y) * diagonal * 0.35
        let mid = CGPoint(x: w / 2 + grain.x * along, y: h / 2 + grain.y * along)
        let out = diagonal * 0.4
        let dark = Color.black.opacity(0.08)
        let clear = Color.white.opacity(0)
        let streak = Gradient(stops: [
            .init(color: clear, location: 0), .init(color: dark, location: 0.18),
            .init(color: .white.opacity(0.45 + 0.35 * reach), location: 0.5), .init(color: dark, location: 0.82),
            .init(color: clear, location: 1),
        ])
        context.fill(
            rect,
            with: .linearGradient(
                streak, startPoint: CGPoint(x: mid.x - grain.x * out, y: mid.y - grain.y * out),
                endPoint: CGPoint(x: mid.x + grain.x * out, y: mid.y + grain.y * out)
            )
        )

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

/// Fine straight brush lines at 45° (along `grain`), one pixel wide. Fixed seed: same metal every time.
private struct BrushedLines: View {
    @Environment(\.displayScale) private var scale

    var body: some View {
        Canvas { context, size in
            var random = SeededRandom(seed: 7)
            let center = CGPoint(x: size.width / 2, y: size.height / 2)
            // Half the diagonal: rotated lines this long still cover the corners.
            let half = hypot(size.width, size.height) / 2
            let pixel = 1 / scale
            // Horizontal lines turned 45° counterclockwise: from bottom left to top right.
            context.translateBy(x: center.x, y: center.y)
            context.rotate(by: .degrees(-45))
            func line(_ y: CGFloat) -> Path {
                Path { $0.move(to: CGPoint(x: -half, y: y)); $0.addLine(to: CGPoint(x: half, y: y)) }
            }
            var y = -half
            while y < half {
                let a = random.nextUnit()
                let color = random.nextBool()
                    ? Color.white.opacity(0.05 + 0.22 * a) : Color.black.opacity(0.02 + 0.07 * a)
                context.stroke(line(y), with: .color(color), lineWidth: pixel)
                y += 1.4 * pixel
            }
            // A few soft darker bands, where the brush pressed harder.
            for _ in 0..<5 {
                context.stroke(line(half * (1.8 * random.nextUnit() - 0.9)), with: .color(.black.opacity(0.05)), lineWidth: 2.5)
            }
        }
        .drawingGroup()
    }
}

#Preview {
    VStack(spacing: 32) {
        ProfileCard(
            name: "Alexis", stats: CollectionStats(vinyls: 5, cds: 2, colored: 3, oldestYear: 1959, value: 15_839, unpriced: 1)
        ) {}
        ProfileCard(name: "", stats: CollectionStats([])) {}
    }
    .padding(20)
}
