# Interactive Spec — Reference

## Theming

All colours are CSS custom properties in `:root`. Change these to match the project brand:

```css
:root {
  --accent: #2563eb;        /* Primary brand colour — rule IDs, active states, links */
  --accent-light: #eff6ff;  /* Light tint for hover backgrounds */
  --accent-soft: #dbeafe;   /* Mid tint for active nav, search highlights */
  --warn: #f59e0b;          /* Warning colour for ⚠ tags and triage */
  --warn-bg: #fffbeb;       /* Warning background */
  --danger: #ef4444;        /* High-severity triage items */
  --success: #16a34a;       /* Success / checkmarks */
  --radius: 10px;           /* Border radius for cards */
  --sidebar-w: 300px;       /* Sidebar width */
}
```

Dark mode colours are in `[data-theme="dark"]` — adjust in parallel.

## Mermaid Diagrams

The template includes 7 diagram slots. Choose the most informative set for the project:

| # | Recommended | When to use |
|---|---|---|
| 1 | System architecture | Always — orients readers |
| 2 | Primary state machine | If the project has a core entity lifecycle |
| 3 | Key creation/decision flow | If entity creation has branching logic |
| 4 | Critical sequence | If there's an important multi-step async flow |
| 5 | Event/side-effect lifecycle | If statuses trigger side effects (emails, webhooks) |
| 6 | Entity relationship diagram | Always — shows data model |
| 7 | Processing modes / batch flow | If there are sync/async or ordering concerns |

Mermaid is loaded from CDN:
```html
<script src="https://cdn.jsdelivr.net/npm/mermaid@11/dist/mermaid.min.js"></script>
```

Theme auto-switches with dark mode via:
```js
mermaid.initialize({ theme: next === 'dark' ? 'dark' : 'default' });
```

### Diagram authoring rules (avoid silent breakage)

- **Quote any node label containing `{`, `}`, `(`, `)`, `/`, `+`, `#`, `:`, `;` or a leading keyword.** Unquoted braces are the most common parse-error cause — e.g. `A[PUT /companies/{nif}]` fails; write `A["PUT /companies/{nif}"]`. One broken diagram renders a red error box; the rest still render.
- Each `.mermaid-wrap` gets auto-injected controls (Fullscreen / SVG / PNG) after render — no per-diagram markup needed. Fullscreen download filename is derived from the `.caption` text, so give every diagram a caption.
- The template renders with `startOnLoad: false` then calls `mermaid.run().then(addDiagramControls)`; diagram source is stashed in `data-original` at init so the theme toggle can re-render without blanking. Don't revert to `startOnLoad: true`.
- SVGs are `display:block; max-width:100%` (not `inline-block`) so they fill the container instead of collapsing to ~300px.

## JavaScript Features

All interactive behaviour is vanilla JS — no framework. The script block at the bottom handles:

| Feature | How it works |
|---|---|
| **Accordion** | Click `.accordion-header` toggles `.open` on parent |
| **Theme toggle** | Swaps `data-theme` on `<html>`, re-initialises Mermaid |
| **Rule ID copy** | Click `.rid` → `navigator.clipboard.writeText()` + toast |
| **View tabs** | Show/hide `#full-spec` vs `#quick-ref` |
| **Quick Ref → Full Spec** | Card clicks switch to full view, scroll to area, flash highlight |
| **Search** | `input` on `#search-box` filters `allRules` array, renders results, click navigates |
| **Scroll spy** | `IntersectionObserver` on `.area[id]` updates sidebar `.active` |
| **Keyboard shortcut** | `Ctrl+K` / `Cmd+K` focuses search box |

### The `allRules` array

At the bottom of the script, the search index is built from:
```js
const allRules = Array.from(document.querySelectorAll('.rule')).map(r => ({
  el: r,
  id: r.dataset.rule,
  area: r.dataset.area,
  text: r.textContent.toLowerCase(),
  areaName: r.closest('.area')?.querySelector('h2')?.textContent?.trim() || ''
}));
```

Your `.rule` elements must have `data-rule` and `data-area` attributes for this to work.

## Layout Customisation

### Sidebar width
Change `--sidebar-w` in `:root`.

### Accordion open by default
Add class `open` to any `.accordion` div. The template opens the first accordion in each area and the diagrams.

### Adding new areas
Copy an existing `.area` block. Update:
- The `id` (must match a sidebar link `href`)
- The `data-area` attribute on all `.rule` elements
- Add a corresponding `.area-link` in the sidebar
- Add a `.qr-card` section in the Quick Reference view

### Responsive breakpoint
Sidebar hides at 860px. Change `@media (max-width: 860px)` in the CSS.

## Accessibility

- All interactive elements are keyboard-accessible
- Search has a keyboard shortcut (Ctrl+K / Cmd+K)
- Dark mode reduces eye strain
- Colour is never the sole differentiator (icons + text accompany status colours)
