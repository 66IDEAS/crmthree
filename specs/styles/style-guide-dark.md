# STYLE GUIDE — DARK THEME

---

## DESIGN TOKENS (CSS CUSTOM PROPERTIES)

```
--bg-primary:      #0d1117
--bg-secondary:    #161b22
--bg-tertiary:     #21262d
--bg-card:         #1c2129
--border:          #30363d
--text-primary:    #e6edf3
--text-secondary:  #8b949e
--text-muted:      #6e7681
--accent-blue:     #58a6ff
--accent-green:    #3fb950
--accent-red:      #f85149
--accent-orange:   #d29922
--accent-purple:   #bc8cff
--accent-cyan:     #39d2c0
--ok:              #3fb950
--danger:          #f85149
--radius-lg:       12px
--radius-md:       10px
--radius-sm:       8px
```

Alias mappings (legacy variable names mapped to override values):
```
--bg    → #0d1117  (same as --bg-primary)
--card  → #161b22  (same as --bg-secondary)
--card-2 → #1c2129 (same as --bg-card)
--line  → #30363d  (same as --border)
--text  → #e6edf3  (same as --text-primary)
--muted → #8b949e  (same as --text-secondary)
```

---

## GLOBAL RESET

- `* { box-sizing: border-box }`
- `html, body { margin: 0; padding: 0; scroll-behavior: smooth }`

---

## TYPOGRAPHY

| Element | font-size | font-weight | color | line-height | extras |
|---|---|---|---|---|---|
| `body` | 14px | normal | --text-primary | 1.6 | font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Helvetica, Arial, sans-serif |
| `h1` | 42px | 800 | transparent (gradient fill) | 1.2 | background: linear-gradient(135deg, --accent-blue, --accent-purple); -webkit-background-clip: text; -webkit-text-fill-color: transparent |
| `h2` | 24px | 700 | --text-primary | default | margin: 0 0 8px |
| `h3` | 16px | 600 | --accent-blue | default | margin: 24px 0 10px |
| `p` | 14px | normal | --text-secondary | 1.7 | margin: 8px 0 0 |
| `a` | inherit | inherit | --accent-blue | inherit | — |

---

## LAYOUT

### `.page` (main container)
```
max-width: 1100px
width: min(1100px, 94vw)
margin: 0 auto
padding: 32px 24px 48px
```

---

## COMPONENTS

### `.card` (section container)
```
background: --bg-secondary
border: 1px solid --border
border-radius: 12px
padding: 32px 36px
margin-bottom: 28px
box-shadow: none
position: relative
```

**Top accent line** (`.card:not(.hero)::before`):
```
content: ""
position: absolute
top: 0; left: 0; right: 0
height: 3px
border-radius: 12px 12px 0 0
background: linear-gradient(90deg, rgba(210,153,34,0.95), rgba(210,153,34,0.2))
pointer-events: none
```

### `.section-label` (floating label above card)
```
position: absolute
top: -11px; left: 24px
background: --bg-primary
border: 1px solid --border
color: --accent-blue
font-size: 10px
font-weight: 700
padding: 2px 14px
border-radius: 12px
letter-spacing: 0.5px
text-transform: uppercase
```

### `.hero` (hero card override)
```
text-align: center
padding: 64px 32px 48px
margin-bottom: 40px
overflow: hidden
border: 1px solid --border
background: --bg-secondary
```

**Hero radial glow** (`.hero::before`):
```
content: ""
position: absolute
top: -120px; left: 50%; transform: translateX(-50%)
width: 600px; height: 600px
background: radial-gradient(circle, rgba(88,166,255,0.08) 0%, rgba(188,140,255,0.04) 40%, transparent 70%)
pointer-events: none
```

### `.eyebrow` (small label above heading)
```
font-size: 11px
text-transform: uppercase
letter-spacing: 3px
color: --accent-purple
margin-bottom: 24px
position: relative
```

### `.section-sub` (section subtitle)
```
color: --text-secondary
font-size: 15px
margin-bottom: 24px
line-height: 1.6
```

---

### `.chip` (tag pill in hero)
```
display: inline-block
background: rgba(88,166,255,0.1)
border: 1px solid rgba(88,166,255,0.2)
color: --accent-blue
font-size: 12px
font-weight: 600
padding: 3px 12px
border-radius: 20px
margin: 2px 4px
```

