# Linear skill patch tracker

Last verified: 2026-06-24

This document tracks the work needed to bring `~/.pi/agent/skills/linear` back in sync with Linear's live MCP server and current GraphQL API.

## Sources of truth

- Local skill files:
  - `SKILL.md`
  - `references/tools.md`
  - `scripts/linear.js`
- Live Linear MCP server: `https://mcp.linear.app/mcp`
  - `tools/list` returned 46 tools on 2026-06-24.
- Local smoke test result:
  - Auth works.
  - 2026-06-24 P0 read-path patch: `node --check` passed.
  - `list_teams`, `list_users`, `list_projects`, `get_project`, `list_issues`, `list_documents`, `list_customers`, `get_status_updates`, `list_initiatives`, and the reported `list_issues` team/project/milestone combinations passed read-only smoke tests.
  - Mutation schema was checked with bogus IDs for status updates, customers, and initiatives.
  - `save_customer` create with `domains` succeeded during schema validation and the test customer was immediately deleted; follow-up query confirmed no `Schema Check Customer` remains.
  - Guarded mutation smoke is still needed for status update create/archive and initiative create/update.
  - 2026-06-24 attachment/diff patch: `prepare_attachment_upload` returned a signed upload request for an existing issue without creating an attachment; `list_diffs`, `get_diff`, and `get_diff_threads` return structured `unsupported` responses when Linear MCP returns `invalid_request` for this API token.
  - 2026-06-24 issue listing patch: `list_issues` smoked with `cursor`, `orderBy`, `includeArchived`, singular `label`, `priority`, `delegate`, `parentId`, `createdAt`, and `updatedAt`.
  - 2026-06-24 issue save patch: `save_issue` schema checked with null-clearing fields, `delegate:"me"`, links, relation adds, duplicate, and relation removals against a bogus issue ID. Guarded throwaway mutation smoke later verified issue link attachment, blocks/blockedBy/related/duplicate relation add/remove, and comment create/update/delete.
  - 2026-06-24 project save patch: `save_project` schema checked status/state alias, summary/content, icon/color/priority, date resolutions, lead null clearing, setTeams, and labels against bogus project IDs. Guarded throwaway mutation smoke later verified initiative create/update, project create/update, initiative add/remove links, and status update create/update/archive.
  - 2026-06-24 project read patch: `list_projects` smoked with team/query/status/member/date/include filters; `get_project` smoked optional milestones, members, and resources.
  - 2026-06-24 document patch: `list_documents` smoked global/project/team/issue/date filters; `save_document` schema checked project target plus icon/color against a bogus document ID.
  - 2026-06-24 comments patch: `list_comments` smoked issue/project/document/milestone filters; `save_comment` update schema checked with a bogus comment ID.
  - 2026-06-24 simple list patch: `list_teams`, `get_team`, `list_users`, `get_user`, `list_issue_statuses`, `get_issue_status`, `list_issue_labels`, and `list_project_labels` smoked with current filters/pagination args.
  - 2026-06-24 pagination patch: `list_milestones`, `list_cycles`, `list_customers`, `list_initiatives`, and `get_status_updates` smoked with `cursor`-capable connection shapes plus `orderBy`/`includeArchived`.
  - 2026-06-24 docs/images patch: `search_documentation` and `extract_images` smoked through Linear MCP with local no-token fallbacks retained.
- Additional validation from reported agent errors:
  - `ProjectFilter` has no `team` field. Use `accessibleTeams: { some: { id: { eq: TEAM_ID } } }` for project team filtering.
  - `Project` has `slugId`, not `slug`.
  - `Project` has `projectMilestones`, not `milestones`.
  - `ProjectMilestoneFilter` supports `name` and `project`, so milestone resolution should search by name and optionally scope by project.
  - Large nested raw project queries can return `Query too complex`; the CLI should avoid high-fanout nested defaults and docs should steer agents to split reads.

## Target outcome

The Linear skill should either:

1. Implement every live official MCP tool name exposed by Linear, or
2. Explicitly document any tool that cannot be implemented through Linear GraphQL and route it through another supported mechanism.

