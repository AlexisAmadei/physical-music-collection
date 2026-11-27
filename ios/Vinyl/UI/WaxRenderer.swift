import CoreGraphics
import Foundation
import SwiftUI

/// A rendered wax image. CGImage is immutable, so it is safe to hand between threads.
struct WaxImage: @unchecked Sendable {
    let cgImage: CGImage
}

/// What a wax image is made of: the same inputs always give the same image, so they are also its cache key.
struct WaxLook: Hashable, Sendable {
    let base: VinylColor?
    let finish: Finish
    let second: VinylColor?
    let seed: UInt64
    /// Side of the square image, in pixels.
    let side: Int
    /// Side of the Marble pixel grid, scaled up to `side`.
    let marbleSide: Int
}

/// A wax image together with the look it was made for, so a stale image is never drawn for another look.
struct RenderedWax {
    let look: WaxLook
    let image: CGImage
}

extension Optional where Wrapped == RenderedWax {
    /// The image to draw for `look`: the rendered one if it is for this look, else a cached one, else nil (draw plain wax).
    func image(for look: WaxLook?) -> CGImage? {
        guard let look else { return nil }
        if let rendered = self, rendered.look == look { return rendered.image }
        return WaxRenderer.cached(look)
    }
}

/// Draws a Finish onto round wax: Marble and Galaxy from a noise bitmap, the others from `WaxPattern`'s ellipses.
/// Mirrors Android `drawWax`. Heavy for Marble (one pass of noise per pixel), so call it off the main thread; images are cached.
enum WaxRenderer {
    private static let blackWax: UInt32 = 0xFF12_1212

    private final class Box {
        let image: CGImage
        init(_ image: CGImage) { self.image = image }
    }

    // NSCache is thread-safe; the Swift 6 checker cannot know it.
    nonisolated(unsafe) private static let cache: NSCache<NSString, Box> = {
        let cache = NSCache<NSString, Box>()
        cache.countLimit = 24
        return cache
    }()

    private static func key(_ look: WaxLook) -> NSString {
        "\(look.seed)|\(look.base?.rawValue ?? "-")|\(look.finish.rawValue)|\(look.second?.rawValue ?? "-")|\(look.side)|\(look.marbleSide)" as NSString
    }

    /// The image already rendered for this look, if any.
    static func cached(_ look: WaxLook) -> CGImage? { cache.object(forKey: key(look))?.image }

    /// The wax image for this look, rendered now if it is not cached.
    static func image(_ look: WaxLook) -> WaxImage? {
        if let hit = cached(look) { return WaxImage(cgImage: hit) }
        guard let made = render(look) else { return nil }
        cache.setObject(Box(made), forKey: key(look))
        return WaxImage(cgImage: made)
    }

    /// Renders `look` off the main thread (Marble is a pass of noise per pixel); nil for Solid or if cancelled.
    static func renderedOffMain(_ look: WaxLook?) async -> RenderedWax? {
        guard let look else { return nil }
        let made = await Task.detached(priority: .userInitiated) { WaxRenderer.image(look) }.value
        guard !Task.isCancelled, let made else { return nil }
        return RenderedWax(look: look, image: made.cgImage)
    }

    private static func cgColor(_ argb: UInt32, alpha: Double? = nil) -> CGColor {
        let a = alpha ?? Double(argb >> 24) / 255
        return CGColor(
            srgbRed: Double((argb >> 16) & 0xFF) / 255, green: Double((argb >> 8) & 0xFF) / 255,
            blue: Double(argb & 0xFF) / 255, alpha: a
        )
    }

