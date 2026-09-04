---
name: doc-process
description: Procimo's two-layer documentation process plus both templates — Layer 1 Feature Specs (Linear, max 2 pages, dies on ship) and Layer 2 Living Functional Specs (docs/spec/*.md, permanent, updated in the same PR that changes behavior). Load this as base context whenever writing or reviewing a spec, PRD, feature brief, acceptance criteria, behavior rule, or docs/spec/ change; when starting a new spec or docs/spec/ area file from a template; when deciding which layer something belongs in; when checking a PR for spec updates; or when the user says "doc process", "documentation process", "spec process", "feature spec template", "which layer", "/doc-process".
---

# Procimo Documentation Process

## Files in this skill

| File | What | Upstream source |
|---|---|---|
| `reference.md` | Full process text | Drive doc `1jqEFkDzzCeEA2ynnOloWi-mrE-JySGWMrr3tg09vW3c` ("01_Documentation Process — Requirements & Functional Specs", owner: Product) |
| `templates/feature-spec.md` | Layer 1 template | Drive doc `13I1uhCkGKO0ivrBxzhOUcKM7kK-D_kNssScXnbLqrPY` ("00_TEMPLATE — Feature Spec (Layer 1)", in `04_PRODUCT / 03_PRD (Specs)`) |
| `templates/functional-spec-area.md` | Layer 2 area-file template | `dms-backend/docs/spec/_template.md` (git; locally `~/Projects/Procimo/dms/codebase/dms-backend/docs/spec/_template.md`) |

Local copies synced **2026-07-30**. Drive `modifiedTime` at sync: process doc
`2026-07-16T09:42:14.618Z`, Layer 1 template `2026-07-16T08:41:56.600Z`.

Note: a second Drive doc with the identical title `00_TEMPLATE — Feature Spec
(Layer 1)` (id `15YKw--QB3qhYJ8R44lUrhvfRvXc5sx2JDkHdFNY_6iM`) sits in João's My
Drive — a personal copy, **not** canonical. Always use the `03_PRD (Specs)` one.

## Use

Read `reference.md` — full process text. Apply it as the base constraints for
whatever spec work is at hand.

Starting a new document? Read the matching file in `templates/` and fill it in —
do not invent structure. Layer 1 → `templates/feature-spec.md` (and remind the
PM the real artifact lives in Linear, or as a Drive copy of the template doc).
Layer 2 → `templates/functional-spec-area.md`, written to `docs/spec/<area>.md`
in the product repo.

The five rules that decide most questions:

1. Behavior is only true in **Layer 2** (living spec). Feature Specs are proposals; never cite an old PRD as truth.
2. Feature Spec = **max 2 pages, hard rule**. Dies (archived in Linear) when the feature ships.
3. Every behavior is a **testable rule**, one per bullet, numbered with an area prefix (`COMP-14`, `ENT-4`): "When [condition], the system [does Z]." Can't imagine the test → rewrite it.
4. A PR that changes behavior **updates `docs/spec/` in that same PR**. Treated like missing tests — tech lead blocks the merge.
5. Small changes and bug fixes **skip Layer 1** entirely.

## Drift check

Upstreams change without notice (the process doc and Layer 1 template are owned
by Product; the Layer 2 template moves with the repo). Before relying on exact
wording — quoting the process to someone, or when the user says something changed
— verify, then refresh whichever copies are stale:

**Drive copies** (process doc, Layer 1 template):

1. `mcp__claude_ai_Google_Drive__get_file_metadata` per `fileId` above with
   `excludeContentSnippets: true` (~200 tokens each).
2. Compare `modifiedTime` against the sync timestamps above.
3. If newer: `mcp__claude_ai_Google_Drive__read_file_content` on that `fileId`,
   overwrite the local file, update the timestamps in this file. Report what changed.

**Layer 2 template** (git, not Drive — no `modifiedTime` to compare):
`diff` against `~/Projects/Procimo/dms/codebase/dms-backend/docs/spec/_template.md`
when that repo is present, and copy over if it moved. Absent repo → bundled copy
stands; say so rather than guessing.

Skip all of this for routine "apply the process" work — bundled copies are enough.
