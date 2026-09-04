---
name: arch-docs
description: Generate architecture documentation for any project — Mermaid diagrams rendered to SVG, packaged as a self-contained HTML presentation with tabs, dark mode, and theme toggle. Use when user asks to document architecture, create architecture diagrams, generate project documentation, visualize system design, or wants an architecture presentation. Uses mermaid-studio for rendering.
---

# Architecture Documentation Generator

Generates a `docs/diagrams/` package: a tailored set of Mermaid diagrams (not always 3 — pick what the project actually needs), SVG renders, and a polished self-contained HTML presentation.

## Quick Start

**First run:**
```
Generate architecture docs for this project
```

**Re-run (idempotent):**
```
Update architecture docs
```

The skill automatically detects existing work and only updates what changed.

## Idempotency

This skill is idempotent — running it multiple times on the same project produces the same result without redundant work.

**Before creating or rendering anything**, compare the desired diagram set (from Step 0) against what already exists in `docs/diagrams/`. Follow this decision table for each diagram type:

| Exists? | Desired? | .mmd stale? | Action |
|---------|----------|-------------|--------|
| Yes | Yes | No | **Skip** — diagram is current |
| Yes | Yes | Yes (.mmd newer than .svg) | **Re-render SVG** only |
| Yes | No | — | **Remove** .mmd + .svg (orphaned diagram) |
| No | Yes | — | **Create** .mmd + render .svg |
| No | No | — | Nothing |

**Staleness check**: Compare file modification timestamps. If the `.mmd` file is newer than its `.svg`, the SVG is stale and needs re-rendering. If timestamps are unavailable (e.g. freshly cloned repo), re-render to be safe.

**HTML regeneration**: The HTML presentation is regenerated ONLY if:
- Any diagram file was created, removed, or re-rendered, OR
- The set of included diagrams changed (e.g. project grew from 2 to 3 diagrams), OR
- The HTML file doesn't exist

If nothing changed, leave the HTML untouched.

**Orphan cleanup**: If `docs/diagrams/` contains SVG files without corresponding `.mmd` sources, or diagram types no longer in the desired set, remove them.

## Workflow

### -1 — Check idempotency (always first)

Before any analysis or creation, check if `docs/diagrams/` already has content. If it does, you're in a re-run scenario. Note what exists, then proceed with Step 0 normally. After Step 0, compare desired vs existing and act per the idempotency table above. If everything matches and is current, report "Documentation is up-to-date" and stop — no further work needed.

### 0 — Decide how many diagrams

**Evaluate the project's shape before creating diagrams.** Not every project needs all three. Ask:

| Question | If YES | If NO |
|----------|--------|-------|
| Does the system have multiple containers/services talking to each other? | Include C4 Container diagram | Skip — a single monolith with no external integrations doesn't need it |
| Is there a non-trivial data pipeline, ingestion flow, or request lifecycle worth visualizing? | Include Data Flow diagram | Skip — CRUD apps with trivial request paths don't need it |
| Does the project have a backend with distinct layers (transport, logic, data, infra)? | Include Backend Layers diagram | Skip — thin backends, serverless functions, or proxy-only backends don't need it |
| Is there a prominent state machine driving core business logic? (e.g. order lifecycle, machine estado, approval flow) | Include State Diagram | Skip — stateless CRUD or implicit state doesn't need it |

**Typical mappings:**

| Project shape | Diagrams |
|---------------|----------|
| Full-stack app with backend + frontend + DB + external APIs | C4, Data Flow, Backend Layers (all 3) |
| Backend-only API with background jobs | C4 (if multi-service) or Backend Layers (if layered), Data Flow |
| Microservices / multi-container system | C4, Data Flow. Backend Layers only for the most interesting service |
| Static site or frontend-only SPA | None — just describe in prose. Don't generate Mermaid diagrams for a static site |
| Single monolith with no external integrations | Backend Layers only. C4 is redundant (one box). Data Flow only if pipeline is interesting |
| CLI tool or library | Skip diagrams entirely — describe architecture in markdown |

**If only 1–2 diagrams are needed**, generate only those `.mmd` files and their SVGs. The HTML template adapts — simply omit the sections for skipped diagrams.

**If no diagrams make sense**, stop after analysis and write a `docs/architecture.md` with prose descriptions instead. Don't generate empty diagram files.

### 1 — Analyze

Read `README.md`, `.specs/codebase/*.md`, `docker-compose.yml`. Explore `backend/`, `frontend/`, `src/`, or equivalent directory trees.

**Extract the tech stack systematically — do not guess badges.** Follow this procedure:

