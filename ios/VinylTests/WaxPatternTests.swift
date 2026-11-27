import CoreGraphics
import Foundation
import Testing
@testable import Vinyl

/// Port of the Android `WaxPatternTest`, same cases. The pinned values come from the Android run (and, for SplitMix64,
/// from the published reference), so the two platforms draw the same patterns.
struct WaxPatternTests {
    @Test func splitMix64MatchesTheReferenceSequence() {
        var r = WaxRandom(seed: 0)
        #expect(r.next() == 0xE220_A839_7B1D_CDAF)
        #expect(r.next() == 0x6E78_9E6A_A1B9_65F4)
        #expect(r.next() == 0x06C4_5D18_8009_454F)
    }

    @Test func unitIsInZeroToOne() {
        var r = WaxRandom(seed: 42)
        for _ in 0..<1000 {
            let u = r.unit()
            #expect(u >= 0 && u < 1)
        }
    }

    @Test func theSeedOfADiscIsStableAndDiffersBetweenDiscs() {
        let a = Date(timeIntervalSince1970: 1_700_000_000)
        let b = Date(timeIntervalSince1970: 1_700_000_000.001)
        #expect(WaxPattern.seed(addedAt: a) == WaxPattern.seed(addedAt: a))
        #expect(WaxPattern.seed(addedAt: a) != WaxPattern.seed(addedAt: b))
        // Editing a Disc keeps its pattern: nothing but addedAt feeds the seed.
        var draft = Draft(title: "x", vinylColor: .red)
        draft.addedAt = a
        #expect(Disc(draft).waxSeed == WaxPattern.seed(addedAt: a))
    }

    @Test func theSeedForAGivenTimeIsPinnedForCrossPlatformParity() {
        // 1_700_000_000_000 ms, as the Android test pins.
        #expect(WaxPattern.seed(addedAt: Date(timeIntervalSince1970: 1_700_000_000)) == 940_689_255_921_423_875)
    }

    @Test func splatterIsTheSameEveryTimeAndDiffersPerSeed() {
        #expect(WaxPattern.splatter(seed: 7) == WaxPattern.splatter(seed: 7))
        #expect(WaxPattern.splatter(seed: 7) != WaxPattern.splatter(seed: 8))
    }

    @Test func splatterThrowsABurstFromEachImpactPoint() {
        let drops = WaxPattern.splatter(seed: 7)
        // 4 to 6 impacts, each 5 to 8 core blobs and 90 to 159 droplets.
        #expect((4 * 95...6 * 167).contains(drops.count))
        #expect(drops.allSatisfy { $0.rx > 0 && $0.ry > 0 && $0.alpha >= 0.9 && $0.alpha <= 1.0 })
        #expect(drops.contains { $0.rx > $0.ry * 1.5 })
    }

    @Test func mostSplatterStaysOnTheDisc() {
        let drops = WaxPattern.splatter(seed: 123)
        let on = drops.filter { $0.x * $0.x + $0.y * $0.y <= 1.2 * 1.2 }.count
        #expect(Double(on) > Double(drops.count) * 0.85)
    }

    @Test func speckleAndFleckCountsAreFixed() {
        #expect(WaxPattern.speckles(seed: 1).count == 160)
        #expect(WaxPattern.flecks(seed: 1).count == 420)
        #expect(WaxPattern.speckles(seed: 1).allSatisfy { $0.x * $0.x + $0.y * $0.y <= 1.05 * 1.05 })
    }

    @Test func splitAngleIsWithinAFullTurn() {
        for seed in 0..<50 {
            let a = WaxPattern.splitAngle(seed: UInt64(seed))
            #expect(a >= 0 && a < 2 * Double.pi)
        }
    }

    @Test func marbleIsTheSameEveryTimeAndOpaqueOnSolidWax() {
        let a = WaxPattern.marble(seed: 9, base: .red, second: .black, size: 24)
        #expect(a.count == 24 * 24)
        #expect(a == WaxPattern.marble(seed: 9, base: .red, second: .black, size: 24))
        #expect(a.allSatisfy { $0 >> 24 == 255 })
    }

