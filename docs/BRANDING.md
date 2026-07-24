# Branding — TATTVA TV

The Apple TV app ships under the **TATTVA TV** identity: an aperture-swirl mark
in warm reds→gold wrapping a white play triangle, the "TATTVA TV" wordmark, and
the line *"Meaningful stories. Beautifully streamed."* This doc is the map of
where those assets live and how they are wired.

<p align="center">
  <img src="images/brand/tattva-tv-logo.png" alt="TATTVA TV logo lockup" width="280">
</p>

## Two asset homes

| Purpose | Location | Consumed by |
|---------|----------|-------------|
| **Shipped app assets** (Apple TV) | `StreamingVideoApp/StreamingVideoAppTV/Assets.xcassets/AppIcon.brandassets` | the tvOS app at runtime / on the Home screen |
| **Repo presentation** (README/docs) | `docs/images/brand/` | GitHub README + docs |

## tvOS Brand Assets (`AppIcon.brandassets`)

tvOS icons are **layered** (a "Brand Assets" set), not a single square image.
The catalog defines four assets:

| Asset | Role | Base size | Scales |
|-------|------|-----------|--------|
| `App Icon.imagestack` | `primary-app-icon` | 400×240 | 1x (400×240), 2x (800×480) |
| `App Icon - App Store.imagestack` | `primary-app-icon` | 1280×768 | 1x |
| `Top Shelf Image.imageset` | `top-shelf-image` | 1920×720 | 1x, 2x |
| `Top Shelf Image Wide.imageset` | `top-shelf-image-wide` | 2320×720 | 1x, 2x |

### Layered app icon

Each `.imagestack` holds three `.imagestacklayer`s — **Front**, **Middle**,
**Back** (front-to-back order in the stack's `Contents.json`). tvOS separates the
layers in Z and shifts them on focus to produce the signature **parallax** float.

The current icon is authored **full-bleed on the Back layer** (Middle/Front are
transparent placeholders): the artwork already contains the mark + wordmark on a
charcoal field, and tvOS supplies its own rounded-rectangle mask, so a full-bleed
composite avoids a baked-in border colliding with the system mask.

> To move to true parallax, split the mark onto the **Front** layer and keep the
> charcoal field + wordmark on **Back**. That requires layer-separated source art
> (the mark on transparency), not a flattened composite.

### Top Shelf

`Top Shelf Image` (2.67:1) and `Top Shelf Image Wide` (≈3.22:1) carry the mark +
wordmark over the sunset landscape. The shelf sits **behind** the app's featured
content rows, so the art is kept clean (no tagline) to avoid colliding with
overlaid UI.

## Wiring

The tvOS target selects the brand-asset set by name in build settings:

```
ASSETCATALOG_COMPILER_APPICON_NAME = AppIcon   // tvOS Debug + Release
```

`actool` validates the layered structure and exact slot dimensions at build time,
so a malformed stack or wrong-sized PNG fails the build (a useful guardrail).

## Repo presentation images (`docs/images/brand/`)

| File | Use |
|------|-----|
| `tattva-tv-hero.jpg` | README banner (1600×800) |
| `top-shelf.jpg` | README Apple TV section + APPLE-TV doc (1600×600) |
| `tattva-tv-logo.png` | Vertical logo lockup (transparent-friendly) |
| `app-icon.png` | Square app-icon render (512×512) |
| `social-preview.jpg` | GitHub social preview (1280×640) |

Photographic assets (the sunset hero/shelf) are **JPEG** — an order of magnitude
smaller than PNG for that content; the flat-graphic logo/icon stay **PNG**.

To set the GitHub social preview: repository **Settings → General → Social
preview → upload** `docs/images/brand/social-preview.jpg` (this is a repo setting,
not a file GitHub reads from the tree).

## Related

- [Apple TV (tvOS)](features/APPLE-TV.md) — the app that consumes these assets
