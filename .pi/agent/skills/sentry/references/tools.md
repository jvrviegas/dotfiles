# Sentry CLI tools

All commands default to organization `procimo-tech-a7`. Most commands accept `limit` (default varies, max 100) and output parsed JSON.

```bash
~/.pi/agent/skills/sentry/scripts/sentry.js <tool> '<json-arguments>'
```

## Authentication

### `authenticate`

Returns the authenticated user and the prefilled organization details.

```bash
sentry.js authenticate
```

## Projects

### `list_projects`

Arguments:
- `limit` optional number
- `cursor` optional Sentry cursor

```bash
sentry.js list_projects '{"limit":50}'
```

### `get_project`

Arguments:
- `project` or `slug` required project slug

```bash
sentry.js get_project '{"project":"dms-backend"}'
```

## Issues / groups

### `list_issues`

Arguments:
- `project` optional project slug or numeric project id
- `query` optional Sentry search query, e.g. `is:unresolved`, `level:error`, `assigned:me`
- `statsPeriod` optional, e.g. `14d`, `24h`
- `sort` optional, e.g. `date`, `freq`, `new`, `user`
- `limit` optional
- `cursor` optional

```bash
sentry.js list_issues '{"project":"dms-backend","query":"is:unresolved","sort":"date","limit":10}'
```

### `get_issue`

Arguments:
- `id` or `issue` required numeric Sentry group/issue id

```bash
sentry.js get_issue '{"id":"1234567890"}'
```

### `update_issue`

Arguments:
- `id` or `issue` required
- `status` optional: `resolved`, `unresolved`, `ignored`
- `statusDetails` optional object
- `assignedTo` optional Sentry assignment string, e.g. `user:ID`, `team:ID`, or `null`
- `isBookmarked`, `hasSeen` optional booleans

```bash
sentry.js update_issue '{"id":"1234567890","status":"resolved"}'
```

## Events

### `list_issue_events`

Arguments:
- `issue` or `id` required numeric group id
- `limit` optional
- `cursor` optional

```bash
sentry.js list_issue_events '{"issue":"1234567890","limit":5}'
```

### `get_issue_event`

Arguments:
- `issue` or `id` required numeric group id
- `event` or `eventId` required event id

```bash
sentry.js get_issue_event '{"issue":"1234567890","event":"abcdef123"}'
```

### `list_project_events`

Arguments:
- `project` required project slug
- `query`, `statsPeriod`, `full`, `limit`, `cursor` optional

```bash
sentry.js list_project_events '{"project":"dms-backend","query":"level:error","statsPeriod":"24h","limit":10}'
```

### `get_event`

Arguments:
- `project` required project slug
- `event` or `eventId` required event id

```bash
sentry.js get_event '{"project":"dms-backend","event":"abcdef123"}'
```

## Releases

### `list_releases`

Arguments:
- `project` optional project slug
- `query`, `limit`, `cursor` optional

```bash
sentry.js list_releases '{"project":"dms-frontend","limit":10}'
```

### `get_release`

Arguments:
- `version` or `release` required release version

```bash
sentry.js get_release '{"version":"dms@1.2.3"}'
```

## Organization

### `list_organization_members`

Arguments:
- `limit`, `cursor` optional

### `organization_stats`

Arguments:
- `stat` optional, default `received`
- `since`, `until`, `resolution` optional Unix timestamp/resolution values supported by Sentry

```bash
sentry.js organization_stats '{"stat":"received","resolution":"1d"}'
```

## Escape hatch

### `request`

Arguments:
- `method` optional, default `GET`
- `path` required API path, e.g. `/organizations/procimo-tech-a7/issues/`
- `query` optional object of query parameters
- `body` optional JSON body

```bash
sentry.js request '{"method":"GET","path":"/organizations/procimo-tech-a7/issues/","query":{"query":"is:unresolved","per_page":10}}'
```
