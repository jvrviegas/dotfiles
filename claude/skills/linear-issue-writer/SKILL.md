---
name: linear-issue-writer
description: Write or rewrite Linear issue descriptions in Procimo's house format — Linear-method task framing with Context, Business Rules, checkbox Acceptance Criteria, Out of Scope, Dependencies, and an AI Handoff section that lets an AI agent build an implementation plan without follow-up questions. Use this skill whenever the user asks to create, write, draft, improve, standardize, or split a Linear issue or ticket; convert client feedback, bug reports, meeting notes, or spec fragments into issues; write acceptance criteria or business rules for a task; or prepare work for handoff to an AI coding agent — even if they never say the word "template" or "skill".
---

# Linear Issue Writer (Procimo)

This skill produces issue descriptions that work twice: a human can read them top-to-bottom and understand the *why* and the *what* in under a minute, and an AI coding agent can take the same text and produce a credible implementation plan with zero clarifying questions.

The format is not invented. It codifies what already worked across an audit of 490+ issues in Dash2Zero, Get2Events, and Procimo Internal (the best of CP-85, CP-170, CP-266, CP-571, CP-815, PRO-1549, PRO-1577), and it closes the failure modes that audit found: screenshot-only bugs, unresolvable shorthand references, untestable acceptance criteria, business rules buried in prose, and multi-topic to-do dumps. It follows the Linear method (linear.app/method/write-issues-not-user-stories): issues are concrete tasks with defined outcomes — never user stories.

## Core principles

1. **One issue = one task with one verifiable outcome.** If the input contains several outcomes (a feedback email, a to-do list, a meeting note), split it into several issues and tell the user you did. A dumping-ground issue named after a person or a meeting is never acceptable.

2. **The title states the task.** Imperative, scannable, ideally under ~70 characters. If the key business rule is short, put it in the title — "Event soft delete: draft-only, zero responses, 90-day retention" beats "Soft delete". Never a symptom ("Forbidden error after sync"), never a label ("[PR-000063] My Equipment"), never a person's name.

3. **No user stories.** "As a user, I want…" pushes the actual work behind ceremony. State the deliverable directly. User context belongs in Context, in one or two sentences.

4. **Self-contained or explicitly linked.** Every reference must be resolvable by a reader (or an AI) who was not in the planning meeting: link issues by their real identifier (CP-123, PRO-456), give spec references as a repository path plus section (`docs/feature-specs/notion-editor.md` §B6), never internal shorthand like "A1" or "M3-1". If you must cite an external decision, date it and name the decider.

5. **Business rules are findable.** Formulas, validation rules, permission matrices, state machines, and edge-case decisions go under their own `## Business Rules` heading — not scattered through prose. Use tables for anything matrix-shaped. A rule that exists only in someone's head or a Slack thread does not exist.

6. **Behavior and constraints, not mechanisms.** The description says *what* must be true and *within which limits* — never *how* to code it. Naming a library, ORM feature, SQL syntax, framework API, or internal helper is a mechanism: it belongs in the implementation plan the assignee (or AI agent) derives from the issue, or in the PR — not in the description. Mechanisms make issues unreadable to non-engineers, go stale when the code moves, and pre-empt the very implementation plan the issue exists to enable. Real technical decisions are still captured, but *as constraints*: "uniqueness is enforced at the database level, not only in application code", "no new dependencies for date handling", "reuse the existing holiday calendar instead of a new table". The test: would the sentence survive the team switching ORM or framework? If not, it's a mechanism — cut it, or lift the underlying requirement into a constraint. Do not add an "Implementation Notes" section; if a tech review fixed a decision, record the constraint (with date/owner) under AI Handoff and leave the mechanism to the PR.

7. **Acceptance criteria are a checkbox list, and each box is independently verifiable.** Include negative and refusal cases ("deletion is refused when the event has responses, and the error names archiving as the alternative"), not just happy paths. Boxes start unchecked. An AC that cannot fail ("works correctly", "fully role-based") is not an AC — rewrite it until a tester could mark it false.