1. **Read dependency files**: `pyproject.toml`, `package.json`, `requirements.txt`, `Cargo.toml`, `go.mod`, etc.
2. **Categorize**: language/runtime, web framework, ORM, database, build tool, UI library, state management, routing, HTTP client, validation, key integrations, notable features (PWA, i18n, real-time, etc.).
3. **Select 8–12 badges** that define the project. Group them by context (Backend, Frontend, Integrations, Features — whichever categories make sense). Rules:
   - Always include: language + version, main backend framework, main frontend framework (if any), database, ORM (if present).
   - Include build tools, UI libraries, and state management only if they are prominent (e.g. Vite, Tailwind, Radix UI, TanStack Query).
   - Include integrations/features that are project-defining (e.g. OPC UA for factory monitoring, PWA for offline-first, i18n for multi-language).
   - Do NOT badge transitive deps (e.g. don't badge `@radix-ui/react-dialog` — badge `Radix UI`).
   - Do NOT badge test-only or dev-only tools (Vitest, ESLint, Ruff, pytest).
   - Do NOT badge every dependency — badge soup is worse than too few badges.
   - Use the canonical product name, not the package name: `Radix UI` not `@radix-ui/*`, `TanStack Query` not `@tanstack/react-query`.
4. **Order within groups**: language → framework → ORM → database (Backend). Language → build → styling → UI (Frontend). Key integrations → notable features (Features).
5. **Output as grouped HTML**: one `<div class="badge-group">` per context with a `<span class="badge-group-label">` label.

Extract: purpose, stack, architecture pattern, external integrations, data flow, module boundaries.

### 2 — Create the chosen diagrams

Create `docs/diagrams/` and write the `.mmd` files you decided on in Step 0. See [REFERENCE.md](REFERENCE.md) for exact patterns, syntax, and examples for each diagram type.

Key rules for every diagram:
- C4: max 5 elements, 4 edges, 1-line descriptions, `UpdateRelStyle` with `$textColor="#000"`
- Flowcharts: `LR` for widescreen, 1-2 line labels, use `classDef`+`class` for colored nodes (not `style`)
- All use `%%{init: {'theme': 'default'}}%%`

### 3 — Render SVGs

```bash
MERMAID="$HOME/.claude/skills/mermaid-studio"
node "$MERMAID/scripts/render.mjs" -i docs/diagrams/file.mmd -o docs/diagrams/file.svg
```

Do this for each `.mmd` file you created.

**After rendering, verify sizes** against the targets in [REFERENCE.md](REFERENCE.md):

```bash
python3 -c "
import re, os
for f in os.listdir('docs/diagrams'):
    if f.endswith('.svg'):
        svg = open('docs/diagrams/'+f).read()
        vb = re.search(r'viewBox=\"([^\"]+)\"', svg)
        if vb:
            parts = [float(x) for x in vb.group(1).split()]
            print(f'{f}: {int(parts[2])}x{int(parts[3])}')
"
```

If any diagram exceeds its target, reduce and re-render before continuing (see Troubleshooting in REFERENCE.md).

### 4 — Generate HTML presentation

Copy [TEMPLATE.html](TEMPLATE.html) to `docs/diagrams/architecture.html`. Replace all `{{PLACEHOLDERS}}` with project-specific content.

**Include only the sections for diagrams you actually created.** The template has three diagram sections wrapped in `<!-- DIAGRAM:xxx ... -->` boundary comments. Include or omit each section based on your Step 0 decision. Also update the nav links to match.

**CRITICAL**: Use `<object data="file.svg" type="image/svg+xml">` for all diagrams, NOT `<img>`. Browsers block `foreignObject` rendering in `<img>`-loaded SVGs — all Mermaid text labels use foreignObjects and will be invisible.

The nav section numbering auto-adjusts: if you skip C4, the first diagram section becomes section 2. Section 1 (Context) and the last section (Summary) are always present.

### 5 — Iterate

Open `architecture.html` in browser. If diagrams are messy:
- C4: cut elements, shorten labels, adjust `$c4ShapeInRow`
- Flowcharts: trim node labels, switch LR↔TD
- Backend: simplify subgraph nesting

## Output examples

**All 4 diagrams (full-stack app with state machine):**
```
docs/diagrams/
├── architecture-c4-container.mmd
├── architecture-c4-container.svg
├── sync-flow.mmd
├── sync-flow.svg
├── backend-layers.mmd
├── backend-layers.svg
├── estado-state-machine.mmd
├── estado-state-machine.svg
└── architecture.html
```

**All 3 diagrams (full-stack app, no state machine):**
```
docs/diagrams/
├── architecture-c4-container.mmd
├── architecture-c4-container.svg
├── sync-flow.mmd
├── sync-flow.svg
├── backend-layers.mmd
├── backend-layers.svg
└── architecture.html
```

**2 diagrams (backend with data pipeline, no frontend):**
```
docs/diagrams/
├── sync-flow.mmd
├── sync-flow.svg
├── backend-layers.mmd
├── backend-layers.svg
└── architecture.html
```

**1 diagram (simple layered backend only):**
```
docs/diagrams/
├── backend-layers.mmd
├── backend-layers.svg
└── architecture.html
```

**No diagrams (CLI tool, library, static site):**
```
docs/
└── architecture.md
```

## Reference

- Diagram patterns & syntax: [REFERENCE.md](REFERENCE.md)
- HTML template to customize: [TEMPLATE.html](TEMPLATE.html)
- SVG rendering: [../mermaid-studio/SKILL.md](../mermaid-studio/SKILL.md)