`SKILL.md` now describes this as an MCP-style CLI. Local switch cases cover every live MCP tool name verified on 2026-06-24; `authenticate` and `query` remain local extras.

## Live official MCP tools missing locally

None as of the 2026-06-24 parity check. Previously missing tools now implemented or bridged:

- [x] `prepare_attachment_upload` — implemented in `scripts/linear.js` on 2026-06-24
- [x] `create_attachment_from_upload` — implemented in `scripts/linear.js` on 2026-06-24
- [x] `get_diff` — MCP bridge with structured unsupported fallback implemented on 2026-06-24
- [x] `list_diffs` — MCP bridge with structured unsupported fallback implemented on 2026-06-24
- [x] `get_diff_threads` — MCP bridge with structured unsupported fallback implemented on 2026-06-24
- [x] `list_initiatives` — implemented in `scripts/linear.js` on 2026-06-24
- [x] `get_initiative` — implemented in `scripts/linear.js` on 2026-06-24
- [x] `save_initiative` — implemented in `scripts/linear.js` on 2026-06-24

## Patch tasks

| ID | Priority | Status | Area | Change needed | Acceptance check |
| --- | --- | --- | --- | --- | --- |
| LSK-001 | P0 | [x] | Project reads | Replace `milestones` with `projectMilestones` in `get_project`. Accept official `query` arg as alias for `id`/`project`. | `linear.js get_project '{"query":"<project>"}'` succeeds. |
| LSK-002 | P0 | [x] | Customers | Replace `domain` with `domains` in customer fields. Update `save_customer` to accept `domains`, `externalIds`, `owner`, `status`, `tier`, `revenue`, `size`. | `linear.js list_customers '{"limit":1}'` succeeds. |
| LSK-003 | P0 | [x] | Status updates | Replace nonexistent `projectUpdateDelete` with archive/delete equivalent. Support `id` updates via `projectUpdateUpdate`. Support official required `type` arg. | Guarded mutation smoke verified create/update/archive. |
| LSK-004 | P0 | [x] | Tool parity | Add missing initiative commands: `list_initiatives`, `get_initiative`, `save_initiative`. Add resolver for initiatives. | Guarded mutation smoke verified create/update; read/list smoke passed. |
| LSK-005 | P0 | [x] | Tool parity | Add missing diff commands: `get_diff`, `list_diffs`, `get_diff_threads`. First verify whether public GraphQL exposes the required diff/review objects. If not, implement an MCP bridge or document limitation. | Commands return useful data or a documented unsupported response with rationale. |
| LSK-006 | P0 | [x] | Attachments | Align attachment tools with official MCP schema: `prepare_attachment_upload`, `create_attachment_from_upload`, and base64/file `create_attachment`. Preserve URL-link attachment support if useful via a separate alias or backwards-compatible path. | File upload workflow documented and smoke-tested with a small fixture or dry-run-safe command. |
| LSK-007 | P1 | [x] | Issues/listing | Implement official list filters: `cursor`, `orderBy`, singular `label`, `delegate`, `priority`, `parentId`, `createdAt`, `updatedAt`, `includeArchived`. Fix documented `labels` mismatch. | `list_issues` honors label/project/team/state filters and pagination args. |
| LSK-008 | P1 | [x] | Issues/saving | Add official save fields: `delegate`, `links`, `blocks`, `blockedBy`, `duplicateOf`, `removeBlocks`, `removeBlockedBy`, `removeRelatedTo`; support null-clearing where official schema allows it. Ensure relations can be added on both create and update. | Guarded throwaway mutation smoke verified links, relations, removals, and cleanup. |
| LSK-009 | P1 | [x] | Projects | Replace deprecated project `state` implementation with `status/statusId` resolution while preserving `state` as an input alias if needed. Add official project args: `summary`, `icon`, `color`, `priority`, date resolutions, add/remove/set teams, labels, initiatives. | Guarded project mutation smoke verified create/update and initiative links; project delete archives/trashes per Linear semantics. |
| LSK-010 | P1 | [x] | Project reads/listing | Add official args for `list_projects`/`get_project`: `cursor`, `orderBy`, `query`, `state`, `initiative`, `member`, `label`, date filters, `includeMilestones`, `includeMembers`, `includeResources`, `includeArchived`. Do not fetch nested milestones/resources by default because large nested project queries can exceed Linear complexity limits. | Read commands return expected optional sections only when requested. |
| LSK-011 | P1 | [x] | Documents | Implement official document filters and targets: project, issue, initiative, cycle, team, icon, color, cursor/order/date filters. Current docs say project filtering works, but code ignores it. | `list_documents '{"projectId":"..."}'` or equivalent filter narrows results. |
| LSK-012 | P1 | [x] | Comments | Support official comment targets and filters: issue/project/initiative/document/milestone, parent comments, cursor/order. Preserve old `issue` alias. | `list_comments` and `save_comment` work for issue comments and expose supported alternate targets. |
| LSK-013 | P1 | [x] | Users/teams/statuses/labels | Add official query/pagination/filter args where missing. Replace deprecated `Team.private` with `visibility` in team fields. | `list_teams`, `get_team`, `list_users`, `get_user`, status/label commands match official arg names. |
| LSK-014 | P2 | [x] | Pagination | Generalize connection helper to accept `cursor`, `orderBy`, and `includeArchived` where supported instead of hard-coded `first/after/filter` only. | All list commands accept at least `limit` and `cursor`; output includes `pageInfo`. |
| LSK-015 | P2 | [x] | Docs search/images | Align `search_documentation` and `extract_images` behavior with official MCP schemas. Current implementations are minimal stubs. | Tool docs honestly describe behavior, or implementation fetches real docs/images. |
| LSK-016 | P2 | [x] | Backwards compatibility | Keep existing commonly used aliases: `issue`/`issueId`, `body`/`comment`, `state`/`status`, `team`/`teamId`, `project`/`projectId`. Note aliases in docs. | Existing examples in `SKILL.md` still work. |
| LSK-017 | P2 | [x] | Documentation | Update `SKILL.md` tool list and examples. Update `references/tools.md` with official args, upload workflow, initiative/diff examples, and known limitations. | Docs match CLI behavior and live tool list. |
| LSK-018 | P2 | [x] | Verification | Add or document a repeatable smoke-test command set for safe read-only coverage plus guarded mutation tests. | `node --check scripts/linear.js` and smoke-test checklist pass. |
| LSK-019 | P0 | [x] | Project team filtering | Fix project filtering/resolution by team. Current code sends `ProjectFilter.team`, which Linear rejects. Use `ProjectFilter.accessibleTeams.some.id.eq` for team-scoped `list_projects` and project resolution. | `linear.js list_projects '{"team":"Carbon Products","limit":100}'` succeeds and returns Carbon Products projects. |
| LSK-020 | P0 | [x] | Milestone resolution | Replace first-page-only milestone resolution with filtered/paginated lookup. Use `ProjectMilestoneFilter.name` and, when available, `project.id`; pass `projectId` from issue filters into milestone resolution. | `linear.js list_issues '{"team":"Carbon Products","project":"Dash2Zero","milestone":"Simple/PRO Integration","state":"Backlog","limit":100}'` and the same command without `project` do not fail during resolution. |
| LSK-021 | P1 | [x] | Query complexity/schema guardrails | Add docs and safer helper behavior for raw GraphQL pitfalls: `slugId` not `slug`, `projectMilestones` not `milestones`, avoid large nested project + teams + milestones queries. Prefer `list_projects` for project summaries and `list_milestones`/`get_project includeMilestones` for scoped detail. | `references/tools.md` contains safe alternatives; optional include flags implemented in LSK-010. |

