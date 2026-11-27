# Vinyl collection

A personal app to keep track of the physical records (vinyl and CD) someone owns or wants.

## Records

**Disc**:
One physical release (an album on vinyl or CD) as the user knows it: title, artist, year, format, Speed, rating, comment, Seen price, Paid price.
_Avoid_: Record, album, item

**Format**:
The physical medium of a Disc: vinyl or CD. Anything else (cassette, file, DVD) is out of scope.
_Avoid_: Media, type

**Vinyl color**:
The main color of a vinyl Disc's wax, picked from a short fixed list of colors (or clear). Black when not set; Black is not in the list, except as a Second color. Kept but hidden if the Disc's Format is CD.
_Avoid_: Colour, variant

**Finish**:
How a vinyl Disc's wax is patterned: Solid, Marble, Splatter, Split, Galaxy or Glitter. Solid when not set, so existing Discs stay Solid. It only exists on a Disc with a Vinyl color, and is drawn from it (and from the Second color, for the Finishes that use one). It shows on the Disc out of its sleeve and in the form, never on the Color band. Every Disc has its own pattern, which never changes between launches. Typed by the user, never prefilled from the Catalog. Kept but hidden if the Disc's Format is CD; cleared when the Vinyl color is turned off. Picture discs and rarer finishes are out of scope.
_Avoid_: Pattern, effect, style, variant

**Second color**:
The other color of a Finish that uses one: Marble, Splatter, Split and Galaxy (Solid and Glitter have none). Picked from the Vinyl color list plus Black (Clear is not offered). Choosing such a Finish preselects White, or Black for Split. Kept when the Finish goes back to Solid, hidden then; cleared when the Vinyl color is turned off, and hidden but kept if the Disc's Format is CD.
_Avoid_: Accent color, color 2

**Speed**:
The RPM a vinyl Disc plays at: 33 or 45, nothing else. Optional and unset by default; existing Discs and Catalog results stay unset. Tapping the selected value in the form clears it. Kept but hidden if the Disc's Format is CD. Shown on the Disc detail only for a vinyl Disc with a Speed set, as "33 tr/min" or "45 tr/min" in French and "33 rpm" or "45 rpm" in English.
_Avoid_: RPM, size

**Color band**:
The flat band of a Disc's Vinyl color across the top-right corner of its cover, drawn only when the Disc shows a Vinyl color. Shown on the cover front everywhere a cover appears. Always a single flat color: the Finish and Second color never show on it.
_Avoid_: Sticker, color dot, badge, ribbon

**Collection**:
The Discs the user owns.
_Avoid_: Library, shelf

**Wishlist**:
The Discs the user wants but does not own yet.
_Avoid_: Wantlist

**Draft**:
A Disc being added or edited, not yet saved.

## Language

The app is available in English and French. Domain terms keep the same meaning in both; only the words shown to the user change. Both platforms use the mapping below.

| English | French |
| --- | --- |
| Disc | Disque |
| Collection | Collection |
| Wishlist | Wishlist |
| Profile | Profil |
| Vinyl color | Couleur vinyle |
| Finish | Finition |
| Second color | Deuxième couleur |
| Speed | Vitesse ("33 tr/min") in French, "33 rpm" in English |
| Format | Format |

**Language**:
The language the app is shown in: English or French. It follows the device language by default, with English as the fallback when the device language is neither. Once the user picks a Language in the Profile view, that choice overrides the device language.
_Avoid_: Locale, translation

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
The user's own screen: the Profile card, then the Language switch.
_Avoid_: Stats, account

**Profile card**:
The portrait silver card at the top of the Profile, brushed in diagonal lines: the Profile name, the Collection value (with the number of Collection Discs without a Paid price, when there are some), the number of vinyl and of CD Discs, the number of colored Discs (vinyl Discs with a Vinyl color, Clear included; never a CD) and the oldest year among the Discs that have one. Collection Discs only. It tilts with the phone.
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
