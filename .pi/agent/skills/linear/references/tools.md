# Linear CLI tool reference

All commands use:

```bash
~/.pi/agent/skills/linear/scripts/linear.js TOOL '{"json":"args"}'
```

## Common reads

```bash
linear.js list_teams '{"query":"carbon","limit":50,"cursor":"next-cursor","orderBy":"updatedAt","includeArchived":false}'
linear.js list_projects '{"team":"Procimo Tech","limit":50}'
linear.js get_project '{"query":"Dash2Zero","team":"Carbon Products"}'
linear.js list_milestones '{"project":"Plastaze - MES"}'
linear.js list_initiatives '{"limit":50}'
linear.js list_issue_statuses '{"team":"Procimo Tech","limit":50,"cursor":"next-cursor","orderBy":"updatedAt"}'
linear.js list_users '{"query":"joao","team":"Procimo Tech","limit":50,"cursor":"next-cursor","orderBy":"updatedAt"}'
linear.js get_user '{"query":"me"}'
linear.js list_issue_labels '{"team":"Procimo Tech","name":"bug","limit":50,"cursor":"next-cursor","orderBy":"updatedAt"}'
linear.js list_project_labels '{"name":"roadmap","limit":50,"cursor":"next-cursor","orderBy":"updatedAt"}'
linear.js list_cycles '{"team":"Procimo Tech"}'
```

## Issues

```bash
linear.js get_issue '{"id":"CP-299"}'
linear.js list_issues '{"team":"Carbon Products","project":"Dash2Zero","state":"Triage","milestone":"Simple/PRO Integration","label":"bug","priority":1,"query":"swagger","limit":25,"cursor":"next-cursor","orderBy":"updatedAt","includeArchived":false}'
linear.js save_issue '{"team":"Carbon Products","title":"New issue","description":"...","project":"Dash2Zero","state":"Triage","assignee":"Jane Doe","delegate":"me","labels":["bug"],"priority":2}'
linear.js save_issue '{"id":"CP-299","state":"Done","assignee":"João","description":"Updated"}'
linear.js save_issue '{"id":"CP-299","links":[{"url":"https://example.com","title":"Reference"}],"blocks":["CP-300"],"blockedBy":["CP-301"],"relatedTo":["CP-302"],"duplicateOf":"CP-303"}'
linear.js save_issue '{"id":"CP-299","assignee":null,"delegate":null,"cycle":null,"parentId":null,"estimate":null,"duplicateOf":null,"removeBlocks":["CP-300"],"removeBlockedBy":["CP-301"],"removeRelatedTo":["CP-302"]}'
```

Useful issue fields: `title`, `description`, `team`, `project`, `state`, `assignee`, `delegate`, `labels`, `priority`, `estimate`, `cycle`, `milestone`, `parent`/`parentId`, `relatedTo`, `blocks`, `blockedBy`, `duplicateOf`, `removeBlocks`, `removeBlockedBy`, `removeRelatedTo`, `links`, `dueDate`.

`list_issues` supports team/project/state/assignee/delegate/milestone/label/labels/priority/parentId/query filters, `createdAt`/`updatedAt` comparators, `cursor`, `orderBy`, and `includeArchived`.

## Comments

```bash
linear.js list_comments '{"issue":"CP-299","limit":50,"cursor":"next-cursor","orderBy":"updatedAt"}'
linear.js list_comments '{"project":"My Project"}'
linear.js list_comments '{"initiative":"My Initiative"}'
linear.js list_comments '{"documentId":"document-uuid-or-slug"}'
linear.js list_comments '{"milestoneId":"milestone-uuid"}'
linear.js save_comment '{"issue":"CP-299","body":"Status update..."}'
linear.js save_comment '{"project":"My Project","body":"Project discussion..."}'
linear.js save_comment '{"parentId":"comment-uuid","body":"Reply..."}'
linear.js save_comment '{"id":"comment-uuid","body":"Edited body"}'
linear.js delete_comment '{"id":"comment-uuid"}'
```

## Projects, milestones, and initiatives

```bash
linear.js list_projects '{"team":"Carbon Products","query":"Dash","state":"Planned","member":"me","label":"roadmap","createdAt":{"gte":"2026-01-01"},"updatedAt":"2026-01-01","limit":50,"cursor":"next-cursor","orderBy":"updatedAt","includeMilestones":false,"includeMembers":false,"includeArchived":false}'
linear.js get_project '{"query":"Dash2Zero","team":"Carbon Products","includeMilestones":true,"includeMembers":true,"includeResources":true}'
linear.js save_project '{"team":"Procimo Tech","name":"My Project","summary":"Short summary","description":"Markdown project brief...","state":"Planned","icon":"Rocket","color":"#00ff00","priority":2}'
linear.js save_milestone '{"project":"My Project","name":"MVP","targetDate":"2026-06-01"}'
linear.js save_milestone '{"id":"milestone-uuid","name":"MVP renamed"}'
linear.js list_initiatives '{"query":"growth","limit":20}'
linear.js get_initiative '{"query":"initiative-name-or-slug"}'
linear.js save_initiative '{"name":"My Initiative","description":"...","leadTeam":"Procimo Tech"}'
```