## Reported error validation

| Reported command/error | Will current patch plan fix it? | Tracker coverage |
| --- | --- | --- |
| `list_projects '{"team":"Carbon Products","limit":100}'` → `Field "team" is not defined by type "ProjectFilter"` | Not fully before this update. Now explicitly covered. | LSK-019 |
| Raw `query` using `Project.slug` and `Project.milestones` → missing fields | Partially covered by LSK-001 for `get_project`; raw GraphQL passthrough cannot rewrite arbitrary queries. Added docs/guardrails. | LSK-001, LSK-021 |
| Raw query with `status`, `teams`, `projectMilestones(first:50)` for 100 projects → `Query too complex` | Not covered before. Add safer default behavior and docs to split this into smaller reads. | LSK-010, LSK-021 |
| `list_issues` with `team` + `project` + `milestone` → same `ProjectFilter.team` error while resolving project | Now covered by fixing team-scoped project resolution and milestone scoping. | LSK-019, LSK-020 |
| `list_issues` with `milestone` only → `Could not resolve milestone` | Not covered before. Add filtered/paginated milestone lookup by name, optionally project-scoped. | LSK-020 |

## Known broken lines in current `scripts/linear.js`

- No known code-level parity gaps remain after guarded mutation smoke. Project/initiative deletes archive/trash records per Linear semantics; active searches confirmed throwaway records are absent.
- `save_issue` relationship fields are implemented but still need a guarded throwaway issue mutation test for end-to-end relation/link behavior.
- No P0 read-path, attachment, or diff parity gaps remain open in code. Guarded mutation/E2E smoke is still pending for some write paths.