    /// Straight ARGB pixels as a CGImage (premultiplied, as CoreGraphics wants).
    private static func marbleImage(_ pixels: [UInt32], side n: Int) -> CGImage? {
        var bytes = [UInt8](repeating: 0, count: n * n * 4)
        for i in 0..<(n * n) {
            let p = pixels[i]
            let a = Int(p >> 24)
            bytes[i * 4] = UInt8(Int((p >> 16) & 0xFF) * a / 255)
            bytes[i * 4 + 1] = UInt8(Int((p >> 8) & 0xFF) * a / 255)
            bytes[i * 4 + 2] = UInt8(Int(p & 0xFF) * a / 255)
            bytes[i * 4 + 3] = UInt8(a)
        }
        guard let provider = CGDataProvider(data: Data(bytes) as CFData),
              let space = CGColorSpace(name: CGColorSpace.sRGB) else { return nil }
        return CGImage(
            width: n, height: n, bitsPerComponent: 8, bitsPerPixel: 32, bytesPerRow: n * 4, space: space,
            bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue), provider: provider,
            decode: nil, shouldInterpolate: true, intent: .defaultIntent
        )
    }

    private static func render(_ look: WaxLook) -> CGImage? {
        let side = look.side
        guard side > 0, let space = CGColorSpace(name: CGColorSpace.sRGB),
              let ctx = CGContext(
                  data: nil, width: side, height: side, bitsPerComponent: 8, bytesPerRow: 0, space: space,
                  bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
              ) else { return nil }
        let full = CGRect(x: 0, y: 0, width: side, height: side)
        let radius = Double(side) / 2
        let baseArgb = look.base?.argb ?? blackWax
        let secondArgb = look.second?.argb ?? 0xFFFF_FFFF

        ctx.addEllipse(in: full)
        ctx.clip()
        // Marble and Galaxy: the noise bitmap is the whole wax, drawn upright before the y axis is flipped below.
        var bitmapDrawn = false
        if let base = look.base, let second = look.second,
           let pixels = WaxPattern.bitmap(finish: look.finish, seed: look.seed, base: base, second: second, size: look.marbleSide),
           let image = marbleImage(pixels, side: look.marbleSide) {
            ctx.interpolationQuality = .high
            ctx.draw(image, in: full)
            bitmapDrawn = true
        }
        if !bitmapDrawn {
            ctx.setFillColor(cgColor(baseArgb))
            ctx.fill(full)
        }
        // The ellipses use the plan's coordinates: y down.
        ctx.translateBy(x: 0, y: CGFloat(side))
        ctx.scaleBy(x: 1, y: -1)

        func drops(_ list: [Droplet], _ colorOf: (Droplet) -> CGColor) {
            for d in list {
                ctx.saveGState()
                ctx.translateBy(x: radius + d.x * radius, y: radius + d.y * radius)
                ctx.rotate(by: d.rot)
                ctx.setFillColor(colorOf(d))
                ctx.fillEllipse(in: CGRect(x: -d.rx * radius, y: -d.ry * radius, width: 2 * d.rx * radius, height: 2 * d.ry * radius))
                ctx.restoreGState()
            }
        }

        switch look.finish {
        case .marble: break
        case .splatter: drops(WaxPattern.splatter(seed: look.seed)) { cgColor(secondArgb, alpha: $0.alpha) }
        case .split:
            ctx.saveGState()
            ctx.translateBy(x: radius, y: radius)
            ctx.rotate(by: WaxPattern.splitAngle(seed: look.seed))
            ctx.setFillColor(cgColor(secondArgb))
            ctx.fill(CGRect(x: 0, y: -radius, width: radius, height: 2 * radius))
            ctx.restoreGState()
        case .galaxy:
            let stars = WaxPattern.stars(seed: look.seed)
            drops(stars.dots) { cgColor(0xFFFF_FFFF, alpha: $0.alpha) }
            let halo = [cgColor(0xFFFF_FFFF, alpha: 0.95), cgColor(0xFFFF_FFFF, alpha: 0.55), cgColor(0xFFFF_FFFF, alpha: 0)]
            if let gradient = CGGradient(colorsSpace: space, colors: halo as CFArray, locations: [0, 0.25, 1]) {
                for glow in stars.glows {
                    let centre = CGPoint(x: radius + glow.x * radius, y: radius + glow.y * radius)
                    ctx.drawRadialGradient(gradient, startCenter: centre, startRadius: 0, endCenter: centre, endRadius: glow.rx * radius, options: [])
                }
            }
        case .glitter:
            let tint = look.base ?? .white
            drops(WaxPattern.flecks(seed: look.seed)) { cgColor(WaxPattern.fleckColor(base: tint, tone: $0.tone), alpha: $0.alpha) }
        }
        return ctx.makeImage()
    }
}

/// The shimmer over Glitter and Galaxy wax: glints that flash as the phone tilts, drawn over the still wax image (which is
/// not redrawn). Nothing is drawn, and the sensor stays off, for other Finishes and with Reduce Motion. The tilt is read in
/// the small inner view, so a tilting phone redraws these few glints and nothing else. Put it inside the turning disc, so
/// the glints turn with the wax. Mirrors Android `WaxShimmer`.
struct WaxShimmer: View {
    let base: VinylColor?
    let finish: Finish?
    let seed: UInt64
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        if let base, finish == .glitter || finish == .galaxy, !reduceMotion {
            ShimmerGlints(
                glints: WaxPattern.glints(finish: finish, seed: seed),
                // Glitter catches the light in the color of its strongest flecks; Galaxy stars are white.
                color: finish == .galaxy ? .white : Color(hex: WaxPattern.fleckColor(base: base, tone: 0) & 0xFF_FFFF)
            )
        }
    }
}

private struct ShimmerGlints: View {
    let glints: [Glint]
    let color: Color

    var body: some View {
        // Read here, not in the Canvas: the view redraws when the tilt changes.
        let tilt = HoloLight.shared.tilt
        Canvas { context, size in
            let radius = min(size.width, size.height) / 2
            let centre = CGPoint(x: size.width / 2, y: size.height / 2)
            for g in glints {
                let level = WaxPattern.glintLevel(g, tiltX: tilt.x, tiltY: tilt.y)
                guard level >= 0.06 else { continue }
                let c = CGPoint(x: centre.x + g.x * radius, y: centre.y + g.y * radius)
                let r = g.r * radius * (0.8 + 0.8 * level)
                let halo = r * 2.4
                let glow = Gradient(stops: [
                    .init(color: color.opacity(level * 0.9), location: 0),
                    .init(color: color.opacity(level * 0.45), location: 0.35),
                    .init(color: color.opacity(0), location: 1),
                ])
                context.fill(
                    Path(ellipseIn: CGRect(x: c.x - halo, y: c.y - halo, width: 2 * halo, height: 2 * halo)),
                    with: .radialGradient(glow, center: c, startRadius: 0, endRadius: halo)
                )
                let arm = r * 2.5
                var cross = Path()
                cross.move(to: CGPoint(x: c.x - arm, y: c.y))
                cross.addLine(to: CGPoint(x: c.x + arm, y: c.y))
                cross.move(to: CGPoint(x: c.x, y: c.y - arm))
                cross.addLine(to: CGPoint(x: c.x, y: c.y + arm))
                context.stroke(cross, with: .color(color.opacity(level * 0.7)), lineWidth: 0.8)
            }
        }
        .onAppear { HoloLight.shared.addReader() }
        .onDisappear { HoloLight.shared.removeReader() }
    }
}
