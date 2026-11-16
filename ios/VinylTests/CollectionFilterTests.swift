import Foundation
import Testing
@testable import Vinyl

/// The Collection screen's Format filter and sort, driven through the app model.
@MainActor
struct CollectionFilterTests {
    let app: AppModel

    init() throws {
        app = try AppModel(container: DiscStore.inMemoryContainer())
    }

    /// Saves a Collection Disc added `day` days after a fixed start.
    func add(_ title: String, year: Int? = nil, format: Format = .vinyl, day: Int) {
        app.newDraft()
        app.draft.title = title
        app.draft.artist = "Artist"
        app.draft.year = year
        app.draft.format = format
        app.draft.addedAt = Date(timeIntervalSinceReferenceDate: Double(day) * 86_400)
        app.saveDraft()
    }

    var shown: [String] { app.shownCollection.map(\.title) }

    @Test func byDefaultTheCollectionShowsEveryFormatNewestAddedFirst() {
        add("Old", format: .cd, day: 1)
        add("New", format: .vinyl, day: 3)
        add("Mid", format: .vinyl, day: 2)

        #expect(app.collectionFilter.format == nil)
        #expect(app.collectionFilter.sort == .added)
        #expect(shown == ["New", "Mid", "Old"])
    }

    @Test func theFormatFilterShowsOnlyThatFormatAndClearingItShowsAllAgain() {
        add("Debut", format: .cd, day: 1)
        add("Kid A", format: .vinyl, day: 2)
        add("Homogenic", format: .cd, day: 3)

        app.collectionFilter.format = .cd
        #expect(shown == ["Homogenic", "Debut"])

        app.collectionFilter.format = .vinyl
        #expect(shown == ["Kid A"])

        app.collectionFilter.format = nil
        #expect(shown == ["Homogenic", "Kid A", "Debut"])
    }

    @Test func tappingAFormatChipSelectsItAndTappingItAgainShowsEveryFormat() {
        add("Debut", format: .cd, day: 1)
        add("Kid A", format: .vinyl, day: 2)

        app.collectionFilter.toggle(.cd)
        #expect(shown == ["Debut"])

        app.collectionFilter.toggle(.vinyl)
        #expect(shown == ["Kid A"])

        app.collectionFilter.toggle(.vinyl)
        #expect(app.collectionFilter.format == nil)
        #expect(shown == ["Kid A", "Debut"])
    }

    @Test func sortingByYearPutsNewestYearFirstNoYearLastAndTiesByNewestAdded() {
        add("Undated old", day: 1)
        add("Kid A", year: 2000, day: 2)
        add("Pablo Honey", year: 1993, day: 3)
        add("Amnesiac", year: 2001, day: 4)
        add("Kid A again", year: 2000, day: 5)
        add("Undated new", day: 6)

        app.collectionFilter.sort = .year

        #expect(shown == ["Amnesiac", "Kid A again", "Kid A", "Pablo Honey", "Undated new", "Undated old"])
    }

    @Test func filterAndSortStaySetWhileDiscsAreAddedAndEdited() throws {
        add("Debut", year: 1993, format: .cd, day: 1)
        add("Kid A", year: 2000, format: .vinyl, day: 2)
        app.collectionFilter = CollectionFilter(format: .cd, sort: .year)

        add("Post", year: 1995, format: .cd, day: 3)
        app.edit(try #require(app.collection.first { $0.title == "Kid A" }))
        app.draft.format = .cd
        app.saveDraft()

        #expect(app.collectionFilter == CollectionFilter(format: .cd, sort: .year))
        #expect(shown == ["Kid A", "Post", "Debut"])
    }
}
