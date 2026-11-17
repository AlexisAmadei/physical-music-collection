import QuartzCore
import SwiftUI

/// Home carousel: Collection covers on a vertical 3D wheel, newest first, front card centred on the screen
/// (Android `CoverWheel` in `ui/Wheel.kt`). The position logic is `WheelMotion`; where a card sits is `WheelPlacement`.
struct CoverWheel: View {
    /// The Collection, newest first (`AppModel.homeDiscs`). Never empty: Home shows the empty state instead.
    let discs: [Disc]
    /// The pencil on an open sleeve: opens that Disc's Draft.
    let onEdit: (Disc) -> Void

    @State private var driver = WheelDriver()
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.accessibilityVoiceOverEnabled) private var voiceOver

    var body: some View {
        GeometryReader { proxy in
            let size = proxy.size
            ZStack(alignment: .topLeading) {
                cards(in: size)
                    .frame(width: max(0, size.width - 72), height: size.height, alignment: .topLeading) // stop before the nav pill
                    .clipped()
                    .mask { FadeEdges(height: size.height) }
                    .contentShape(Rectangle())
                    .simultaneousGesture(drag)
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel("Ma collection")
                    .accessibilityValue(Text(verbatim: discs[driver.motion.discIndex(atCard: driver.motion.front, count: discs.count)].coverLabel))
                    .accessibilityAction(named: "Disque suivant") { step(by: 1) }
                    .accessibilityAction(named: "Disque précédent") { step(by: -1) }
                    .accessibilityAction(named: "Retourner") { tap(driver.motion.front) }
                    .accessibilityActions {
                        if let disc = openDisc {
                            Button("Modifier le disque") { onEdit(disc) }
                        }
                    }
                    .accessibilityAdjustableAction { direction in
                        switch direction {
                        case .increment: step(by: 1)
                        case .decrement: step(by: -1)
                        @unknown default: break
                        }
                    }
                PositionIndicator(fraction: WheelMotion.indicator(front: driver.motion.front, count: discs.count))
                    .offset(x: size.width - 79.5, y: size.height / 2 - 51.5)
                    .accessibilityHidden(true)
            }
        }
        .ignoresSafeArea()
        .onAppear { driver.start() }
        .onDisappear { driver.stop() }
        .onChange(of: reduceMotion || voiceOver, initial: true) { _, still in
            // No idle drift with Reduce Motion, nor under VoiceOver (it would keep changing the Disc being read).
            driver.driftAllowed = !still
        }
    }

    /// The ten cards around the front, drawn back to front.
    private func cards(in size: CGSize) -> some View {
        let motion = driver.motion
        return ZStack {
            ForEach(motion.cards, id: \.self) { k in
                let place = WheelPlacement(theta: motion.theta(card: k))
                let disc = discs[motion.discIndex(atCard: k, count: discs.count)]
                card(k, disc: disc, veil: place.veil)
                    .modifier(WheelTilt(degrees: -place.theta))
                    .scaleEffect(place.scale)
                    .position(x: size.width / 2, y: size.height / 2 + place.offsetY)
                    .onTapGesture { tap(k) }
                    .zIndex(place.depth) // last: the ZStack only sees its direct children's zIndex
            }
        }
    }

    /// The open sleeve stays on its card, so it rides along when the wheel turns.
    @ViewBuilder private func card(_ k: Int, disc: Disc, veil: Double) -> some View {
        if driver.sleeve.card == k {
            SleeveView(disc: disc, sleeve: driver.sleeve, veil: veil) { onEdit(disc) }
        } else {
            WheelCard(disc: disc, veil: veil)
        }
    }

    /// The Disc whose sleeve is open (not closing), if any.
    private var openDisc: Disc? {
        guard driver.sleeve.holding, let k = driver.sleeve.card else { return nil }
        return discs[driver.motion.discIndex(atCard: k, count: discs.count)]
    }

    /// Tapping the front card flips its sleeve open; tapping the open sleeve closes it. Any other card turns
    /// to the front, closing an open sleeve on the way (closing never blocks the wheel).
    private func tap(_ k: Int) {
        if driver.sleeve.tap(card: k, front: driver.motion.front, reduceMotion: reduceMotion) {
            driver.motion.focus(card: k)
        }
    }

    private func step(by cards: Int) {
        driver.sleeve.close()
        driver.motion.step(by: cards)
        let disc = discs[driver.motion.discIndex(atCard: driver.motion.heading, count: discs.count)]
        AccessibilityNotification.Announcement(disc.coverLabel).post()
    }

    /// One finger: any touch pauses the drift; a vertical move turns the wheel; lifting flings it.
    private var drag: some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { value in
                driver.touching = true
                let dy = value.translation.height - driver.lastDragY
                if !driver.motion.dragging {
                    guard abs(value.translation.height) > 10 else { return }
                    driver.sleeve.close()
                    driver.motion.startDrag()
                    driver.lastDragY = value.translation.height
                    return
                }
                driver.lastDragY = value.translation.height
                driver.motion.drag(byDegrees: dy * Self.degreesPerPoint)
            }
            .onEnded { value in
                driver.touching = false
                driver.lastDragY = 0
                if driver.motion.dragging {
                    driver.motion.endDrag(degreesPerSecond: value.velocity.height * Self.degreesPerPoint)
                } else {
                    driver.motion.touchEnded()
                }
            }
    }

    /// A finger moving this many points turns the wheel one degree at its rim.
    private static let degreesPerPoint = 180 / (Double.pi * WheelPlacement.radius)
}

