---
name: interactive-spec
description: Generate an interactive, self-contained HTML functional specification from markdown spec files. Produces a single HTML file with search, dark/light mode, accordion sections, Mermaid diagrams, quick-reference cards, rule ID copying, and a triage report. Use when the user wants an interactive spec, an HTML version of documentation, a polished spec presentation, or says "interactive spec", "HTML spec", "spec presentation", "generate spec HTML".
---

# Interactive Spec Generator

## Quick start

Given a set of markdown spec files in `docs/spec/` (typically produced by the `reverse-engineer-spec` skill), generate a single self-contained `dash2zero-functional-spec.html` (or `{project}-functional-spec.html`) with these features:

- Dark/light mode toggle
- Full-text search across all rules (Ctrl+K)
- Accordion sections grouped by capability
- Mermaid diagrams (architecture, state machines, sequences, ERDs) — each with hover controls: fullscreen (zoomable) viewer + SVG/PNG download
- Quick Reference card view with key facts
- Rule ID copy-to-clipboard
- Sidebar scroll spy
- Triage report with severity-colored table
- Stats bar (rule count, error codes, diagrams)

## Workflow

### 1. Gather the source material

Read all markdown spec files from `docs/spec/`. At minimum you need the area files (e.g., `authentication.md`, `companies-and-onboarding.md`, etc.) and the `README.md` index.

Identify from the files:
- Area names, prefixes, and descriptions
- Concepts tables (entity definitions)
- Rules with their IDs, text, and any ⚠️ confirm-intent markers
- Error code tables
- Permissions matrices
- Known gaps & quirks sections
- Any cross-references between rules

### 2. Design the diagrams

Create Mermaid diagrams covering these standard views (adapt to the project):

| Diagram | Type | What it shows |
|---|---|---|
| System architecture | `graph LR` | External systems → backend → frontend → DB |
| Core state machine | `stateDiagram-v2` | The project's primary state/status lifecycle |
| Key creation flow | `flowchart TD` | Decision tree for the main entity creation |
| Critical sequence | `sequenceDiagram` | The most important async/event flow |
| Event/side-effect lifecycle | `flowchart LR` | Statuses and their side effects |
| Entity relationships | `erDiagram` | Core entities, keys, and relationships |
| Processing modes | `flowchart TD` | Sync vs async paths, ordering |

Write Mermaid source directly in the HTML — the CDN-loaded Mermaid.js renders them client-side.

⚠️ **Quote node labels with special chars** (`{`, `}`, `(`, `)`, `/`, `+`, `:`). Unquoted braces break the parser — `A[PUT /companies/{nif}]` fails; write `A["PUT /companies/{nif}"]`. See REFERENCE.md → *Diagram authoring rules*.

### 3. Build the HTML

See `assets/template.html` for the complete base template. The template uses these patterns you must fill in:

**CSS variables** — Already provided; tweak colours to match the project's brand.

**Stats bar** — Replace counts with real numbers from the spec:
```html
<div class="stat-card"><div class="num">220+</div><div class="label">Behavior Rules</div></div>
```

**Mermaid diagrams** — 5-7 diagrams wrapped in:
```html
<div class="mermaid-wrap">
  <div class="mermaid">...mermaid source...</div>
  <div class="caption">Diagram Title</div>
</div>
```

**Area sections** — One `.area` div per spec file. Each contains:
- `.area-header` with title and DRAFT badge
- `.area-meta` with prefix and rule count
- Overview paragraph
- `.concepts-grid` with `.concept-card` items (extracted from Concepts table)
- `.accordion` groups with `.rule` items

**Rule markup:**
```html
<div class="rule" data-rule="AUTH-4" data-area="auth">
  <span class="rid" title="Click to copy">AUTH-4</span>
  <span class="content">Rule text with <code>code</code> and <strong>bold</strong>...</span>
</div>
```
For rules with ⚠️ Confirm intent markers, prepend:
```html
<span class="warn-tag">⚠ confirm</span>
```

**Quick Reference cards** — Extract key facts, thresholds, and formulas into `.qr-card` items grouped by area:
```html
<div class="qr-card" data-nav="area-auth">
  <h4>Card Title</h4>
  <div class="qr-body">Key facts with <strong>bold values</strong>.</div>
</div>
```

**Triage report** — Three severity tables (🔴 High, 🟡 Medium, 🟢 Low) extracted from the analysis phase.

### 4. Adapt the template

Key variables to change in the template:
- `<title>` — project name
- Sidebar header — project name + subtitle
- Area links — one per spec file, matching the actual area IDs
- Stats bar — actual counts from the spec
- `allRules` JS array — the `data-rule` and `data-area` values must match your markup

### 5. Deliver

Write the single HTML file to `docs/spec/{project}-functional-spec.html`. It's fully self-contained — no build step, no dependencies except the Mermaid CDN script.

## Customisation

See [REFERENCE.md](REFERENCE.md) for theming, adding custom diagrams, and advanced layout options.

## Prerequisites

This skill works best after running `reverse-engineer-spec` to produce the markdown spec files. If spec files don't exist yet, run that skill first.
