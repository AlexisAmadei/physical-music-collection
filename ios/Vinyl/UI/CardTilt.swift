import QuartzCore
import SwiftUI
import UIKit

/// The Profile card's shown tilt, x and y in -1...1, once per screen frame (Android `ProfileCard` frame loop).
/// Eases toward the finger while it touches the card, else toward the phone tilt. Each time the card appears, the
/// intro starts lit from the top right and settles slowly (first 1.4 s).
@MainActor
@Observable
final class CardTiltDriver: NSObject {
    /// The intro starts lit from here (Android `IntroStart`).
    static let introStart = CGPoint(x: 0.62, y: -0.55)

    private(set) var shown = CardTiltDriver.introStart
    /// Finger position on the card as a tilt while it touches, else nil.
    @ObservationIgnored var finger: Tilt?

    @ObservationIgnored private var link: CADisplayLink?
    @ObservationIgnored private var started: CFTimeInterval = 0
    @ObservationIgnored private var last: CFTimeInterval = 0

    func start() {
        guard link == nil else { return }
        shown = Self.introStart
        started = 0
        HoloLight.shared.addReader()
        let link = CADisplayLink(target: self, selector: #selector(frame(_:)))
        link.add(to: .main, forMode: .common)
        self.link = link
    }

    func stop() {
        guard let link else { return }
        link.invalidate()
        self.link = nil
        finger = nil
        HoloLight.shared.removeReader()
    }

    @objc private func frame(_ link: CADisplayLink) {
        let now = link.timestamp
        guard started != 0 else {
            started = now
            last = now
            return
        }
        let dt = min(0.05, now - last)
        last = now
        let t = finger ?? HoloLight.shared.tilt
        let k = 1 - exp(-dt / (now - started < 1.4 ? 0.45 : 0.08))
        let next = CGPoint(x: shown.x + (t.x - shown.x) * k, y: shown.y + (t.y - shown.y) * k)
        // Still card: no write, so no redraw.
        if abs(next.x - shown.x) + abs(next.y - shown.y) > 1e-4 { shown = next }
    }
}

/// Reports the finger in window coordinates while it touches the view, then nil. Only watches: it never
/// recognizes and never prevents another gesture, so the card's tap and the screen's scroll work as before.
struct FingerWatcher: UIGestureRecognizerRepresentable {
    let onFinger: @MainActor (CGPoint?) -> Void

    func makeUIGestureRecognizer(context: Context) -> Recognizer {
        let r = Recognizer()
        r.cancelsTouchesInView = false
        r.delaysTouchesBegan = false
        r.delaysTouchesEnded = false
        return r
    }

    func updateUIGestureRecognizer(_ recognizer: Recognizer, context: Context) {
        recognizer.onFinger = onFinger
    }

    final class Recognizer: UIGestureRecognizer {
        var onFinger: (@MainActor (CGPoint?) -> Void)?
        private var touch: UITouch?

        override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent) {
            guard touch == nil, let first = touches.first else { return }
            touch = first
            onFinger?(first.location(in: nil))
        }

        override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent) {
            guard let touch, touches.contains(touch) else { return }
            onFinger?(touch.location(in: nil))
        }

        override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent) { lift(touches) }
        override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent) { lift(touches) }

        override func reset() {
            if touch != nil { onFinger?(nil) }
            touch = nil
        }

        override func canPrevent(_ preventedGestureRecognizer: UIGestureRecognizer) -> Bool { false }

        private func lift(_ touches: Set<UITouch>) {
            guard let touch, touches.contains(touch) else { return }
            self.touch = nil
            onFinger?(nil)
            state = .failed
        }
    }
}

extension Tilt {
    /// The finger at `point` on a card at `frame` (same coordinate space): -1 at the left / top edge, 1 at the
    /// right / bottom edge, clamped.
    init(finger point: CGPoint, on frame: CGRect) {
        func axis(_ v: CGFloat, _ min: CGFloat, _ size: CGFloat) -> Double {
            size > 0 ? Swift.min(1, Swift.max(-1, (v - min) / size * 2 - 1)) : 0
        }
        self.init(x: axis(point.x, frame.minX, frame.width), y: axis(point.y, frame.minY, frame.height))
    }
}