## Fixed in the 2026-06-24 P0 read-path patch

- `projectFields` now uses `status` instead of removed `state`.
- `teamFields` now uses `visibility` instead of removed `private`.
- `get_project` now queries `projectMilestones` and accepts `query`.
- Project filtering/resolution by team now uses `ProjectFilter.accessibleTeams.some`.
- Milestone resolution uses `ProjectMilestoneFilter.name`, optional `project`, and pagination.
- `list_customers` now queries `domains`; `save_customer` accepts richer current customer fields.
- `delete_status_update` now uses `projectUpdateArchive`; `save_status_update` supports `id` updates.

## Fixed in the 2026-06-24 attachment/diff patch

- Added `prepare_attachment_upload` with Linear `fileUpload` signed upload requests.
- Added `create_attachment_from_upload` to link uploaded `assetUrl` values.
- Extended `create_attachment` with base64/file upload support while preserving URL-link attachments.
- Added `get_diff`, `list_diffs`, and `get_diff_threads` through a Linear MCP bridge with a structured unsupported fallback when MCP returns `invalid_request` for this token/request.
- Initiative field selection avoids org feature-gated fields (`identifier`, labels, priority) so basic initiative commands work when optional initiative features are disabled.

## Fixed in the 2026-06-24 issue listing patch

- `list_issues` now supports `cursor`, `orderBy`, `includeArchived`, singular `label`, `labels`, `delegate`, `priority`, `parentId`, `createdAt`, and `updatedAt`.
- Label filters use `IssueFilter.labels.some.id.in`; project/team/state/milestone filters continue to work.

## Implemented in the 2026-06-24 issue save patch

- `save_issue` now accepts `delegate`, `links`, `blocks`, `blockedBy`, `duplicateOf`, `removeBlocks`, `removeBlockedBy`, and `removeRelatedTo`.
- `save_issue` preserves `null` for supported clearing fields: `assignee`, `delegate`, `cycle`, `parentId`, `estimate`, and `duplicateOf` relation removal.
- User resolver now supports `"me"`.

## Implemented in the 2026-06-24 project save patch

- `save_project` maps `state`/`status` to current Linear `statusId`; it no longer sends removed/deprecated `state` input.
- Added `summary`, Markdown `description`/`content`, `icon`, `color`, `priority`, `startDateResolution`, `targetDateResolution`, project labels, `lead` null clearing, team set/add/remove, and initiative set/add/remove support.

## Fixed in the 2026-06-24 project read patch

- `list_projects` now supports `cursor`, `orderBy`, `query`, `state`/`status`, `initiative`, `member`, `label`, `createdAt`, `updatedAt`, `includeMilestones`, `includeMembers`, and `includeArchived`.
- `get_project` now keeps milestones/members/resources optional via `includeMilestones`, `includeMembers`, and `includeResources` instead of fetching high-fanout nested data by default.

