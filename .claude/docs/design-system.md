# Design system

Claude-inspired dual-mode theme. Warm off-whites in light mode, warm dark browns in dark mode. Coral-orange accent throughout.
All tokens live in `Resources/AppColors.swift`, `AppFonts.swift`, `AppSpacing.swift`.

Color mode is user-selectable: **Automatic** (follows system), **Light**, or **Dark**. Set via Settings > Appearance.

---

## Colors

All colors are adaptive — they resolve automatically based on the active color scheme.

### Neutral surfaces

| Token | Light | Dark | Swift constant | Usage |
|---|---|---|---|---|
| Canvas | `#FDFCFA` | `#1A1815` | `AppColors.canvas` | Main window background |
| Surface | `#F7F5F0` | `#201D18` | `AppColors.surface` | Sidebar, panel backgrounds |
| Surface+ | `#F2EFE9` | `#2A251D` | `AppColors.surfacePlus` | Code blocks, input backgrounds |
| Subtle | `#EAE8E3` | `#3A352B` | `AppColors.subtle` | Section dividers, subtle fills |
| Border | `#DDD9D2` | `#3A352B` | `AppColors.border` | Default borders, separators |
| Muted | `#C8C4BC` | `#6A6158` | `AppColors.muted` | Disabled borders, placeholders |

### Text scale

| Token | Light | Dark | Swift constant | Usage |
|---|---|---|---|---|
| Primary | `#1A1916` | `#E8E6E3` | `AppColors.textPrimary` | Main text, headings |
| Secondary | `#3B3A37` | `#C4BEB5` | `AppColors.textSecondary` | Body text, labels |
| Tertiary | `#6B6760` | `#9A9389` | `AppColors.textTertiary` | Supporting text, captions |
| Placeholder | `#8C8982` | `#6A6158` | `AppColors.textPlaceholder` | Input placeholders, hints |
| Faint | `#A09D96` | `#5A5549` | `AppColors.textFaint` | Section labels, eyebrows |

### Brand accent — Claude orange-coral

| Token | Light | Dark | Swift constant | Usage |
|---|---|---|---|---|
| Tint 50 | `#FAF0EA` | `#2A2018` | `AppColors.brandTint50` | Hover backgrounds |
| Tint 100 | `#EECFBA` | `#3A2A1A` | `AppColors.brandTint100` | Active borders |
| Primary | `#D4622E` | `#D4622E` | `AppColors.brand` | Send button, CTA, active selection |
| Hover | `#C96A2A` | `#E67D22` | `AppColors.brandHover` | Hover state |
| Pressed | `#A84E1E` | `#C96A2A` | `AppColors.brandPressed` | Pressed / active state |

### Semantic — status & feedback

| Token | Light Bg | Dark Bg | Light Text | Dark Text | Swift bg constant | Usage |
|---|---|---|---|---|---|---|
| Success | `#EAF5EE` | `#1A2E20` | `#1D6B3A` | `#4CAF50` | `AppColors.successBg` | 2xx responses, saved |
| Info | `#EBF3FB` | `#1A2535` | `#1E5F8F` | `#42A5F5` | `AppColors.infoBg` | Informational, POST |
| Warning | `#FEF4E6` | `#2E2510` | `#8A5A0B` | `#F3DF31` | `AppColors.warningBg` | 3xx, PUT method |
| Error | `#FDEEEC` | `#2E1A18` | `#9B2A1E` | `#FF6B6B` | `AppColors.errorBg` | 4xx/5xx, DELETE |

### HTTP method palette

| Method | Light Bg | Dark Bg | Light Text | Dark Text | Swift constant |
|---|---|---|---|---|---|
| GET | `#EAF5EE` | `#1A2E20` | `#1D6B3A` | `#4CAF50` | `AppColors.methodGet` |
| POST | `#EBF3FB` | `#1A2535` | `#1E5F8F` | `#42A5F5` | `AppColors.methodPost` |
| PUT | `#FEF4E6` | `#2E2510` | `#8A5A0B` | `#F3DF31` | `AppColors.methodPut` |
| DELETE | `#FDEEEC` | `#2E1A18` | `#9B2A1E` | `#FF6B6B` | `AppColors.methodDelete` |
| PATCH | `#F0EBF8` | `#251A30` | `#6040A0` | `#AB47BC` | `AppColors.methodPatch` |
| OPTIONS | `#E8F6F5` | `#1A2E2D` | `#1A5F5A` | `#26C6DA` | `AppColors.methodOptions` |
| HEAD | `#F2EFE9` | `#2A251D` | `#6B6760` | `#9A9389` | `AppColors.methodHead` |