/// One cover on the wheel, veiled in white towards the back.
/// An open sleeve's card is a `SleeveView` instead.
struct WheelCard: View {
    let disc: Disc
    let veil: Double

    var body: some View {
        Cover(url: disc.coverURL)
            .colorSticker(disc.shownVinylColor)
            .overlay(Color.white.opacity(veil))
            .frame(width: WheelPlacement.card, height: WheelPlacement.card)
            .background(Color.white.shadow(.drop(color: .black.opacity(0.25), radius: 5, y: 2)))
            .contentShape(Rectangle())
    }
}

/// Tilts a card about its horizontal axis, with a camera `WheelPlacement.perspective` points away (Android `rotationX`).
struct WheelTilt: GeometryEffect {
    var degrees: Double

    func effectValue(size: CGSize) -> ProjectionTransform {
        var camera = CATransform3DIdentity
        camera.m34 = -1 / WheelPlacement.perspective
        let tilt = CATransform3DMakeRotation(degrees * .pi / 180, 1, 0, 0)
        let toCentre = CATransform3DMakeTranslation(-size.width / 2, -size.height / 2, 0)
        let back = CATransform3DMakeTranslation(size.width / 2, size.height / 2, 0)
        // Applied left to right: centre on the origin, tilt, then project, then put back.
        let steps = [toCentre, tilt, camera, back]
        return ProjectionTransform(steps.dropFirst().reduce(steps[0], CATransform3DConcat))
    }
}

/// Vertical fade: clear for 56 pt then opaque at 120 pt from the top, mirrored 65 → 117 pt from the bottom.
private struct FadeEdges: View {
    let height: CGFloat

    var body: some View {
        let top = { (pt: CGFloat) in min(max(pt / height, 0), 1) }
        let bottom = { (pt: CGFloat) in min(max(1 - pt / height, 0), 1) }
        LinearGradient(
            stops: [
                .init(color: .clear, location: 0), .init(color: .clear, location: top(56)),
                .init(color: .black, location: top(120)), .init(color: .black, location: bottom(117)),
                .init(color: .clear, location: bottom(65)), .init(color: .clear, location: 1),
            ],
            startPoint: .top, endPoint: .bottom
        )
    }
}

/// A thin track with a thumb showing how far through the Collection the front Disc is.
private struct PositionIndicator: View {
    /// 0 = newest Disc, 1 = oldest.
    let fraction: Double

    var body: some View {
        RoundedRectangle(cornerRadius: 2)
            .fill(Palette.line)
            .frame(width: 3, height: 103)
            .overlay(alignment: .top) {
                RoundedRectangle(cornerRadius: 2)
                    .fill(Palette.thumb)
                    .frame(width: 3, height: 44)
                    .offset(y: fraction * 59)
            }
    }
}

/// Runs `WheelMotion` once per screen frame.
@MainActor
@Observable
final class WheelDriver: NSObject {
    var motion = WheelMotion()
    /// The open sleeve, if any.
    var sleeve = SleeveMotion()
    /// A finger is down on the wheel: no drift.
    @ObservationIgnored var touching = false
    /// Reduce Motion or VoiceOver turn the idle drift off.
    @ObservationIgnored var driftAllowed = true
    /// Holds the wheel still (no drift) while a sleeve is open.
    var frozen: Bool { sleeve.holding }
    /// The drag's last vertical translation, points.
    @ObservationIgnored var lastDragY: CGFloat = 0

    @ObservationIgnored private var link: CADisplayLink?
    @ObservationIgnored private var last: CFTimeInterval = 0

    func start() {
        guard link == nil else { return }
        last = 0
        let link = CADisplayLink(target: self, selector: #selector(frame(_:)))
        link.add(to: .main, forMode: .common)
        self.link = link
    }

    func stop() {
        link?.invalidate()
        link = nil
    }

    @objc private func frame(_ link: CADisplayLink) {
        let dt = last == 0 ? 1.0 / 60 : link.timestamp - last
        last = link.timestamp
        var next = motion
        next.tick(dt: dt, canDrift: driftAllowed && !frozen && !touching)
        if next != motion { motion = next } // a still wheel redraws nothing
        var nextSleeve = sleeve
        nextSleeve.tick(dt: dt)
        if nextSleeve != sleeve { sleeve = nextSleeve }
    }
}
