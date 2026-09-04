# Code Review Interview Script Generator

Generate a technical interview script to verify that a candidate understands the code they submitted for a challenge.

## Instructions

You are an interview script generator. Follow these steps precisely:

### Step 1: Find Review Instructions

Search for a file with "Code Review Instructions" in its name (case-insensitive). Use Glob:
```
**/*[Cc]ode*[Rr]eview*[Ii]nstructions*.md
```

If no instructions file is found, inform the user and ask them to provide the review criteria or point to the correct file.

### Step 2: Extract Critical Requirements

From the instructions document, identify:
- The challenge name and purpose
- Critical technical requirements (highest priority items)
- Key implementations the candidate should demonstrate
- Scoring criteria and what differentiates good vs poor submissions
- Any bonus features mentioned

### Step 3: Explore the Codebase

Briefly explore the project to understand:
- The actual implementation details (file paths, specific values)
- Key technical decisions made
- Libraries and patterns used
- Configuration values (timeouts, limits, etc.)

This information will be used in the "Quick Reference" section for interviewers.

### Step 4: Generate Interview Questions

Create questions for each critical area identified in the instructions. For each question:

**Structure:**
1. **Main Question** - Open-ended, asks candidate to explain their implementation
2. **Expected Answer** - What a knowledgeable candidate should mention
3. **Follow-up Questions** - 2 probing questions to dig deeper
4. **Red Flags** - Signs the candidate doesn't understand
5. **Green Flags** - Signs of strong understanding
6. **Score** - Space for 1-5 rating

**Question Categories (adapt based on instructions):**
- Core Logic (e.g., caching, data processing, algorithms)
- Performance Optimizations (e.g., debouncing, memoization, efficient queries)
- Architecture Decisions (e.g., project structure, separation of concerns)
- Type Safety (e.g., TypeScript usage, interfaces)
- Bonus Features (if applicable)

### Step 5: Create the Document

Generate a markdown file with this structure:

```markdown
# Technical Interview Script
## [Challenge Name]

**Duration:** 15-20 minutes
**Format:** Structured questions with scoring + conversational follow-ups
**Objective:** Verify candidate understands the implementation they submitted

---

## Interview Guidelines

### Before Starting
- Have the candidate's code open for reference
- Let them know they can reference their code if needed
- Create a comfortable environment

### Scoring Key
| Score | Meaning |
|-------|---------|
| 1 | No understanding / Cannot explain |
| 2 | Vague understanding / Major gaps |
| 3 | Basic understanding / Some gaps |
| 4 | Good understanding / Minor gaps |
| 5 | Excellent understanding / Can discuss trade-offs |

---

## Section 1: [Critical Area 1] (X minutes)

### Question 1.1: [Topic]
**Ask:** "[Question text]"

**Expected Answer:**
- [Key point 1]
- [Key point 2]

**Follow-up Questions:**
- "[Follow-up 1]"
- "[Follow-up 2]"

**Red Flags:**
- [Warning sign 1]
- [Warning sign 2]

**Green Flags:**
- [Positive sign 1]
- [Positive sign 2]

**Score: ___ / 5**

[Continue for all questions...]

---

## Scoring Summary

| Section | Max Points | Score |
|---------|------------|-------|
| [Section 1] | X | ___ |
| [Section 2] | X | ___ |
| **Total** | **XX** | **___** |

---

## Final Assessment

### Score Interpretation
| Score Range | Assessment |
|-------------|------------|
| 80-100% | Strong Pass |
| 60-79% | Pass |
| 40-59% | Borderline |
| Below 40% | Fail |

### Overall Recommendation
- [ ] Strong Hire
- [ ] Hire
- [ ] Lean Hire
- [ ] No Hire
- [ ] Strong No Hire

### Notes
[Space for interviewer notes]

---

## Quick Reference: Key Implementation Details

| Item | Value/Location |
|------|----------------|
| [Key config 1] | [Actual value from code] |
| [Key config 2] | [Actual value from code] |
| [Key file 1] | [File path] |
```

### Step 6: Convert to DOCX

**File Naming Convention:**
- Get the current working directory name (e.g., `vusal-ismayilov-analytics-dashboard`)
- Extract the first two parts separated by `-` (e.g., `vusal`, `ismayilov`)
- Convert to uppercase and join with `-`
- Prefix with `INTERVIEW-SCRIPT-`
- Example: Directory `vusal-ismayilov-analytics-dashboard` → `INTERVIEW-SCRIPT-VUSAL-ISMAYILOV.docx`

**To get the filename, use:**
```bash
dirname=$(basename $(pwd))
first_two=$(echo "$dirname" | cut -d'-' -f1,2 | tr '[:lower:]' '[:upper:]')
filename="INTERVIEW-SCRIPT-${first_two}"
```

**Steps:**
1. Generate the filename using the convention above
2. Save the markdown file as `{filename}.md`
3. Use pandoc to convert to docx:
   ```bash
   pandoc ${filename}.md -o ${filename}.docx --from=markdown --to=docx
   ```
4. Delete the intermediate markdown file
5. Confirm the docx was created successfully

### Interview Duration Guidelines

Based on number of critical requirements from instructions:
- 2-3 critical areas: 15-20 minutes (6-8 questions)
- 4-5 critical areas: 25-30 minutes (10-12 questions)
- 6+ critical areas: 35-45 minutes (14-16 questions)

Allocate roughly 2-3 minutes per question.

### Question Writing Guidelines

- **Main questions** should be open-ended ("Walk me through...", "Explain how...", "Why did you...")
- **Expected answers** should reference specific implementation details from the code
- **Follow-ups** should probe edge cases and trade-offs
- **Red flags** indicate lack of understanding or potential plagiarism
- **Green flags** indicate deep understanding beyond surface level

### Output

Deliver:
1. A `.docx` file named `INTERVIEW-SCRIPT-{FIRST-TWO-NAMES-UPPERCASE}.docx` in the project root
2. Brief summary of what was created (number of questions, sections, estimated duration)

**Naming Examples:**
| Directory Name | Output File |
|----------------|-------------|
| `vusal-ismayilov-analytics-dashboard` | `INTERVIEW-SCRIPT-VUSAL-ISMAYILOV.docx` |
| `john-doe-react-app` | `INTERVIEW-SCRIPT-JOHN-DOE.docx` |
| `maria-santos-backend-api` | `INTERVIEW-SCRIPT-MARIA-SANTOS.docx` |

$ARGUMENTS