Project reads use `slugId` and `projectMilestones` internally. `save_project` accepts `state` as a backwards-compatible alias for current Linear project `statusId`, plus `addTeams`/`removeTeams`/`setTeams`, `labels`, `lead`, and initiative add/remove/set fields.

## Documents

```bash
linear.js list_documents '{"project":"My Project","team":"Procimo Tech","query":"spec","createdAt":{"gte":"2026-01-01"},"updatedAt":"2026-01-01","cursor":"next-cursor","orderBy":"updatedAt","includeArchived":false}'
linear.js list_documents '{"issue":"CP-299","limit":10}'
linear.js get_document '{"id":"document-uuid-or-slug"}'
linear.js save_document '{"project":"My Project","title":"Spec","content":"# Spec\n...","icon":"Rocket","color":"#00ff00"}'
linear.js save_document '{"issue":"CP-299","title":"Issue notes","content":"..."}'
linear.js save_document '{"team":"Procimo Tech","title":"Team doc","content":"..."}'
linear.js save_document '{"team":"Procimo Tech","cycle":"1","title":"Cycle doc","content":"..."}'
linear.js save_document '{"id":"document-uuid","content":"Updated","initiative":"My Initiative"}'
```

## Attachments/status updates/customers

Attachments support both the official direct-upload workflow and the older URL-link path:

```bash
# Official file upload workflow:
linear.js prepare_attachment_upload '{"issue":"CP-299","filename":"screenshot.png","contentType":"image/png","size":12345}'
# PUT raw bytes to uploadRequest.url with every returned header, then:
linear.js create_attachment_from_upload '{"issue":"CP-299","assetUrl":"https://uploads.linear.app/...","title":"Screenshot"}'

# Convenience fallback: uploads base64/file content, then links the uploaded asset.
linear.js create_attachment '{"issue":"CP-299","base64Content":"...","filename":"screenshot.png","contentType":"image/png"}'
linear.js create_attachment '{"issue":"CP-299","path":"/tmp/screenshot.png","contentType":"image/png"}'

# Backwards-compatible URL attachment path:
linear.js create_attachment '{"issue":"CP-299","title":"PR","url":"https://github.com/..."}'

linear.js save_status_update '{"type":"project","project":"My Project","body":"Weekly update","health":"onTrack"}'
linear.js save_status_update '{"type":"project","id":"project-update-uuid","body":"Edited update"}'
linear.js get_status_updates '{"type":"project","project":"My Project"}'
linear.js list_customers '{"limit":10}'
linear.js save_customer '{"name":"Acme","domains":["acme.com"],"revenue":100000}'
```

## Diffs

```bash
linear.js list_diffs '{"limit":10,"orderBy":"updatedAt"}'
linear.js get_diff '{"urlOrId":"https://github.com/org/repo/pull/123"}'
linear.js get_diff_threads '{"urlOrId":"https://github.com/org/repo/pull/123","resolved":false}'
```

Diff tools are bridged to Linear MCP because Linear GraphQL does not expose top-level diff/review objects to this CLI. With a personal API key, Linear MCP may return `invalid_request`; in that case the CLI returns `{ "unsupported": true, ... }` with the MCP error details instead of fabricating data.

## Documentation/images

```bash
linear.js search_documentation '{"query":"projects","page":0}'
linear.js extract_images '{"markdown":"![screenshot](https://uploads.linear.app/...)"}'
```

These route through Linear MCP when a token is available. Without a token, `search_documentation` returns a docs search URL and `extract_images` returns markdown image URLs only.

## Raw GraphQL

Use this when Linear adds fields before the skill is updated:

```bash
linear.js query '{"query":"query($first:Int){ teams(first:$first){ nodes { id name key } } }","variables":{"first":5}}'
```

Raw GraphQL guardrails:

- Project slugs are exposed as `slugId`, not `slug`.
- Project milestones are exposed as `projectMilestones`, not `milestones`.
- Avoid high-fanout project queries that fetch teams, status, milestones, and resources for many projects at once; split them into `list_projects`, `get_project`, and `list_milestones` calls to avoid Linear query-complexity errors.