## Fixed in the 2026-06-24 document patch

- `list_documents` now supports project, issue, initiative, cycle, team, creator, query, `cursor`, `orderBy`, created/updated date filters, and `includeArchived`.
- `save_document` now supports project, issue, initiative, cycle, and team targets plus `icon` and `color`.

## Fixed in the 2026-06-24 comments patch

- `list_comments` now supports issue, project, initiative, document, milestone, parent comment, cursor, order, and includeArchived filters.
- `save_comment` now supports issue, project, initiative, document, milestone, and parent reply targets while preserving the old `issue` alias.

## Fixed in the 2026-06-24 simple list patch

- `list_teams`, `list_users`, `list_issue_statuses`, `list_issue_labels`, and `list_project_labels` now support current query/pagination/filter args where available.
- `get_team` and `get_user` now accept official `query`; `get_user {"query":"me"}` resolves to the viewer.

## Fixed in the 2026-06-24 pagination patch

- Added a paged connection helper with `cursor`/`orderBy`/`includeArchived` support.
- Applied it to milestones, cycles, customers, initiatives, and project status updates.

## Fixed in the 2026-06-24 docs/images patch

- `search_documentation` and `extract_images` now use Linear MCP when a token is available.
- Both tools retain explicit fallback behavior without a token instead of pretending to fetch full MCP results.

## Verification checklist

Run after patching:

```bash
node --check "$HOME/.pi/agent/skills/linear/scripts/linear.js"

CLI="$HOME/.pi/agent/skills/linear/scripts/linear.js"
$CLI authenticate
$CLI list_teams '{"limit":1}'
$CLI list_users '{"limit":1}'
$CLI list_projects '{"limit":1}'
$CLI list_projects '{"team":"Carbon Products","limit":100}'
$CLI get_project '{"query":"Dash2Zero","team":"Carbon Products"}'
$CLI list_issues '{"limit":1,"orderBy":"updatedAt","includeArchived":false}'
$CLI list_issues '{"team":"Carbon Products","project":"Dash2Zero","milestone":"Simple/PRO Integration","state":"Backlog","limit":100}'
$CLI list_issues '{"team":"Carbon Products","milestone":"Simple/PRO Integration","state":"Backlog","limit":100}'
$CLI list_issues '{"team":"Carbon Products","label":"<visible-label>","priority":1,"limit":1}'
$CLI list_documents '{"limit":1}'
$CLI list_customers '{"limit":1}'
$CLI get_status_updates '{"type":"project","limit":1}'
$CLI list_initiatives '{"limit":1}'
$CLI prepare_attachment_upload '{"issue":"<visible-issue>","filename":"dryrun.png","contentType":"image/png","size":68}'
$CLI list_diffs '{"limit":1}'
$CLI get_diff_threads '{"urlOrId":"not-real"}'
$CLI search_documentation '{"query":"projects","page":0}'
$CLI extract_images '{"markdown":"![alt](https://example.com/a.png)"}'
```

Optional parity check against live MCP:

```bash
# Requires LINEAR_API_KEY or Keychain token.
# Fetch tools/list from https://mcp.linear.app/mcp and compare names against SKILL.md + CLI switch cases.
# 2026-06-24 result: live count 46, local switch count 48 (extras: authenticate, query), missing local: none.
```

## Definition of done

- [x] `scripts/linear.js` passes syntax check.
- [x] Every live MCP tool is implemented or explicitly documented as unsupported with rationale.
- [x] Read-only smoke tests pass.
- [x] At least one guarded mutation path is tested for issue/comment/status update changes. Throwaway mutation smoke verified status update create/update/archive, issue relation/link add/remove, comment create/update/delete, initiative create/update, and project initiative links. Throwaway projects/initiatives are archived/trashed by Linear delete semantics; active searches confirmed none remain.
- [x] `SKILL.md` and `references/tools.md` reflect actual behavior.
- [x] The MCP-equivalent claim is accurate after the patch: docs now say MCP-style and note bridged/unsupported diff behavior.
