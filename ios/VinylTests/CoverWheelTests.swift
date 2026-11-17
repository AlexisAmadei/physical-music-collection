import Foundation
import Testing
@testable import Vinyl

/// What Home's cover wheel shows: the Collection, newest first.
@MainActor
struct HomeDiscsTests {
    let app: AppModel

    init() throws {
        app = try AppModel(container: DiscStore.inMemoryContainer())
    }

    func add(_ title: String, artist: String = "Artist", wishlist: Bool = false, day: Int) {
        app.newDraft(wishlist: wishlist)
        app.draft.title = title
        app.draft.artist = artist
        app.draft.addedAt = Date(timeIntervalSinceReferenceDate: Double(day) * 86_400)
        app.saveDraft()
    }

    @Test func homeShowsTheCollectionNewestAddedFirstWithoutTheWishlist() {
        add("Old", artist: "A", day: 1)
        add("Wanted", wishlist: true, day: 4)
        add("New", artist: "B", day: 3)
        add("Mid", artist: "C", day: 2)

        #expect(app.homeDiscs.map(\.title) == ["New", "Mid", "Old"])
    }

    @Test func homeIgnoresTheCollectionScreensFilterAndSort() {
        add("CD", day: 1)
        add("Vinyl", day: 2)
        app.collectionFilter.format = .cd
        app.collectionFilter.sort = .year

        #expect(app.homeDiscs.map(\.title) == ["Vinyl", "CD"])
    }
}

/// The wheel as an endless tape: ten cards around the front, each showing Disc `k mod n`.
struct WheelTapeTests {
    @Test func atRestTheFrontCardIsTheNewestDisc() {
        let wheel = WheelMotion()
        #expect(wheel.front == 0)
        #expect(wheel.disc(atCard: wheel.front, count: 3) == 0)
    }

    @Test func turningTheWheelUpOneCardBringsTheNextDiscToTheFront() {
        var wheel = WheelMotion()
        wheel.angle = -36
        #expect(wheel.front == 1)
        wheel.angle = -53 // past half a card still rounds to the nearer card
        #expect(wheel.front == 1)
        wheel.angle = -55
        #expect(wheel.front == 2)
    }

    @Test func theTapeWrapsSoTheOldestDiscSitsJustBeforeTheNewest() {
        let wheel = WheelMotion()
        #expect(wheel.disc(atCard: -1, count: 3) == 2)
        #expect(wheel.disc(atCard: 3, count: 3) == 0)
        #expect(wheel.disc(atCard: -7, count: 3) == 2)
    }

    @Test func onlyTheTenCardsAroundTheFrontAreDrawn() {
        var wheel = WheelMotion()
        wheel.angle = -36 * 250
        #expect(wheel.cards == 245..<255)
    }
}

/// The position indicator: how far through the Collection the front Disc is, 0 (newest) to 1 (oldest).
struct WheelIndicatorTests {
    @Test func theNewestDiscIsAtTheTopAndTheOldestAtTheBottom() {
        #expect(WheelMotion.indicator(front: 0, count: 5) == 0)
        #expect(WheelMotion.indicator(front: 2, count: 5) == 0.5)
        #expect(WheelMotion.indicator(front: 4, count: 5) == 1)
    }

    @Test func itFollowsTheTapeAroundBothWays() {
        #expect(WheelMotion.indicator(front: -1, count: 5) == 1)
        #expect(WheelMotion.indicator(front: 6, count: 5) == 0.25)
        #expect(WheelMotion.indicator(front: 251, count: 201) == 0.25)
    }

    @Test func aSingleDiscKeepsTheThumbAtTheTop() {
        #expect(WheelMotion.indicator(front: 0, count: 1) == 0)
        #expect(WheelMotion.indicator(front: 3, count: 1) == 0)
    }
}

/// Runs the wheel frame by frame at 60 fps.
func run(_ wheel: inout WheelMotion, seconds: Double, canDrift: Bool = false) {
    for _ in 0..<Int(seconds * 60) { wheel.tick(dt: 1.0 / 60, canDrift: canDrift) }
}

/// Dragging and flinging the wheel.
struct WheelDragTests {
    @Test func theWheelFollowsTheFingerThenSettlesOnTheNearestCard() {
        var wheel = WheelMotion()
        wheel.startDrag()
        wheel.drag(byDegrees: -50)
        #expect(wheel.angle == -50)
        wheel.endDrag(degreesPerSecond: 0)
        run(&wheel, seconds: 2)

        #expect(wheel.angle == -36)
        #expect(wheel.front == 1)
        #expect(wheel.isSettled)
    }

    @Test func aFlingCarriesTheWheelAQuarterSecondFurtherAndLandsOnACard() {
        var wheel = WheelMotion()
        wheel.startDrag()
        wheel.endDrag(degreesPerSecond: -400) // -100°, nearest card -108°
        #expect(!wheel.isSettled)
        run(&wheel, seconds: 3)

        #expect(wheel.angle == -108)
        #expect(wheel.front == 3)
    }

    @Test func aWildFlingIsCappedAtOneTurn() {
        var wheel = WheelMotion()
        wheel.startDrag()
        wheel.endDrag(degreesPerSecond: -100_000) // capped at 1400°/s, so -350°, nearest card -360°
        run(&wheel, seconds: 3)

        #expect(wheel.front == 10)
    }

