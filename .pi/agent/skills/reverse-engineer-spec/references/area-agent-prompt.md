# Area exploration agent — prompt template

Use this as the skeleton for every area agent. Fill the [BRACKETS]. The prompts must be demanding and specific: vague prompts produce summaries; these prompts must produce evidence-backed rule inventories.

---

You are reverse-engineering the CURRENT functional behavior of [PRODUCT] from its code, to produce material for a functional spec. Search breadth: very thorough.

Repos:
- [ROLE, e.g. Backend (Firebase Cloud Functions, TypeScript)]: [ABSOLUTE PATH] (source under [SRC DIR])
- [ROLE 2 if relevant]: [ABSOLUTE PATH] (note when to consult it, e.g. "only to clarify backend behavior" or "primary for this scope")

Scope: [AREA — e.g. "COMPANY and CONTRACT entities only"].

Investigate:
- [Specific directories/files for this area — service handlers, models, validation arrays]
- [Triggers/watchers affecting this area, e.g. onChange/onWrite hooks]
- [Scheduled jobs touching this area — name them if known]
- [Side-effect surfaces: notification service calls, email templates, cascades to other entities]
- [For frontend scopes: pages, form schemas, permission gating, status displays]

Report format — numbered, testable rules of CURRENT behavior, grouped by capability, each with file:line evidence:
- "When [condition], the system [does Z]. (file.ts:123)"

Cover, exhaustively:
- Creation preconditions and validations (including duplicate checks), with exact error messages/codes
- Edit behavior and what it recomputes or resets
- State/status transitions: every state, what causes each transition, who/what is allowed
- Archive/restore/delete rules and cascades to child or related entities
- Expiration/time-based rules with EXACT thresholds (days, schedules, timezones)
- All side effects: in-app notifications (who is notified), emails (which template, to whom), external system calls
- Error cases: every condition that makes an operation fail, with the exact message and code

Also list:
- The fields/structure of each entity in scope (concept-table material): which are required, formats, nested objects
- Anything that looks like a bug, dead code, or an inconsistency worth flagging (wrong error codes, unawaited promises, threshold mismatches between code paths, guards that don't guard, copy-paste artifacts)

Be exhaustive — this report is the sole source for the spec section. A behavior you omit will be missing from the product's documentation.

---

## Notes for the orchestrator

- Send all area agents in ONE message so they run in parallel.
- Give each agent the architecture context you learned in Step 1 (request patterns, naming conventions) — it saves them discovery time.
- If an agent's report comes back thin (few rules, no error cases, no quirks), re-run it with narrower scope rather than accepting the gap.
- Expect and welcome overlapping findings between agents (e.g. two agents both describe a cascade) — overlaps are consistency checks, not waste. Reconcile them during synthesis; if two agents disagree about the same behavior, check the code yourself before writing the rule.
