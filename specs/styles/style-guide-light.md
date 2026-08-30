# STYLE GUIDE — LIGHT THEME

> Generic light-theme style guide for converting markdown content to styled HTML pages.

---

## DESIGN TOKENS (CSS CUSTOM PROPERTIES)

```css
:root {
  /* Brand */
  --primary: #0a6ed1;
  --primary-dark: #0854a0;
  --primary-light: #e3f2fd;

  /* Status */
  --green: #188038;
  --green-bg: #e6f4ea;
  --red: #c5221f;
  --red-bg: #fce8e6;
  --amber: #e65100;
  --amber-bg: #fff3e0;

  /* Neutral */
  --gray-50: #f8f9fa;
  --gray-100: #f1f3f5;
  --gray-200: #e9ecef;
  --gray-300: #dee2e6;
  --gray-500: #868e96;
  --gray-700: #495057;
  --gray-900: #212529;

  /* Elevation */
  --shadow: 0 1px 3px rgba(0,0,0,0.08), 0 1px 2px rgba(0,0,0,0.06);
  --shadow-lg: 0 4px 12px rgba(0,0,0,0.1);
  --radius: 8px;
}
```

---

## TYPOGRAPHY

- **Font stack:** `-apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, 'Helvetica Neue', Arial, sans-serif`
- **Monospace:** `'SF Mono', SFMono-Regular, Consolas, monospace`
- **Base size:** Browser default (16px)
- **Line height:** 1.6

| Element | Size | Weight | Color |
|---|---|---|---|
| h1 (in header) | 1.75rem | 600 | white |
| h2 | 1.3rem | 600 | --gray-900 |
| h3 | 1.05rem | 600 | --gray-700 |
| Body text | 0.88–0.92rem | 400 | --gray-900 |
| Table header | 0.8rem | 600 | --gray-700 (uppercase, letter-spacing 0.03em) |
| Code | 0.82rem | 400 | --gray-700 (with --gray-100 background, 3px radius) |
| Small/meta text | 0.8–0.85rem | 400 | --gray-500 |

---

## PAGE LAYOUT

Single-column centered layout with a full-width header.

```
┌─────────────────────────────────────────────────────────┐
│                    Header (full width)                   │
├─────────────────────────────────────────────────────────┤
│                                                         │
│              Main Content (centered)                    │
│              max-width: 1000px                          │
│              (scrollable)                               │
│                                                         │
└─────────────────────────────────────────────────────────┘
```

- Main content: `max-width: 1000px`, `margin: 0 auto`, `padding: 2rem`

---

## HEADER

```
background: linear-gradient(135deg, var(--primary) 0%, var(--primary-dark) 100%)
color: white
padding: 2.5rem 2rem
box-shadow: var(--shadow-lg)
```

Contains: h1, subtitle/description, optional meta badges.

---

## TABLES

- Full width, white background, `var(--radius)` border-radius, `var(--shadow)` box-shadow
- Header row: `var(--gray-100)` background, 2px bottom border
- Header text: uppercase, 0.8rem, 600 weight, `var(--gray-700)`
- Cell padding: `0.65rem 1rem`
- Row hover: `var(--gray-50)`
- Bottom border per row: `1px solid var(--gray-100)`
- Overflow-x: auto wrapper for responsiveness

---

## BADGES

Inline label pills for status or category indicators.

| Class | Background | Text Color |
|---|---|---|
| `.badge-green` | --green-bg | --green |
| `.badge-neutral` | --gray-100 | --gray-700 |
| `.badge-blue` | #e3f2fd | #1565c0 |
| `.badge-purple` | #f3e5f5 | #7b1fa2 |
| `.badge-amber` | --amber-bg | --amber |
| `.badge-teal` | #e8f5e9 | #2e7d32 |
| `.badge-red` | --red-bg | --red |
| `.badge-primary` | --primary | white |
| `.badge-primary-alt` | --green | white |

All badges: `display: inline-block; padding: 0.15rem 0.5rem; border-radius: 4px; font-size: 0.78rem; font-weight: 500;`

---

## SUMMARY CARDS

Grid of key metric cards.

```css
.summary-cards {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(160px, 1fr));
  gap: 1rem;
  margin: 1.5rem 0 2rem;
}

.card {
  background: white;
  border-radius: var(--radius);
  padding: 1.25rem;
  box-shadow: var(--shadow);
  text-align: center;
}

.card .number { font-size: 2rem; font-weight: 700; color: var(--primary); }
.card .label { font-size: 0.85rem; color: var(--gray-500); margin-top: 0.25rem; }
```

---

## CONTENT BLOCKS

Card-style blocks for grouping related content sections:

```css
.content-block {
  background: white;
  border-radius: var(--radius);
  box-shadow: var(--shadow);
  margin-bottom: 1rem;
  overflow: hidden;
}

.content-block .block-header {
  padding: 0.75rem 1rem;
  background: var(--gray-100);
  font-weight: 600;
  font-size: 0.95rem;
  border-bottom: 1px solid var(--gray-200);
}

.content-block .block-body { padding: 1rem; }
```

---

## LINKS

- Link color: `var(--primary)`, no underline by default, underline on hover
- Header links: white, no underline, underline on hover

---

## RESPONSIVE

- Tables get `overflow-x: auto` wrapper on small screens
- Summary cards reflow to single column on narrow viewports

---

## DESIGN PATTERNS SUMMARY

1. **Color semantic mapping**: blue/primary = brand/links/actions, green = positive/success, red = danger/required, amber = warning/SAP, gray scale = neutral hierarchy.
2. **Surface hierarchy**: `--gray-50` (page background) → `white` (cards/tables) → `--gray-100` (headers/hover states).
3. **Elevation**: Cards and tables use `var(--shadow)` for subtle lift. Header uses `var(--shadow-lg)` for prominence.
4. **Border radius**: Uniform `var(--radius)` (8px) on all containers. Badges use 4px.
5. **Badge pattern**: `display: inline-block; padding: 0.15rem 0.5rem; border-radius: 4px; font-size: 0.78rem; font-weight: 500;` with semantic background/text color pairs.
6. **Hover interaction**: Table rows get `--gray-50` background on hover. Links get underline on hover.
7. **Spacing**: Card padding 1.25rem, block body padding 1rem, cell padding 0.65rem 1rem, grid gaps 1rem.
8. **Text hierarchy**: `--gray-900` for headings/body, `--gray-700` for secondary headings/labels, `--gray-500` for meta/descriptions.
