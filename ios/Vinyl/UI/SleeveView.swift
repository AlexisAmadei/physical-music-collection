import QuartzCore
import SwiftUI

/// The front card of Home's wheel turned into an open sleeve: the cover flips on its vertical axis to show
/// the back, and the vinyl slides out to its left (Android `Sleeve`, `FlipFaces` and `Vinyl`).
/// Driven frame by frame by `SleeveMotion`.
struct SleeveView: View {
    let disc: Disc
    let sleeve: SleeveMotion
    /// The white veil of the card's place on the wheel (the sleeve rides along while the wheel turns).
    let veil: Double
    let onEdit: () -> Void

    var body: some View {
        ZStack {
            if sleeve.discVisible {
                VinylView(disc: disc, spin: sleeve.spin)
                    .offset(x: -Self.slideOut * sleeve.slide)
            }
            faces
                .modifier(FlipTurn(degrees: sleeve.rotation))
        }
        .frame(width: WheelPlacement.card, height: WheelPlacement.card)
    }

    /// The back shows past 90°.
    @ViewBuilder private var faces: some View {
        let turn = (sleeve.rotation.truncatingRemainder(dividingBy: 360) + 360).truncatingRemainder(dividingBy: 360)
        if (90...270).contains(turn) {
            SleeveBackFace(disc: disc, onEdit: onEdit)
                .scaleEffect(x: -1) // seen from behind: mirrored back so it reads the right way round
        } else {
            WheelCard(disc: disc, veil: veil)
        }
    }

    /// How far the vinyl comes out, points.
    static let slideOut = 78.0
}

/// Turns a face about its vertical axis, camera 1100 pt away (Android `rotationY` with `cameraDistance`).
struct FlipTurn: GeometryEffect {
    var degrees: Double

    func effectValue(size: CGSize) -> ProjectionTransform {
        var camera = CATransform3DIdentity
        camera.m34 = -1 / 1100
        let turn = CATransform3DMakeRotation(degrees * .pi / 180, 0, 1, 0)
        let toCentre = CATransform3DMakeTranslation(-size.width / 2, -size.height / 2, 0)
        let back = CATransform3DMakeTranslation(size.width / 2, size.height / 2, 0)
        let steps = [toCentre, turn, camera, back]
        return ProjectionTransform(steps.dropFirst().reduce(steps[0], CATransform3DConcat))
    }
}

/// The back of the sleeve: the cover blurred behind a white glass veil, the Disc's details, a decorative barcode
/// and the pencil that opens its Draft.
struct SleeveBackFace: View {
    let disc: Disc
    let onEdit: () -> Void

    private let pad = 18.0

    var body: some View {
        let back = SleeveBack(disc)
        ZStack(alignment: .topLeading) {
            Cover(url: disc.coverURL)
                .scaleEffect(1.24)
                .saturation(1.6)
                .blur(radius: 14)
            LinearGradient(colors: [.white.opacity(0.72), .white.opacity(0.55)], startPoint: .top, endPoint: .bottom)
            VStack(alignment: .leading, spacing: 3) {
                if let artist = back.artist {
                    Text(verbatim: artist.uppercased())
                        .textStyle(TextStyle(size: 11, lineHeight: 14, weight: .medium, letterSpacing: 0.6))
                        .foregroundStyle(Color(hex: 0x5A3A3A))
                        .lineLimit(1)
                }
                Text(verbatim: back.title)
                    .textStyle(TextStyle(size: 17, lineHeight: 21, weight: .bold))
                    .foregroundStyle(Palette.ink)
                    .lineLimit(back.titleLines)
                Text(verbatim: back.details)
                    .textStyle(Typography.label)
                    .foregroundStyle(Palette.ink)
                if let speed = back.speed {
                    Text(verbatim: speed)
                        .textStyle(Typography.label)
                        .foregroundStyle(Palette.ink)
                }
                Text(verbatim: back.addedOn)
                    .textStyle(TextStyle(size: 11, lineHeight: 15))
                    .foregroundStyle(Palette.ink.opacity(0.7))
                if let price = back.price {
                    Text(verbatim: price)
                        .textStyle(Typography.label)
                        .foregroundStyle(Palette.ink)
                }
                if back.showsRating { StarRating(rating: disc.rating, size: 13) }
            }
            .padding(pad)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            Barcode(seed: Barcode.seed(disc))
                .padding([.leading, .bottom], pad)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
            PencilButton(action: onEdit)
                .padding([.trailing, .bottom], 8)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
        }
        .frame(width: WheelPlacement.card, height: WheelPlacement.card)
        .clipped()
        .background(Color.white.shadow(.drop(color: .black.opacity(0.25), radius: 5, y: 2)))
        .contentShape(Rectangle())
    }
}