Container `.chips`: `display: flex; flex-wrap: wrap; gap: 8px; justify-content: center`

### `.jump a` (navigation pill links)
```
display: inline-block
background: transparent
color: --accent-blue
font-size: 14px
font-weight: 600
padding: 10px 24px
border-radius: 8px
border: 1px solid --accent-blue
text-decoration: none
transition: background 0.2s, transform 0.2s
```

Hover state:
```
color: --accent-orange
border-color: --accent-orange
background: rgba(210,153,34,0.12)
transform: translateY(-2px)
```

Container `.jump`: `display: flex; flex-wrap: wrap; gap: 8px; justify-content: center; margin-top: 24px`

---

### `.kpis` (KPI grid)
```
display: grid
grid-template-columns: repeat(4, 1fr)
gap: 16px
margin-bottom: 24px
```

Responsive (`@media max-width: 900px`): `grid-template-columns: repeat(2, 1fr)`

### `.kpi` (individual KPI card)
```
background: --bg-tertiary
border: 1px solid --border
border-radius: 10px
padding: 20px 16px
text-align: center
transition: transform 0.2s, border-color 0.2s
```

Hover: `transform: translateY(-3px); border-color: --accent-blue`

**`.kpi strong`**: `font-size: 28px; font-weight: 800; color: --accent-blue; display: block; margin-bottom: 4px`
**`.kpi span`**: `font-size: 11px; color: --text-secondary; text-transform: uppercase; letter-spacing: 0.5px`

---

### `.project-card`
```
background: --bg-tertiary
border: 1px solid --border
border-radius: 10px
padding: 24px 22px
margin-bottom: 14px
transition: transform 0.2s, border-color 0.2s
```

Hover: `transform: translateY(-3px); border-color: --accent-blue`

### `.tag` (project code badge)
```
display: inline-block
font-size: 10px
text-transform: uppercase
letter-spacing: 0.5px
padding: 2px 8px
border-radius: 10px
font-weight: 600
border: 1px solid
margin-bottom: 7px
```

Variants:
| Class | color | border-color | background |
|---|---|---|---|
| `.tag.sch` | --accent-orange | rgba(210,153,34,0.35) | rgba(210,153,34,0.15) |
| `.tag.abb` | --accent-blue | rgba(88,166,255,0.35) | rgba(88,166,255,0.15) |
| `.tag.dic` | --accent-purple | rgba(188,140,255,0.35) | rgba(188,140,255,0.15) |

### `.project-meta`
```
color: --text-secondary
font-size: 13px
margin-top: 8px
```

### `.member-pill`
```
display: inline-block
border: 1px solid rgba(88,166,255,0.2)
border-radius: 999px
padding: 3px 10px
font-size: 12px
color: --accent-blue
background: rgba(88,166,255,0.1)
font-weight: 600
```

**`.member-pill.lead`** variant:
```
border-color: rgba(188,140,255,0.35)
color: --accent-purple
background: rgba(188,140,255,0.15)
```

Container `.member-pills`: `display: flex; flex-wrap: wrap; gap: 6px; margin-top: 8px`

### `.details-btn` (project action button)
```
display: inline-block
border: 1px solid --accent-orange
border-radius: 8px
padding: 8px 12px
background: linear-gradient(135deg, rgba(210,153,34,0.22), rgba(210,153,34,0.08))
color: #ffd9a6
font-size: 12px
font-weight: 700
text-decoration: none
letter-spacing: 0.2px
transition: transform 0.2s, background 0.2s, border-color 0.2s
```

Hover:
```
transform: translateY(-2px)
border-color: #f2b86a
background: linear-gradient(135deg, rgba(210,153,34,0.35), rgba(210,153,34,0.15))
```

Container `.project-actions`: `display: flex; align-items: center; margin-top: 12px`

---

### `.assignment-item`
```
background: --bg-tertiary
border: 1px solid --border
border-radius: 10px
padding: 14px 16px
margin-bottom: 10px
```

**`.assignment-title`**: `font-size: 13px; font-weight: 700; color: --text-primary; margin: 0 0 8px; line-height: 1.4`

---

