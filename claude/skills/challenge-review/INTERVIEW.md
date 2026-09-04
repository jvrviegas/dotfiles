# Phase 3 — Interview script (docx + interactive HTML scoresheet)

Goal: a structured interview that confirms the candidate understands what they submitted. **Default format is verbal-only — no live coding**; the rubric's live change-requests become talk-through design questions ("tell me every place that has to change, in order — no code"). Only include live coding if the user asks.

## Question design

Scale by rubric size: 2–3 critical areas → 6–8 questions / 15–20 min; 4–5 → 10–12 / 25–30 min; 6+ → 14–16 / 35–45 min. Roughly one section per rubric criterion, ordered by weight, plus a "verbal change requests" section and a closing trade-offs question.

Every question carries: **Ask** (the exact spoken wording), **Expected answer** (specific to *their* code — name files, constants, comments), **Follow-ups** (≥1; always instruct the interviewer to ask a follow-up even when the first answer is right — probing is where borrowed understanding collapses), **Red flags**, **Green flags**, **Score __/5**.

Source questions from the Phase 1 evidence:
- The core mechanism, end to end ("walk me through what happens when…").
- The rejected alternatives ("a simpler design would be X — why didn't that work?").
- **Authorship probes** (mark them with a badge, weight them in the assessment):
  - the most obscure plumbing in the repo — code too weird to write without debugging it;
  - war stories behind their own fix commits ("what was actually going wrong?") — real debugging is messy and specific;
  - the insight question — a change request whose correct answer is realizing part of their design *doesn't* need to change.
- The subtlest behavior in the submission (something even a careful author might not know — knowing it precisely is a strong green flag).
- Their own README claims and next-steps ("you wrote X — defend it / design it").
- Anything the rubric's per-candidate notes flag, and every AI-tell from Phase 1.

Scoring: 5 points per question; interpretation bands at ≥80% strong pass, 60–79% pass, 40–59% borderline, <40% fail. Add a weighting note naming the authorship-probe questions as the strongest discriminators. Include a Quick Reference table of real values (constraint names, file paths, constants, commit hashes, credentials) so the interviewer can verify answers live.

## Outputs

Naming: repo directory's first two dash-parts, uppercased → `INTERVIEW-SCRIPT-{FIRST-TWO}` (e.g. `leman-zeynalli-foo` → `INTERVIEW-SCRIPT-LEMAN-ZEYNALLI`). Both files go in the candidate repo root (they're untracked; remind the user not to commit or share them).

### 1. DOCX

Write the full script as markdown (script content per above, plus interviewer guidelines, scoring key, summary table, final assessment block), then:

```bash
pandoc INTERVIEW-SCRIPT-{FIRST-TWO}.md -o INTERVIEW-SCRIPT-{FIRST-TWO}.docx --from=markdown --to=docx
rm INTERVIEW-SCRIPT-{FIRST-TWO}.md
```

### 2. Interactive HTML scoresheet

Built from the bundled template — do **not** hand-write the HTML. Write a JSON data file and run:

```bash
python3 <skill-dir>/scripts/build_scoresheet.py data.json INTERVIEW-SCRIPT-{FIRST-TWO}.html
```

The result is self-contained and offline (system fonts, no CDN): sticky live-total bar, 1–5 segmented scoring per question with auto-summed section/total scores and band chip, localStorage persistence (scores/recommendation/notes survive refresh), Reset button, light+dark themes, print stylesheet.

JSON schema (write the data file to the scratchpad; string values are HTML — use `<code>`, `<em>`, `<strong>`; must not contain `</script`):

```jsonc
{
  "title": "Interview Script — Jane Doe · Challenge",   // browser tab
  "barTitle": "Jane Doe · Challenge deep-dive",          // sticky bar
  "barSubtitle": "Verbal only — no live coding",
  "storeKey": "interview-jane-doe-challenge",            // unique per candidate!
  "eyebrow": "Internal · Hiring · Do not share with the candidate",
  "subtitle": "Objective sentence…",
  "facts": [["Candidate","Jane Doe"],["Duration","35–45 min"],["Format","Verbal, scored 1–5"],["Repo","jane-doe/"]],
  "callouts": [
    {"label":"Before starting","html":"…guidelines…"},
    {"label":"Scoring key","html":"1 — cannot explain · … · 5 — discusses trade-offs","muted":true}
  ],
  "sections": [{
    "title":"Core Mechanism","meta":"10 min · highest weight","note":null,
    "questions":[{
      "id":"1.1","topic":"The mechanism","probe":null,        // or "Authorship probe"
      "ask":"Spoken question…",
      "expected":["point…","point…"],
      "followups":["“Question?” <em>(what a good answer contains)</em>"],
      "red":["warning sign…"], "green":["strong sign…"]
    }]
  }],
  "bands": [["64–80 (≥80%)","Strong Pass — built it and owns it"], ["…","Pass — …"], ["…","Borderline — …"], ["…","Fail — …"]],
  "thresholds": {"strong":0.8,"pass":0.6,"border":0.4},
  "weightNote":"Questions X, Y, Z are the strongest discriminators…",
  "quickRef": [["Item","<code>value / path</code>"]],
  "footer":"Internal hiring document — generated <date> from the rubric and the submitted repo."
}
```

Section numbers, per-section max, total max and question count are all derived — never state totals manually.

**Verify**: open the HTML in a browser (browser tools if available: click a score radio, confirm the sticky total updates, then clear the test entry with `localStorage.removeItem('<storeKey>')` — never click Reset via automation, its `confirm()` dialog blocks the browser extension). Without browser tools, at minimum re-run the build script (it validates the JSON) and open with the user.
