# Privacy Policy

**App:** Vinyl (Android: `com.kiwidev.physical`, and iOS)
**Developer:** Kiwidev
**Last updated:** 22 November 2026

Vinyl is a personal app to keep track of the vinyl records and CDs you own or want. This policy explains what data the app handles and where it goes.

**In short:** your collection stays on your phone. There is no account, no analytics, no advertising and no tracking. The app only contacts public music databases to look up releases.

## Data stored on your device

Everything you enter is stored locally on your phone and is never sent to the developer or to any server operated by the developer:

- Your discs: title, artist, year, format, barcode, vinyl color, speed, rating and comment
- Your Collection and Wishlist, with the Seen price and Paid price you type in
- Your Profile name (optional)
- Your chosen Language

The developer has no access to this data. Deleting the app deletes it.

**Device backups:** your phone's operating system may include the app's data in its own backups (for example Android Backup to your Google account, or iCloud Backup on iOS), depending on your device settings. That is handled by Google or Apple under their own policies and is not controlled by the app.

## Camera

The app asks for camera access only to scan the barcode of a disc. Camera images are processed on your device to read the barcode. They are not saved and not sent anywhere. You can refuse the permission and still use the app by typing a search instead.

## Network requests to third-party catalogs

To prefill a disc when you search or scan, the app queries these public music databases, in this order, and uses the first one that answers:

| Service | What is sent | Their policy |
| --- | --- | --- |
| [Discogs](https://www.discogs.com) (`api.discogs.com`) | The barcode or the text you searched for | https://www.discogs.com/privacy |
| [MusicBrainz](https://musicbrainz.org) (`musicbrainz.org`) | The barcode or the text you searched for | https://metabrainz.org/privacy |
| [Cover Art Archive](https://coverartarchive.org) | A request to download a cover image | https://metabrainz.org/privacy |

When the app contacts these services, they receive your IP address and the technical information any web request carries (such as the app's name in the user agent), along with the barcode or search text. The app does not send your Collection, your Wishlist, your prices, your Profile name or any identifier that links the request to you. Cover images may also be downloaded from the image servers the catalogs point to.

These requests happen only when you search or scan. Browsing your own Collection and Wishlist works offline.

## What the app does not do

- No account or sign-in
- No analytics, crash reporting or usage statistics
- No advertising and no ad identifiers
- No tracking across apps or websites
- No sale or sharing of personal data
- No access to your contacts, location, microphone or photos

## Children

The app is not directed at children and does not knowingly collect personal data from anyone.

## Your rights

Because the developer does not collect or hold any of your data, there is nothing to access, correct or delete on a server. You control your data on your device: edit or delete any disc in the app, or delete the app to remove everything stored locally.

## Changes to this policy

If the app's data practices change, this policy will be updated and the date above will change. The history of this file is available in the repository.

## Contact

For any question about this policy, open an issue at https://github.com/AlexisAmadei/physical-vinyle-collection/issues.
