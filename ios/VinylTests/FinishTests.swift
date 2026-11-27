import Testing
@testable import Vinyl

/// Port of the Android `FinishTest`, same cases.
@MainActor
struct FinishTests {
    var red: Draft { Draft(format: .vinyl, vinylColor: .red) }

    @Test func marbleSplatterSplitAndGalaxyUseASecondColorButGlitterDoesNot() {
        #expect(Set(Finish.allCases.filter(\.usesSecondColor)) == [.marble, .splatter, .split, .galaxy])
        #expect(!Finish.glitter.usesSecondColor)
    }

    @Test func secondColorStartsAsWhiteAndBlackForSplit() {
        #expect(Finish.marble.defaultSecondColor == .white)
        #expect(Finish.splatter.defaultSecondColor == .white)
        #expect(Finish.galaxy.defaultSecondColor == .white)
        #expect(Finish.split.defaultSecondColor == .black)
        #expect(Finish.glitter.defaultSecondColor == nil)
    }

    @Test func finishesKeepTheAndroidOrderAndStoredNames() {
        #expect(Finish.allCases.map(\.rawValue) == ["MARBLE", "SPLATTER", "SPLIT", "GALAXY", "GLITTER"])
    }

    @Test func aDiscIsSolidWhenNoFinishIsSet() {
        let disc = Disc(red)
        #expect(disc.shownFinish == nil)
        #expect(disc.shownSecondColor == nil)
        #expect(Disc(Draft()).finish == nil)
        #expect(Disc(Draft()).secondColor == nil)
    }

    @Test func pickingAFinishThatUsesASecondColorPreselectsIt() {
        var draft = red
        draft.pickFinish(.marble)
        #expect(draft.secondColor == .white)
        draft.pickFinish(.split)
        #expect(draft.secondColor == .white) // already set, kept
        var split = red
        split.pickFinish(.split)
        #expect(split.secondColor == .black)
        var glitter = red
        glitter.pickFinish(.glitter)
        #expect(glitter.secondColor == nil)
    }

    @Test func pickingAFinishKeepsASecondColorAlreadyChosen() {
        var draft = red
        draft.pickFinish(.marble)
        draft.secondColor = .black
        draft.pickFinish(.splatter)
        #expect(draft.secondColor == .black)
    }

    @Test func goingBackToSolidKeepsTheSecondColorHiddenAndItComesBackWithTheNextFinish() {
        var draft = red
        draft.pickFinish(.marble)
        draft.secondColor = .teal
        draft.pickFinish(nil)
        #expect(draft.finish == nil)
        #expect(draft.secondColor == .teal)
        #expect(draft.shownSecondColor == nil)
        draft.pickFinish(.galaxy)
        #expect(draft.shownSecondColor == .teal)
    }

    @Test func glitterHidesAKeptSecondColor() {
        var draft = red
        draft.pickFinish(.marble)
        draft.secondColor = .teal
        draft.pickFinish(.glitter)
        #expect(draft.secondColor == .teal)
        #expect(draft.shownSecondColor == nil)
    }

    @Test func turningTheVinylColorOffClearsTheFinishAndTheSecondColor() {
        var draft = red
        draft.pickFinish(.marble)
        draft.coloredVinyl = false
        #expect(draft.vinylColor == nil)
        #expect(draft.finish == nil)
        #expect(draft.secondColor == nil)
    }

    @Test func pickingAnotherVinylColorKeepsTheFinishAndTheSecondColor() {
        var draft = red
        draft.pickFinish(.splatter)
        draft.secondColor = .gold
        draft.vinylColor = .blue
        #expect(draft.finish == .splatter)
        #expect(draft.secondColor == .gold)
    }

    @Test func aCDKeepsItsFinishAndSecondColorHiddenAndVinylShowsThemAgain() {
        var draft = red
        draft.pickFinish(.marble)
        draft.format = .cd
        #expect(draft.finish == .marble)
        #expect(draft.secondColor == .white)
        #expect(draft.shownFinish == nil)
        #expect(draft.shownSecondColor == nil)
        #expect(!Disc(draft).hasColorBand)
        #expect(Disc(draft).shownFinish == nil)

        draft.format = .vinyl
        #expect(draft.shownFinish == .marble)
        #expect(draft.shownSecondColor == .white)
        #expect(Disc(draft).shownFinish == .marble)
    }

    @Test func aFinishNeedsAVinylColorToShow() {
        // The form never builds this, but a stored Disc could: no Vinyl color means plain black wax.
        let orphan = Draft(format: .vinyl, finish: .marble, secondColor: .white)
        #expect(orphan.shownFinish == nil)
        #expect(orphan.shownSecondColor == nil)
        #expect(!orphan.showsFinishField)
        #expect(red.showsFinishField)
    }

    @Test func aFinishThatUsesASecondColorButHasNoneStoredShowsTheFinishDefault() {
        var draft = red
        draft.finish = .split
        draft.secondColor = nil
        #expect(draft.shownSecondColor == .black)
    }

    @Test func finishAndSecondColorSurviveSavingAndEditing() throws {
        let app = try AppModel.pinned()
        app.newDraft()
        app.draft.title = "Currents"
        app.draft.coloredVinyl = true
        app.draft.pickFinish(.splatter)
        app.draft.secondColor = .gold
        app.saveDraft()

        let saved = try #require(app.collection.first)
        #expect(saved.finish == .splatter)
        #expect(saved.secondColor == .gold)

        app.edit(saved)
        #expect(app.draft.finish == .splatter)
        #expect(app.draft.secondColor == .gold)
    }

    @Test func finishesAreNamedInBothLanguages() {
        let language = Language.pinned(.french)
        #expect(Finish.allCases.map { $0.label(in: language) } == ["Marbré", "Splatter", "Bicolore", "Galaxy", "Pailleté"])
        #expect((nil as Finish?).label(in: language) == "Unie")
        language.select(.english)
        #expect(Finish.allCases.map { $0.label(in: language) } == ["Marble", "Splatter", "Split", "Galaxy", "Glitter"])
        #expect((nil as Finish?).label(in: language) == "Solid")
    }
}
