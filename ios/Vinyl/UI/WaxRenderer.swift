import CoreGraphics
import Foundation

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

/// Draws a Finish onto round wax: Marble and Galaxy from the noise bitmap, the others from `WaxPattern`'s ellipses.
/// Mirrors Android `drawWax`. Heavy for Marble (one pass of noise per pixel), so call it off the main thread; images are cached.
enum WaxRenderer {
    private static let blackWax: UInt32 = 0xFF12_1212
    private static let silver: UInt32 = 0xFFE6_E8EC

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
        var marbleDrawn = false
        if look.finish == .marble || look.finish == .galaxy, let base = look.base, let second = look.second {
            let pixels = WaxPattern.marble(seed: look.seed, base: base, second: second, size: look.marbleSide)
            if let image = marbleImage(pixels, side: look.marbleSide) {
                ctx.interpolationQuality = .high
                ctx.draw(image, in: full)
                marbleDrawn = true
            }
        }
        if !marbleDrawn {
            ctx.setFillColor(cgColor(baseArgb))
            ctx.fill(full)
        }
        // The ellipses use the plan's coordinates: y down.
        ctx.translateBy(x: 0, y: CGFloat(side))
        ctx.scaleBy(x: 1, y: -1)

        func drops(_ list: [Droplet], _ argb: UInt32) {
            for d in list {
                ctx.saveGState()
                ctx.translateBy(x: radius + d.x * radius, y: radius + d.y * radius)
                ctx.rotate(by: d.rot)
                ctx.setFillColor(cgColor(argb, alpha: d.alpha))
                ctx.fillEllipse(in: CGRect(x: -d.rx * radius, y: -d.ry * radius, width: 2 * d.rx * radius, height: 2 * d.ry * radius))
                ctx.restoreGState()
            }
        }

        switch look.finish {
        case .marble: break
        case .splatter: drops(WaxPattern.splatter(seed: look.seed), secondArgb)
        case .split:
            ctx.saveGState()
            ctx.translateBy(x: radius, y: radius)
            ctx.rotate(by: WaxPattern.splitAngle(seed: look.seed))
            ctx.setFillColor(cgColor(secondArgb))
            ctx.fill(CGRect(x: 0, y: -radius, width: radius, height: 2 * radius))
            ctx.restoreGState()
        case .galaxy: drops(WaxPattern.speckles(seed: look.seed), 0xFFFF_FFFF)
        case .glitter: drops(WaxPattern.flecks(seed: look.seed), silver)
        }
        return ctx.makeImage()
    }
}
