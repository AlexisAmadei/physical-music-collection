import Testing
@testable import Vinyl

/// The open sleeve on Home: when it opens and closes, and when the wheel holds still
/// (Android `FlipState` and the tap rules in `ui/Wheel.kt`).
struct SleeveMotionTests {
    /// Runs `seconds` of screen frames at 60 Hz.
    func run(_ sleeve: inout SleeveMotion, _ seconds: Double) {
        for _ in 0..<Int((seconds * 60).rounded()) { sleeve.tick(dt: 1.0 / 60) }
    }

    @Test func tappingTheFrontCardOpensItsSleeveAndHoldsTheWheel() {
        var sleeve = SleeveMotion()

        let turns = sleeve.tap(card: 3, front: 3)

        #expect(sleeve.card == 3)
        #expect(sleeve.holding)
        #expect(turns) // the wheel settles exactly on it
    }

    @Test func tappingTheOpenSleeveClosesItAndLetsTheWheelGoAtOnce() {
        var sleeve = SleeveMotion()
        sleeve.tap(card: 3, front: 3)
        run(&sleeve, 2)

        let turns = sleeve.tap(card: 3, front: 3)

        #expect(!turns)
        #expect(!sleeve.holding)
        #expect(sleeve.card == 3) // still shutting, on its card
        run(&sleeve, 2)
        #expect(sleeve.card == nil)
        #expect(sleeve.rotation == 0)
    }

    @Test func tappingAnotherCardWhileOpenClosesTheSleeveAndTurnsToThatCard() {
        var sleeve = SleeveMotion()
        sleeve.tap(card: 3, front: 3)
        run(&sleeve, 2)

        let turns = sleeve.tap(card: 5, front: 3)

        #expect(turns)
        #expect(!sleeve.holding)
    }

    @Test func tappingACardBehindTheFrontOnlyTurnsTheWheel() {
        var sleeve = SleeveMotion()

        let turns = sleeve.tap(card: 5, front: 3)

        #expect(turns)
        #expect(sleeve.card == nil)
        #expect(!sleeve.holding)
    }

    @Test func theVinylComesOutOnlyOnceTheSleeveFacesBackwards() {
        var sleeve = SleeveMotion()
        sleeve.open(card: 0)
        var highest = 0.0

        for _ in 0..<60 {
            sleeve.tick(dt: 1.0 / 60)
            highest = max(highest, sleeve.rotation)
            if sleeve.rotation < 180 { #expect(!sleeve.discVisible) }
        }

        #expect(sleeve.discVisible)
        // A light overshoot: cubic-bezier(.3, 1.45, .55, 1) peaks near 1.067, about 192°.
        #expect(highest > 188 && highest < 195)
    }

    @Test func theVinylSlidesAllTheWayOutThenSpins() {
        var sleeve = SleeveMotion()
        sleeve.open(card: 0)

        run(&sleeve, 0.5)
        #expect(!sleeve.spinning)
        run(&sleeve, 1.5)

        #expect(sleeve.rotation == 180)
        #expect(sleeve.slide == 1)
        #expect(sleeve.spinning)
        let spin = sleeve.spin
        run(&sleeve, 0.5)
        #expect(abs(sleeve.spin - (spin + 100)) < 0.001) // one turn in 1.8 s
    }

    @Test func closingTucksTheVinylInBeforeTheSleeveTurns() {
        var sleeve = SleeveMotion()
        sleeve.open(card: 0)
        run(&sleeve, 2)

        sleeve.close()
        #expect(!sleeve.spinning)
        run(&sleeve, 0.2)
        #expect(sleeve.rotation == 180)
        #expect(sleeve.discVisible)
        run(&sleeve, 0.2)
        #expect(!sleeve.discVisible)
        #expect(sleeve.rotation < 180)
    }

    @Test func withReduceMotionTheSleeveOpensAndClosesAtOnce() {
        var sleeve = SleeveMotion()

        sleeve.tap(card: 2, front: 2, reduceMotion: true)
        #expect(sleeve.rotation == 180)
        #expect(sleeve.discVisible)
        #expect(sleeve.slide == 1)

        sleeve.tap(card: 2, front: 2, reduceMotion: true)
        #expect(sleeve.card == nil)
        #expect(sleeve.rotation == 0)
        #expect(!sleeve.discVisible)
    }

    @Test func reopeningAClosingSleevePicksUpWhereItIs() {
        var sleeve = SleeveMotion()
        sleeve.open(card: 1)
        run(&sleeve, 2)
        sleeve.close()
        run(&sleeve, 0.5) // vinyl in, sleeve turning back
        let turning = sleeve.rotation
        #expect(turning > 0 && turning < 180)

        sleeve.tap(card: 1, front: 1)
        #expect(sleeve.holding)
        sleeve.tick(dt: 1.0 / 60)
        #expect(sleeve.rotation > turning)
        run(&sleeve, 2)
        #expect(sleeve.rotation == 180)
        #expect(sleeve.slide == 1)
    }

    @Test func openingAnotherCardShutsTheClosingSleeveAtOnce() {
        var sleeve = SleeveMotion()
        sleeve.open(card: 1)
        run(&sleeve, 2)
        sleeve.close()
        run(&sleeve, 0.1)

        sleeve.open(card: 2)

        #expect(sleeve.card == 2)
        #expect(sleeve.rotation == 0)
        #expect(!sleeve.discVisible)
    }

    @Test func closingWithNoOpenSleeveDoesNothing() {
        var sleeve = SleeveMotion()

        sleeve.close()

        #expect(sleeve == SleeveMotion())
    }
}
