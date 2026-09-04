# Phase 1 — Evaluate the submission

Goal: a scored, evidence-backed evaluation report. Every claim in the report must come from something you ran or read — never from the candidate's README alone.

## 1. Locate the inputs

- Candidate repo = the working directory (or the path the user gives).
- Challenge spec + internal rubric: look in `../instructions/` for files matching the challenge name (e.g. `technical-challenge-*.md`, `Code_Review_Instructions_*.md`, PDFs). If ambiguous, ask which pair applies.
- Read **both files in full** before touching the repo. Extract: pass/fail gates, scoring criteria with weights, score bands, AI-generation tells, per-candidate focus points (rubrics often carry notes from prior interviews — these decide where to probe hardest).

## 2. Static review (before running anything)

- `git log --pretty=format:'%h %ad %an %s' --date=iso` — commit count, cadence, message quality, timestamps/timezone. One giant commit or generated-sounding messages is a rubric flag; realistic mid-stream fix commits are a strong authenticity signal. Note anything relevant to per-candidate flags (e.g. focused-effort questions).
- Map the repo (`find … -not -path '*/node_modules/*'`), then read: README, schema/migrations, the core business-logic services, the test files, Docker/compose files, tsconfig (or equivalent strictness config), env examples.
- Check hygiene: secrets committed? passwords hashed? `grep -rn ': any\|as any'` (or language equivalent) for type discipline.
- **Cross-check the README against the code.** This is the strongest AI tell in most rubrics: does the claimed mechanism (concurrency handling, caching, algorithm) match what the code actually does, down to file paths and constants? Verify every checkable claim.

## 3. First gate — run it

- Start it exactly the way the challenge says reviewers will (usually `docker compose up`). Use `run_in_background` for builds; verify all services healthy; hit the health endpoint.
- Log into the UI with seeded credentials; confirm the app is usable without reading code (a browser check with a screenshot is ideal if browser tools are available).
- If it doesn't come up: trivial fix (missing env var) → note it and continue; otherwise the rubric usually says fail — stop and report.

## 4. Verify business rules at the API level

The rubric's core rules must live in the API, not the UI. Script the checks with curl and record actual status codes + bodies:

- Each validation rule (past dates, out-of-range values, forbidden states) → expect the documented 4xx.
- Role separation: hit admin endpoints with a non-admin token → expect 403.
- **Concurrency, when the challenge has a race-sensitive rule**: fire 8–10 truly parallel requests (shell `&` + `wait`, not sequential) at the contested resource. Expect exactly one winner, and verify the datastore holds exactly one row — response codes alone don't prove it.
- Anything the rubric calls an edge case (boundary times, exact-limit values) — test the boundary itself.

## 5. Run the candidate's tests

Run their documented test command (prefer the Dockerized path so it's their environment, not yours). Record counts and pass/fail. Then judge the tests themselves: do they assert failures and datastore state, or only happy-path status codes? Does a real concurrency test exist? Boundary tests?

## 6. Score and write the report

Score each rubric criterion (0–4 or as the rubric defines) with the rubric's weights; compute the weighted total and band. For each criterion cite concrete evidence (file:line, command output, test names).

Report sections, in order:
1. **Verdict** — weighted score, band, one-paragraph justification, up front.
2. **First gate** — pass/fail with the actual probe results.
3. **Per-criterion scores** — one paragraph each, evidence-first, nitpicks included honestly.
4. **AI-generation tells** — go through the rubric's list explicitly; state which are present/absent and why. Flags aren't auto-fails — each one becomes an interview question.
5. **Per-candidate focus points** — address whatever the rubric flagged for this person.
6. **Suggested live-interview probes** — feeds Phase 3.
7. **Comparative note** if the rubric positions candidates against each other.

**Save as** `evaluation-<challenge>-<candidate-slug>.md` in the directory *above* the candidate repo (never inside it — it's their git repo). Mark it `INTERNAL` at the top. State the evaluation date and what was actually executed.