---

## Typography

All fonts are native — SF Pro Display, SF Pro Text, SF Mono. Zero imports.

| Role | Size | Weight | Font | Swift constant |
|---|---|---|---|---|
| Display | 22pt | 500 | SF Pro Display | `AppFonts.display` |
| Title | 15pt | 500 | SF Pro Display | `AppFonts.title` |
| Body | 13pt | 400 | SF Pro Text | `AppFonts.body` |
| Mono | 12pt | 400 | SF Mono | `AppFonts.mono` |
| Eyebrow | 10pt | 500 | SF Pro Text | `AppFonts.eyebrow` |

**Rules:**
- Eyebrow labels: `0.10em` letter spacing, all caps
- SF Mono used for: URL bar, JSON viewer, header keys/values, response body, environment variable values

---

## Spacing scale

All values as `CGFloat` in `AppSpacing`.

| Token | Value | Swift constant | Usage |
|---|---|---|---|
| xs | 4 | `AppSpacing.xs` | Icon padding, tight gaps |
| sm | 8 | `AppSpacing.sm` | Internal component gaps |
| md | 12 | `AppSpacing.md` | Row padding |
| lg | 16 | `AppSpacing.lg` | Panel padding |
| xl | 24 | `AppSpacing.xl` | Section gaps |
| xxl | 32 | `AppSpacing.xxl` | Large section gaps |
| xxxl | 48 | `AppSpacing.xxxl` | Page-level spacing |

---

## Corner radius

| Token | Value | Swift constant | Usage |
|---|---|---|---|
| Badge | 3 | `AppSpacing.radiusBadge` | Method badges, status pills |
| Input | 5 | `AppSpacing.radiusInput` | Text inputs, text areas |
| Card | 7 | `AppSpacing.radiusCard` | Sidebar rows, list items |
| Panel | 10 | `AppSpacing.radiusPanel` | Panels, sheets, cards |
| Pill | 20 | `AppSpacing.radiusPill` | Tag pills, rounded labels |

---

## Elevation

### Light mode

| Level | Background | Border | Shadow | Usage |
|---|---|---|---|---|
| 0 | `#F7F5F0` | `#EAE8E3` | none | Sidebar background |
| 1 | `#FDFCFA` | `#DDD9D2` | 0 1 3px rgba(0,0,0,.05) | Cards, panels |
| 2 | `#FFFFFF` | `#DDD9D2` | 0 2 8px rgba(0,0,0,.07) | Dropdowns, popovers |
| 3 | `#FFFFFF` | `#DDD9D2` | 0 4 16px rgba(0,0,0,.10) | Modals, sheets |

### Dark mode

| Level | Background | Border | Shadow | Usage |
|---|---|---|---|---|
| 0 | `#201D18` | `#3A352B` | none | Sidebar background |
| 1 | `#1A1815` | `#3A352B` | 0 1 3px rgba(0,0,0,.20) | Cards, panels |
| 2 | `#2A251D` | `#3A352B` | 0 2 8px rgba(0,0,0,.25) | Dropdowns, popovers |
| 3 | `#2A251D` | `#3A352B` | 0 4 16px rgba(0,0,0,.30) | Modals, sheets |

---

## Icon system

Native SF Symbols only — no third-party icon libs.

| Icon | SF Symbol name | Usage |
|---|---|---|
| Folder | `folder` | Collections in sidebar |
| Clock | `clock` | History tab |
| Checkmark | `checkmark` | Success states |
| Plus | `plus` | New request / folder |
| Xmark | `xmark` | Close, cancel, delete |
| List | `list.bullet` | Collections view |
| Pencil | `pencil` | Rename, edit |
| Trash | `trash` | Delete |
| Chevron | `chevron.right` | Expand tree nodes |
| Globe | `globe` | URL / endpoint indicator |
| Environment | `square.stack` | Environment selector |
| Send | `paperplane` | Send button icon |
| Copy | `doc.on.doc` | Copy value / response |
| Settings | `gear` | Settings button |

---

## JSON syntax colors

Used in `JSONTreeView` and `RawBodyView`.

| Token type | Light | Dark | Color name |
|---|---|---|---|
| Key | `#C96A2A` | `#D4916A` | Brand orange |
| String value | `#2D7F4E` | `#4CAF50` | Forest green |
| Number value | `#6040A0` | `#AB47BC` | Violet |
| Boolean value | `#1E5F8F` | `#42A5F5` | Info blue |
| Null value | `#8C8982` | `#6A6158` | Muted gray |
| Punctuation | `#6B6760` | `#9A9389` | Tertiary text |
