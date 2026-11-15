# Vinyl collection

A personal app to keep track of the physical records (vinyl and CD) someone owns or wants.

## Records

**Disc**:
One physical release (an album on vinyl or CD) as the user knows it: title, artist, year, format, rating, comment, Seen price, Paid price.
_Avoid_: Record, album, item

**Format**:
The physical medium of a Disc: vinyl or CD. Anything else (cassette, file, DVD) is out of scope.
_Avoid_: Media, type

**Collection**:
The Discs the user owns.
_Avoid_: Library, shelf

**Wishlist**:
The Discs the user wants but does not own yet.
_Avoid_: Wantlist

**Draft**:
A Disc being added or edited, not yet saved.

## Prices

All prices are in euros, typed by the user (never from the Catalog), and optional.

**Seen price**:
The price the user saw a Wishlist Disc at, kept as a reminder. Kept but hidden once the Disc moves to the Collection.
_Avoid_: Target price, wish price

**Paid price**:
What the user paid for a Disc in the Collection. Prefilled from the Seen price when the Disc moves from the Wishlist.
_Avoid_: Cost, value

**Collection value**:
The sum of the Paid prices of the Collection Discs that have one. Discs without a Paid price are counted apart, not as zero.
_Avoid_: Worth, total

## Profile

**Profile**:
The user's own screen: the Profile card, then the Collection value by Format.
_Avoid_: Stats, account

**Profile card**:
The brushed silver card at the top of the Profile: Profile name, Collection value and the number of Collection Discs. It tilts with the phone.
_Avoid_: Holo card, badge

**Profile name**:
The name the user types for the Profile card (24 characters at most). Optional; kept on the phone only.
_Avoid_: Username, handle

## Catalog

**Catalog**:
The outside knowledge of existing releases the app asks to prefill a Draft, by barcode or by text.
_Avoid_: Database, API, lookup

**Source**:
One provider the Catalog asks (Discogs, MusicBrainz). Sources are asked in a fixed order; the first one with an answer wins.
_Avoid_: Provider, backend

**Pressing**:
One of many releases of the same album in the same Format. The Catalog shows one Pressing per album and Format.
_Avoid_: Edition, variant