    @Test func marbleMixesBothColorsAndDiffersPerSeed() {
        let a = WaxPattern.marble(seed: 9, base: .red, second: .white, size: 48)
        let reds = a.filter { (($0 >> 16) & 0xFF) > 0xA0 && (($0 >> 8) & 0xFF) < 0x80 }.count
        let whites = a.filter { (($0 >> 8) & 0xFF) > 0xD0 }.count
        #expect(reds > 48 * 48 / 10 && whites > 48 * 48 / 10)
        #expect(a != WaxPattern.marble(seed: 10, base: .red, second: .white, size: 48))
    }

    @Test func marbleOnClearWaxIsSeeThroughWhereTheSecondColorIsAbsent() {
        let alphas = WaxPattern.marble(seed: 9, base: .clear, second: .red, size: 48).map { $0 >> 24 }
        #expect((0x8A...0x8E).contains(alphas.min() ?? 0))
        #expect((alphas.max() ?? 0) > 0xF0)
    }

    @Test func marblePixelsMatchAndroid() {
        // Golden values from the Android test, within 1 per channel: sin and exp may differ in the last bit.
        let p = WaxPattern.marble(seed: 0x1234_5678_9ABC, base: .blue, second: .white, size: 16)
        #expect(p.count == 256)
        let expected: [(Int, UInt32)] = [
            (0, 0xFFE7_E8E9), (17, 0xFFF3_F1ED), (100, 0xFFF3_F1ED), (135, 0xFF2B_5BA8), (255, 0xFF40_6AAF),
        ]
        for (index, want) in expected {
            for shift in [24, 16, 8, 0] as [UInt32] {
                let got = Int((p[index] >> shift) & 0xFF)
                let exp = Int((want >> shift) & 0xFF)
                #expect(abs(got - exp) <= 1, "pixel \(index), shift \(shift): \(got) vs \(exp)")
            }
        }
    }

    @Test func splatterMatchesAndroid() {
        let d = WaxPattern.splatter(seed: 0x1234_5678_9ABC)
        #expect(d.count == 514)
        #expect(abs(d[0].x - 0.18925281250478643) < 1e-9)
        #expect(abs(d[0].rx - 0.028500420131112356) < 1e-9)
        #expect(d[0].alpha == 0.97)
        #expect(abs(d[100].y - -0.9869534417692565) < 1e-9)
        #expect(abs(d[100].rot - 4.1255971454634714) < 1e-9)
        #expect(abs(d[d.count - 1].x - 0.4386496446218519) < 1e-9)
        #expect(abs(d[d.count - 1].ry - 0.020505143576469913) < 1e-9)
    }
}

/// The wax images: one per Finish, the right size, cached.
struct WaxRendererTests {
    func look(_ finish: Finish, base: VinylColor? = .red, second: VinylColor? = .white) -> WaxLook {
        WaxLook(base: base, finish: finish, second: second, seed: 3, side: 64, marbleSide: 16)
    }

    @Test func everyFinishRendersARoundImageOfTheAskedSize() throws {
        for finish in Finish.allCases {
            let image = try #require(WaxRenderer.image(look(finish)), "\(finish)")
            #expect(image.cgImage.width == 64 && image.cgImage.height == 64)
        }
    }

    @Test func theSameLookIsRenderedOnceAndFoundInTheCache() throws {
        let marble = look(.marble, second: .teal)
        _ = try #require(WaxRenderer.image(marble))
        #expect(WaxRenderer.cached(marble) != nil)
        #expect(WaxRenderer.cached(look(.marble, second: .gold)) == nil)
    }

    @Test func aRenderedImageIsOnlyDrawnForItsOwnLook() throws {
        let a = look(.splatter)
        let rendered: RenderedWax? = RenderedWax(look: a, image: try #require(WaxRenderer.image(a)).cgImage)
        #expect(rendered.image(for: a) != nil)
        #expect(rendered.image(for: nil) == nil)
        #expect(rendered.image(for: look(.splatter, base: .blue, second: .gold)) == nil)
    }

    @Test func aDiscShowsItsFinishInItsWax() {
        var draft = Draft(format: .vinyl, vinylColor: .red)
        draft.pickFinish(.marble)
        #expect(VinylWax(Disc(draft)).finish == .marble)
        #expect(VinylWax(Disc(draft)).look(side: 100)?.second == .white)

        draft.format = .cd
        #expect(VinylWax(Disc(draft)).finish == nil)
        #expect(VinylWax(Disc(draft)).look(side: 100) == nil)

        #expect(VinylWax(Disc(Draft(format: .vinyl, vinylColor: .red))).look(side: 100) == nil)
    }
}
