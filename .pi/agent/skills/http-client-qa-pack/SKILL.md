---
name: http-client-qa-pack
description: Generates rest.nvim HTTP-client QA packs with a README, .http request file, and sample-data folder for backend/API testing. Use when the user asks to create QA/testing HTTP files, reproduce API acceptance criteria manually, or scaffold requests under http-client/ for a Linear issue such as CP-174.
---

# HTTP Client QA Pack

Create a small, repeatable QA pack under `http-client/<issue-or-feature>/` for manual API validation with rest.nvim.

## Quick start

When the user asks for QA files:

1. If an issue key is given, fetch the issue details from Linear when available.
2. Inspect existing `http-client/README.md`, env examples, and nearby `.http` conventions.
3. Create:
   - `http-client/<slug>/README.md`
   - `http-client/<slug>/<slug-or-feature>.http`
   - `http-client/<slug>/sample-data/*.json` when payloads are non-trivial
4. Update `http-client/README.md` organization list if this is a new folder.

Optional scaffold command:

```bash
node "$HOME/.pi/agent/skills/http-client-qa-pack/scripts/scaffold.js" \
  --root http-client \
  --slug cp-174 \
  --issue CP-174 \
  --title "Onboarding state machine QA"
```

Then edit the generated files with endpoint-specific requests.

## README checklist

Include:

- Purpose: issue/key and what acceptance criteria are covered.
- Prerequisites: backend/db startup, migrations, auth/env setup.
- rest.nvim usage (`:Rest env set ...`, `:Rest run`).
- Step-by-step run order, especially copy/paste IDs into top-level variables.
- Expected results for happy paths and negative cases.
- Optional DB verification queries for audit/history tables.

## .http checklist

Follow repo conventions:

- Use `{{baseUrl}}`; it already includes `/api`.
- Include login/session/logout unless the endpoint is machine-to-machine.
- Put editable variables at the top, e.g. `@companyId = paste-id-here`.
- Use named sections with expected status/result in comments.
- Cover:
  - setup data creation
  - happy paths in execution order
  - response exposure/read-back checks
  - invalid/skipped/permission/validation cases returning expected errors
- Keep payloads realistic and deterministic. Avoid secrets.

## Sample data checklist

Create `sample-data/*.json` when request bodies are long or reused. Include only safe test data:

- fake company names/emails/domains
- valid-looking NIFs/IDs only if accepted by validators
- no production tokens, customer data, or personal data

## Quality bar

Before finishing:

- Ensure paths are correct and files are committed-ready.
- Ensure generated requests match actual controller routes and DTO field names.
- Ensure comments say what the tester should copy from responses.
- Do not run destructive DB reset commands unless user explicitly asks.