/// 44 pt glass-look round button with a pencil: "Modifier le disque".
private struct PencilButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            PencilShape()
                .stroke(Palette.ink, style: StrokeStyle(lineWidth: 1.7 * 22 / 24, lineCap: .round, lineJoin: .round))
                .frame(width: 22, height: 22)
                .frame(width: 44, height: 44)
                .background {
                    Circle()
                        .fill(LinearGradient(
                            colors: [.white.opacity(0.75), Color(hex: 0xF0F0F0, opacity: 0.5)],
                            startPoint: .topLeading, endPoint: .bottomTrailing
                        ))
                        .overlay(Circle().stroke(.white.opacity(0.9), lineWidth: 1))
                        .shadow(color: .black.opacity(0.2), radius: 6, y: 2)
                }
                .contentShape(Circle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Modifier le disque")
    }
}

/// Decorative barcode, stable per Disc.
private struct Barcode: View {
    let seed: UInt64

    var body: some View {
        Canvas { context, size in
            var random = SeededRandom(seed: seed)
            var x = 0.0
            while x < size.width {
                let w = 0.8 + Double(random.next() % 3) * 0.8
                context.fill(Path(CGRect(x: x, y: 0, width: min(w, size.width - x), height: size.height)), with: .color(Palette.ink))
                x += w + 0.8 + Double(random.next() % 2) * 0.8
            }
        }
        .frame(width: 56, height: 18)
        .accessibilityHidden(true)
    }

    /// The same bars for a Disc on every launch (Swift's `hashValue` changes between launches).
    static func seed(_ disc: Disc) -> UInt64 {
        var hash: UInt64 = 0xCBF2_9CE4_8422_2325 // FNV-1a
        for byte in "\(disc.title)|\(disc.artist)|\(disc.addedAt.timeIntervalSince1970)".utf8 {
            hash = (hash ^ UInt64(byte)) &* 0x100_0000_01B3
        }
        return hash
    }
}

/// The vinyl Disc out of its sleeve: a 188 pt disc in its wax (`VinylWax`), grooves, the round cover as its label and
/// an 8 pt hole. Turns by `spin` degrees; the highlight stays fixed.
struct VinylView: View {
    let disc: Disc
    let spin: Double

    var body: some View {
        let wax = VinylWax(disc)
        ZStack {
            ZStack {
                Canvas { context, size in
                    let outer = min(size.width, size.height) / 2
                    let centre = CGPoint(x: size.width / 2, y: size.height / 2)
                    func circle(_ r: Double) -> Path {
                        Path(ellipseIn: CGRect(x: centre.x - r, y: centre.y - r, width: 2 * r, height: 2 * r))
                    }
                    context.fill(circle(outer), with: .color(Color(hex: wax.argb & 0xFF_FFFF, opacity: Double(wax.argb >> 24) / 255)))
                    let groove = wax.grooves == .dark ? Color.black.opacity(0.10) : Color.white.opacity(0.07)
                    var r = outer * 0.36
                    while r < outer - 2 {
                        context.stroke(circle(r), with: .color(groove), lineWidth: 0.8)
                        r += 3
                    }
                }
                Cover(url: disc.coverURL)
                    .frame(width: 64, height: 64)
                    .clipShape(Circle())
                Circle().fill(.white).frame(width: 8, height: 8)
            }
            .rotationEffect(.degrees(spin))
            Circle()
                .fill(AngularGradient(
                    stops: [
                        .init(color: .clear, location: 0), .init(color: .white.opacity(0.13), location: 0.06),
                        .init(color: .clear, location: 0.12), .init(color: .clear, location: 0.5),
                        .init(color: .white.opacity(0.13), location: 0.56), .init(color: .clear, location: 0.62),
                        .init(color: .clear, location: 1),
                    ],
                    center: .center
                ))
        }
        .frame(width: 188, height: 188)
        .accessibilityHidden(true)
    }
}
