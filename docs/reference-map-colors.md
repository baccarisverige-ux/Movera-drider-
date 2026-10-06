# Reference map colors — October 6, 2026

Both Movera apps use identical base-map JSON sampled from the supplied images.
The lossless PNGs are the source of flat fill colors; JPEG compression shifts
some channels by one or more levels.

| Feature | Color | Evidence |
| --- | --- | --- |
| Land | `#FAFCFA` | Dominant land fill in all PNGs |
| Water | `#9EE4FF` | Dominant water fill in all PNGs |
| Parks | `#BEF2C9` | Green fill in IMG_7395/IMG_7396 |
| Natural green areas | `#DDF7E3` | Pale green fill in IMG_7390/IMG_7393 |
| Buildings / POIs | `#E2E7E9` | Urban grey fill in IMG_7395/IMG_7396 |
| Minor roads / boundaries | `#D2DBE1` | Light grey map detail |
| Main roads | `#C0C5CB` | Grey road pixels in IMG_7395 |
| Highways | `#8E9496`, `#8C939A` | Dark grey road pixels in IMG_7395 |
| General label fill | `#565C61` | Dark text pixels in IMG_7395 |
| Park label fill | `#158945` | Green text pixels in IMG_7395 |
| Water label fill | `#2676B5` | Visual match for antialiased blue labels |

Feature assignments are inferred from the screenshots; screenshots do not
contain the original map provider style. Google Maps geometry and text rendering
can differ from the reference provider. These values match the sampled palette,
but do not imply an identical rendered screenshot.

Traffic, route lines, location accuracy circles and custom markers are overlays;
they are not recolored or fabricated by the base-map style. Rider Home and its
shared map fallback use one constant to prevent palette drift. Driver uses the
same JSON for its shared map fallback.
