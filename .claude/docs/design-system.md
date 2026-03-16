# Design system

Claude-inspired light mode. Warm off-whites, coral-orange accent, deep warm slate text.
All tokens live in `Resources/AppColors.swift`, `AppFonts.swift`, `AppSpacing.swift`.

---

## Colors

### Neutral surfaces

| Token | Hex | Swift constant | Usage |
|---|---|---|---|
| Canvas | `#FDFCFA` | `AppColors.canvas` | Main window background |
| Surface | `#F7F5F0` | `AppColors.surface` | Sidebar, panel backgrounds |
| Surface+ | `#F2EFE9` | `AppColors.surfacePlus` | Code blocks, input backgrounds |
| Subtle | `#EAE8E3` | `AppColors.subtle` | Section dividers, subtle fills |
| Border | `#DDD9D2` | `AppColors.border` | Default borders, separators |
| Muted | `#C8C4BC` | `AppColors.muted` | Disabled borders, placeholders |

### Text scale

| Token | Hex | Swift constant | Usage |
|---|---|---|---|
| Primary | `#1A1916` | `AppColors.textPrimary` | Main text, headings |
| Secondary | `#3B3A37` | `AppColors.textSecondary` | Body text, labels |
| Tertiary | `#6B6760` | `AppColors.textTertiary` | Supporting text, captions |
| Placeholder | `#8C8982` | `AppColors.textPlaceholder` | Input placeholders, hints |
| Faint | `#A09D96` | `AppColors.textFaint` | Section labels, eyebrows |

### Brand accent — Claude orange-coral

| Token | Hex | Swift constant | Usage |
|---|---|---|---|
| Tint 50 | `#FAF0EA` | `AppColors.brandTint50` | Hover backgrounds |
| Tint 100 | `#EECFBA` | `AppColors.brandTint100` | Active borders |
| Primary | `#D4622E` | `AppColors.brand` | Send button, CTA, active selection |
| Hover | `#C96A2A` | `AppColors.brandHover` | Hover state |
| Pressed | `#A84E1E` | `AppColors.brandPressed` | Pressed / active state |

### Semantic — status & feedback

| Token | Background | Text | Swift bg constant | Usage |
|---|---|---|---|---|
| Success | `#EAF5EE` | `#1D6B3A` | `AppColors.successBg` | 2xx responses, saved |
| Info | `#EBF3FB` | `#1E5F8F` | `AppColors.infoBg` | Informational, POST |
| Warning | `#FEF4E6` | `#8A5A0B` | `AppColors.warningBg` | 3xx, PUT method |
| Error | `#FDEEEC` | `#9B2A1E` | `AppColors.errorBg` | 4xx/5xx, DELETE |

### HTTP method palette

| Method | Background | Text | Swift constant |
|---|---|---|---|
| GET | `#EAF5EE` | `#1D6B3A` | `AppColors.methodGet` |
| POST | `#EBF3FB` | `#1E5F8F` | `AppColors.methodPost` |
| PUT | `#FEF4E6` | `#8A5A0B` | `AppColors.methodPut` |
| DELETE | `#FDEEEC` | `#9B2A1E` | `AppColors.methodDelete` |
| PATCH | `#F0EBF8` | `#6040A0` | `AppColors.methodPatch` |
| OPTIONS | `#E8F6F5` | `#1A5F5A` | `AppColors.methodOptions` |
| HEAD | `#F2EFE9` | `#6B6760` | `AppColors.methodHead` |

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

| Level | Background | Border | Shadow | Usage |
|---|---|---|---|---|
| 0 | `#F7F5F0` | `#EAE8E3` | none | Sidebar background |
| 1 | `#FDFCFA` | `#DDD9D2` | 0 1 3px rgba(0,0,0,.05) | Cards, panels |
| 2 | `#FFFFFF` | `#DDD9D2` | 0 2 8px rgba(0,0,0,.07) | Dropdowns, popovers |
| 3 | `#FFFFFF` | `#DDD9D2` | 0 4 16px rgba(0,0,0,.10) | Modals, sheets |

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

---

## JSON syntax colors

Used in `JSONTreeView` and `RawBodyView`.

| Token type | Color | Hex |
|---|---|---|
| Key | Brand orange | `#C96A2A` |
| String value | Forest green | `#2D7F4E` |
| Number value | Violet | `#6040A0` |
| Boolean value | Info blue | `#1E5F8F` |
| Null value | Muted gray | `#8C8982` |
| Punctuation | Tertiary text | `#6B6760` |