    @Test func theWheelStaysUnderTheFingerWhileDragging() {
        var wheel = WheelMotion()
        wheel.startDrag()
        wheel.drag(byDegrees: -10)
        run(&wheel, seconds: 1, canDrift: true)

        #expect(wheel.angle == -10)
    }
}

/// "Disque suivant", "Disque précédent" and tapping a card.
struct WheelStepTests {
    @Test func nextAndPreviousMoveOneCardAndAddUpWhenRepeatedQuickly() {
        var wheel = WheelMotion()
        wheel.step(by: 1)
        run(&wheel, seconds: 0.1)
        wheel.step(by: 1)
        run(&wheel, seconds: 3)
        #expect(wheel.front == 2)

        wheel.step(by: -1)
        run(&wheel, seconds: 3)
        #expect(wheel.front == 1)
    }

    @Test func previousFromTheNewestDiscShowsTheOldest() {
        var wheel = WheelMotion()
        wheel.step(by: -1)
        run(&wheel, seconds: 3)
        #expect(wheel.disc(atCard: wheel.front, count: 4) == 3)
    }

    @Test func aStepKnowsAtOnceWhichCardItWillLandOn() {
        var wheel = WheelMotion()
        #expect(wheel.heading == 0)
        wheel.step(by: 1)
        wheel.step(by: 1)
        #expect(wheel.front == 0)
        #expect(wheel.heading == 2)
        run(&wheel, seconds: 3)
        #expect(wheel.heading == 2)
    }

    @Test func eachCardSitsOneTenthOfATurnFromTheNext() {
        var wheel = WheelMotion()
        wheel.angle = -36
        #expect(wheel.theta(card: 1) == 0)
        #expect(wheel.theta(card: 2) == 36)
        #expect(wheel.theta(card: 0) == -36)
    }

    @Test func tappingACardTurnsItToTheFront() {
        var wheel = WheelMotion()
        wheel.focus(card: -2)
        run(&wheel, seconds: 3)
        #expect(wheel.front == -2)
        #expect(wheel.isSettled)
    }
}

/// Where a card sits on the wheel: 200 pt cards, 20 pt apart, on a radius of about 356 pt.
struct WheelPlacementTests {
    @Test func theFrontCardIsCentredFullSizeUnveiledAndOnTop() {
        let p = WheelPlacement(theta: 0)
        #expect(p.offsetY == 0)
        #expect(p.scale == 1)
        #expect(p.veil == 0)
        #expect(p.depth == 1)
    }

    @Test func theNextCardSitsBelowTheFrontOne() {
        let p = WheelPlacement(theta: 36)
        #expect(abs(p.offsetY - 209.23) < 0.01)
        #expect(abs(p.scale - 0.9363) < 0.0001)
        #expect(abs(p.veil - 0.0292) < 0.0001)
        #expect(p.depth < 1)
    }

    @Test func aCardAQuarterTurnAwayIsSmallerAndHalfVeiled() {
        let p = WheelPlacement(theta: -90)
        #expect(abs(p.offsetY - -355.97) < 0.01)
        #expect(abs(p.scale - 0.7375) < 0.0001)
        #expect(abs(p.veil - 0.2313) < 0.0001)
    }

    @Test func theCardAtTheBackIsTheMostVeiledAndBehindTheOthers() {
        let p = WheelPlacement(theta: 180)
        #expect(abs(p.veil - 0.55) < 0.0001)
        #expect(p.depth == -1)
    }
}

/// The idle wheel drifts slowly upwards, and pauses after the user touches it.
struct WheelDriftTests {
    @Test func anIdleWheelDriftsUpTenDegreesASecond() {
        var wheel = WheelMotion()
        run(&wheel, seconds: 1, canDrift: true)
        #expect(abs(wheel.angle - -10) < 0.001)
    }

    @Test func whenDriftStopsTheWheelSettlesOnTheNearestCard() {
        var wheel = WheelMotion()
        run(&wheel, seconds: 2.5, canDrift: true) // -25°: nearer the second card
        run(&wheel, seconds: 3)
        #expect(wheel.angle == -36)
    }

    @Test func aTapPausesTheDriftForTwoPointEightSeconds() {
        var wheel = WheelMotion()
        wheel.focus(card: 0)
        run(&wheel, seconds: 2.7, canDrift: true)
        #expect(wheel.angle == 0)
        run(&wheel, seconds: 0.5, canDrift: true)
        #expect(wheel.angle < 0)
    }

    @Test func aTouchOrADragPausesTheDriftForTwoAndAHalfSecondsAfterTheFingerLifts() {
        var touched = WheelMotion()
        touched.touchEnded()
        run(&touched, seconds: 2.4, canDrift: true)
        #expect(touched.angle == 0)
        run(&touched, seconds: 0.3, canDrift: true)
        #expect(touched.angle < 0)

        var dragged = WheelMotion()
        dragged.startDrag()
        dragged.endDrag(degreesPerSecond: 0)
        run(&dragged, seconds: 2.4, canDrift: true)
        #expect(dragged.angle == 0)
    }
}
