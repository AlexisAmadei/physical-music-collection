import Testing
@testable import Vinyl

/// Profile name rules (port of the Android `ProfileName`) and the Profile through the app model.
@MainActor
struct ProfileTests {
    let preferences = InMemoryProfilePreferences()
    let app: AppModel

    init() throws {
        app = try AppModel(container: DiscStore.inMemoryContainer(), profilePreferences: preferences)
    }

    @Test func profileNameIsTrimmedAndCutTo24Characters() {
        #expect(ProfileName.clean("  Alexis  ") == "Alexis")
        #expect(ProfileName.clean("Jean-Baptiste de la Fontaine") == "Jean-Baptiste de la Font")
        #expect(ProfileName.clean(" \n ") == "")
        // Cut, then trimmed again: the cut leaves no trailing space.
        #expect(ProfileName.clean("Jean-Baptiste de la      Fontaine") == "Jean-Baptiste de la")
    }

    @Test func profileNameIsUnsetUntilTyped() {
        #expect(app.profileName == "")
    }

    @Test func setNameKeepsTheCleanNameInPreferences() throws {
        app.setProfileName("  Alexis ")

        #expect(app.profileName == "Alexis")
        let reopened = try AppModel(container: DiscStore.inMemoryContainer(), profilePreferences: preferences)
        #expect(reopened.profileName == "Alexis")
    }

    @Test func blankNameUnsetsIt() throws {
        app.setProfileName("Alexis")
        app.setProfileName("   ")

        #expect(app.profileName == "")
        #expect(preferences.name == nil)
        let reopened = try AppModel(container: DiscStore.inMemoryContainer(), profilePreferences: preferences)
        #expect(reopened.profileName == "")
    }

    @Test func collectionValueUpdatesAfterASave() throws {
        #expect(app.collectionValue == CollectionValue(total: 0, cd: 0, vinyl: 0, unpriced: 0))

        app.newDraft()
        app.draft.title = "Kid A"
        app.draft.format = .cd
        app.draft.priceText = "12,50"
        app.saveDraft()
        app.newDraft()
        app.draft.title = "Discovery"
        app.saveDraft()
        app.newDraft(wishlist: true)
        app.draft.title = "Homogenic"
        app.draft.priceText = "30"
        app.saveDraft()

        #expect(app.collectionValue == CollectionValue(total: 1250, cd: 1250, vinyl: 0, unpriced: 1))

        let discovery = try #require(app.collection.first { $0.title == "Discovery" })
        app.edit(discovery)
        app.draft.priceText = "25"
        app.saveDraft()

        #expect(app.collectionValue == CollectionValue(total: 3750, cd: 1250, vinyl: 2500, unpriced: 0))
    }
}