### `.stack-list` (bulleted list)
```
margin: 0
padding-left: 20px
color: --text-secondary
line-height: 1.6
```

**`.stack-list li`**: `margin: 6px 0`

---

### TABLE SYSTEM

#### `.table-wrap` (scrollable table container)
```
overflow-x: auto
background: --bg-tertiary
border: 1px solid --border
border-radius: 10px
margin-top: 10px
```

#### `table`
```
width: 100%
min-width: 760px
border-collapse: collapse
font-size: 13px
color: --text-primary
```

#### `th`
```
text-align: left
padding: 8px 10px
border-bottom: 1px solid rgba(48,54,61,0.5)
background: rgba(22,27,34,0.95)
color: --accent-blue
font-size: 11px
text-transform: uppercase
letter-spacing: 0.5px
position: sticky; top: 0
```

#### `td`
```
text-align: left
padding: 8px 10px
border-bottom: 1px solid rgba(48,54,61,0.5)
vertical-align: top
```

Last row: `tr:last-child td { border-bottom: none }`

---

### TABS & BUTTONS

#### `.tabs button` / `.view-toggle button`
```
border: 1px solid --border
border-radius: 8px
background: --bg-card
color: --text-secondary
font-size: 13px
font-weight: 600
padding: 8px 14px
cursor: pointer
transition: transform 0.2s, border-color 0.2s, color 0.2s
```

Hover: `transform: translateY(-2px); border-color: --accent-blue; color: --text-primary`

Active (`.active`):
```
color: #fff
border-color: --accent-orange
background: linear-gradient(135deg, --accent-orange, #b97b12)
```

Container: `display: flex; flex-wrap: wrap; gap: 8px; margin-bottom: 8px`

---

### TASK LIST

#### `.tasks-project`
```
background: --bg-tertiary
border: 1px solid --border
border-radius: 10px
padding: 16px 18px
margin-bottom: 12px
```

#### `.task-items` (ul)
```
list-style: none; margin: 0; padding: 0
```

#### `.task-items li`
```
background: --bg-card
border: 1px solid --border
border-radius: --radius-sm (8px)
margin-top: 7px
padding: 8px
font-size: 13px
color: --text-secondary
```

#### `.task-id`
```
color: --accent-blue
font-weight: 700
margin-right: 6px
```

---

### GANTT CHART

#### `.gantt` (outer container)
```
background: --bg-tertiary
border: 1px solid --border
border-radius: 10px
overflow: hidden
```

#### `.gantt-header` / `.gantt-row`
```
display: grid
grid-template-columns: minmax(300px, 390px) 1fr
border-bottom: 1px solid rgba(48,54,61,0.5)
```

Last row: `border-bottom: none`

Responsive (`@media max-width: 900px`): `grid-template-columns: 1fr`

#### `.gantt-header`
```
background: --bg-secondary
color: --accent-blue
font-size: 11px
text-transform: uppercase
letter-spacing: 0.5px
```

#### `.gantt-header .weeks`
```
display: grid
grid-template-columns: repeat(12, minmax(34px, 1fr))
```

**Week span cells**: `border-right: 1px solid rgba(48,54,61,0.5); text-align: center; padding: 9px 4px; font-size: 0.72rem; color: --text-secondary`
Last child: no right border.

#### `.task-col`
```
padding: 9px 10px
border-right: 1px solid rgba(48,54,61,0.5)
```

Responsive: `border-right: none`

#### `.task-main`
```
color: --text-primary
font-size: 13px
line-height: 1.36
```

**`.task-main .id`**: `color: --accent-blue; font-weight: 700; margin-right: 6px`

#### `.task-sub`
```
color: --text-muted
font-size: 12px
margin-top: 4px
```

#### `.track` (bar container)
```
position: relative
min-height: 54px
padding: 10px 8px
background: --bg-card
```

Responsive: `min-height: 62px`

**Grid lines** (`.track::before`):
```
content: ""
position: absolute; inset: 0
background-image: repeating-linear-gradient(to right,
  transparent, transparent calc((100%/12) - 1px),
  rgba(48,54,61,0.5) calc((100%/12) - 1px),
  rgba(48,54,61,0.5) calc(100%/12))
pointer-events: none
```