8. **Evidence is transcribed, never screenshot-only.** Attached images expire and are invisible to AI agents. Always transcribe the essential content (error text, values, URLs) into the body; keep the screenshot as supplementary evidence.

9. **Corrections keep the issue truthful.** When scope or a rule changes after creation, update the affected acceptance criteria *in place* and append a dated note explaining the change. Never leave a live checkbox that a later paragraph contradicts.

10. **English body.** Keep verbatim client quotes in their original language, immediately followed by an English translation. Untranslated Portuguese-only issues block both non-PT teammates and most AI tooling.

11. **Honest unknowns beat invented details.** If something is undecided, write it under `## Open Questions` with a named owner and, when work can proceed anyway, state the safe interim assumption you built the issue on. Do not fabricate data models, endpoints, or rules the source material doesn't support.

## Workflow

1. **Classify the input.** Feature/Task (new behavior, change, chore, spike) or Bug (observed wrong behavior). If the source material mixes both or contains multiple outcomes, split first.

2. **Extract before you write.** From the user's material, pull: the why (context), the concrete outcome, every rule/validation/permission mentioned, environment details (for bugs), known code/spec references, and dependencies. Mark what's missing — ask the user only for things that genuinely block writing; otherwise record them as Open Questions.

3. **Write from the matching template.** Read [references/feature-template.md](references/feature-template.md) for features/tasks/chores/spikes, or [references/bug-template.md](references/bug-template.md) for bugs. Each contains the full skeleton, per-section guidance, and a gold example.

4. **Fill the AI Handoff section deliberately — boundaries, not solutions.** This is what turns a good human issue into an AI-executable one: integration points to reuse, data captured (fields and their semantics), API contract with an error-case table, test plan, and constraints (migrations, feature flags, human-in-the-loop warnings, "enforce at the database level", "no new dependencies"). It hands the AI the *inputs* to an implementation plan — it is not the plan itself, so never prescribe libraries, ORM syntax, algorithms, or code snippets here. Include only subsections that apply — an empty heading is noise. If you don't know the codebase, say what you do know and mark the rest "to be located by implementer" rather than inventing paths.

5. **Run the quality checklist.** Fix anything that fails before delivering.

## Quality checklist

- Title is imperative, specific, and under ~70 characters
- Exactly one outcome; anything else was split out
- Context explains *why* in 2–4 sentences and links its sources
- Every business rule from the source material appears under Business Rules
- Every AC is checkable, includes at least one negative/refusal case, and starts unchecked
- Out of Scope names the owning issue for each exclusion (when known)
- Dependencies are real issue links, or the explicit line "None — can start immediately"
- No unresolvable shorthand; no screenshot standing in for text; no "As a user…"
- No mechanisms in the body: no library, ORM/SQL syntax, framework API, or internal-helper names — behavior in product language, hard technical requirements expressed as constraints in AI Handoff
- Acceptance criteria assert behavior, not implementation artifacts ("re-registering after deletion creates a new active record", not "entity + migration created")
- Open questions have owners; interim assumptions are stated
- Body is English; original-language quotes carry translations

## Output

Deliver the issue as clean Linear-flavored markdown (headings, `- [ ]` checkboxes, tables), ready to paste into Linear's description field, with the title on the first line as `# Title` or clearly labeled. When creating the issue directly via the Linear MCP tools, put the title in the title field and everything below it in the description. When you produced multiple issues from one input, present them in dependency order and list the links between them.

## Metadata (when creating issues in Linear)

Suggest an estimate (XS–L t-shirt), a priority, and labels (e.g. Frontend/Backend/Database, Bug/Feature) when the project uses them — the audit found bugs routinely missing estimates and planner issues carrying them. Assign the issue to the milestone/cycle the user names; never leave a placeholder title like "[Edit Client]" as the deliverable.