#### `.bar` (gantt bar)
```
position: absolute
top: 16px; height: 22px
border-radius: 999px
display: flex; align-items: center; justify-content: center
font-size: 11px; font-weight: 700; letter-spacing: 0.03em
color: #fff
z-index: 1
left: calc((var(--start) - 1) * (100%/12) + 3px)
width: calc((var(--end) - var(--start) + 1) * (100%/12) - 6px)
min-width: 28px
```

Bar color variants:
| Class | background |
|---|---|
| `.bar.sch` | linear-gradient(90deg, --accent-orange, #b97b12) |
| `.bar.abb` | linear-gradient(90deg, --accent-blue, #388bfd) |
| `.bar.dic` | linear-gradient(90deg, --accent-purple, #8b5cf6) |

#### `.open-chip` (unscheduled task indicator)
```
position: absolute
top: 15px; left: 10px; z-index: 1
border: 1px solid rgba(248,81,73,0.4)
color: --accent-red
background: rgba(248,81,73,0.12)
border-radius: 999px
padding: 4px 9px
font-size: 0.72rem
font-weight: 700
```

---

### STATUS PILLS

#### `.status-pill` (base)
```
display: inline-block
border-radius: 999px
padding: 3px 8px
font-size: 0.74rem
font-weight: 700
border: 1px solid
white-space: nowrap
```

| Variant | color | border-color | background |
|---|---|---|---|
| `.status-pill.confirmed` | --accent-green | rgba(63,185,80,0.35) | rgba(63,185,80,0.12) |
| `.status-pill.open` | --accent-red | rgba(248,81,73,0.35) | rgba(248,81,73,0.12) |

---

### `.timeline-controls`
```
background: --bg-tertiary
border: 1px solid --border
border-radius: 10px
padding: 16px 18px
margin-bottom: 10px
```

### `.counts`
```
margin: 6px 0 0
color: --text-secondary
font-size: 0.82rem
```

### `.footer`
```
color: --text-secondary
font-size: 0.76rem
margin-top: 14px
padding-bottom: 6px
```

---

## DESIGN PATTERNS SUMMARY

1. **Color semantic mapping**: orange = primary action/highlight, blue = info/links/identifiers, purple = accent/lead/special, green = confirmed/ok, red = danger/open.
2. **Surface hierarchy**: `--bg-primary` (page) → `--bg-secondary` (card) → `--bg-tertiary` (nested element) → `--bg-card` (deeply nested).
3. **Border pattern**: All containers use `1px solid --border (#30363d)`. Pill/badge variants use semi-transparent borders matching their accent color at 0.2–0.4 alpha.
4. **Border radius scale**: 12px (cards), 10px (inner cards/tags), 8px (buttons/small items), 999px (pills/badges).
5. **Pill/badge pattern**: `border-radius: 999px; padding: 3px 8px; font-size: 10–12px; font-weight: 600–700; border: 1px solid <accent-alpha-0.35>; background: <accent-alpha-0.10–0.15>; color: <accent-solid>`.
6. **Hover interaction**: `transform: translateY(-2px)` or `translateY(-3px)` with `border-color` change to accent. Always with `transition: transform 0.2s`.
7. **Gradient usage**: Cards have no gradient (flat `--bg-secondary`). Active buttons use `linear-gradient(135deg, --accent-orange, #b97b12)`. Gantt bars use `linear-gradient(90deg, <start>, <end>)`. Top card accent is `linear-gradient(90deg, rgba(210,153,34,0.95), rgba(210,153,34,0.2))`.
8. **Text hierarchy**: `--text-primary` for headings/important, `--text-secondary` for body/descriptions, `--text-muted` for tertiary info.
9. **Spacing**: card padding 32px 36px, inner card padding 16–24px, gap between items 8–16px, margin-bottom between cards 28px, between inner items 10–14px.
10. **Table pattern**: sticky header, uppercase 11px letter-spaced blue headers, 13px body text, semi-transparent row borders, scrollable wrapper.

---

## RESPONSIVE BREAKPOINT

`@media (max-width: 900px)`:
- `.kpis` grid: 4 columns → 2 columns
- `.gantt-header` / `.gantt-row`: 2-column grid → single column
- `.task-col` border-right removed
- `.gantt-header .weeks`: gains top border
- `.track` min-height: 54px → 62px
