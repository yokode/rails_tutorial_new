---
name: basic-review
description: Reviews code diff for functional bugs, fragility, performance issues and SOLID violations only. Ignores style and formatting. Use when the user asks for a code review.
---

# Code Review (Functional & Design Only)

Review code **only** for:
1. **Functional bugs** – wrong logic, missing edge cases, race conditions, incorrect assumptions, misuse of APIs.
2. **Performance issues** - N+1 queries, long-running transactions, network calls to 3rd party API inside requests.
3. **Code fragility** – tight coupling, hidden dependencies, brittle conditionals, magic values/strings that affect behavior, missing error handling where it changes outcomes.
4. **SOLID violations** – Single Responsibility (class/component doing too many unrelated things), Open/Closed (hard-coded branching instead of extension), Liskov (subtypes breaking contracts), Interface Segregation (fat interfaces forcing unused methods), Dependency Inversion (depending on concretions instead of abstractions where it hurts testability or flexibility).

**Do not comment on:** formatting, naming style, line length, indentation, comment style, or other purely stylistic choices.


## CI / automation (GitHub Actions)

This skill is intended to run only in CI with Cursor headless (`agent -p`). The workflow writes review inputs at the repo root—do **not** compute scope with `git diff`:

- **`.pr-diff.patch`** — unified diff for the PR from `gh pr diff` (same for full and incremental runs).
- **`.changed-files.txt`** — paths changed in the PR from `gh pr diff --name-only` (one path per line).

The agent must **not** modify tracked files, commit, push, or post PR comments—only print the review (stdout). The workflow pipes that output into `gh pr comment`.

## Process

This skill is read-only. Do not modify any source files.
Review ONLY using `.pr-diff.patch`, `.prev-review.md` and files from `.changed-files.txt`.
Do not run repository-wide searches.
Do not inspect unrelated files.
Only read additional files when required to validate a concrete suspected bug, max 2 extra files per changed file.
If evidence is insufficient, omit the finding.
Return at most 10 findings, prioritized by severity.

1. **Read the PR diff and scope.** Use `.pr-diff.patch` as the authoritative change set and `.changed-files.txt` for which paths are in scope. Do not substitute a different diff. **Incremental review** means `.prev-review.md` is present and the run is labeled incremental in the prompt—the diff is still the same full PR diff as a non-incremental run; only the re-verification step below differs.
2. **Use the project's actual language and framework.** Before flagging "wrong" or "missing" APIs (e.g. methods on core types), confirm behavior for the versions in use (Gemfile, package.json, etc.). Frameworks often extend core types, do not assume vanilla language behavior. Always check the codebase or framework docs for the project's stack.
3. **Read changed code and surrounding context** (callers, tests, related types). But only review paths listed in `.changed-files.txt` (and lines touched or shown in `.pr-diff.patch`).
4. **Re-verify previous findings (incremental only).** Read `.prev-review.md` and check each prior finding:
   - If the issue is **resolved** (code changed or removed), drop the finding.
   - If the code **moved** (renamed file, shifted lines), update the anchor and keep the finding if the issue persists.
   - If the code is **unchanged** and the issue still applies, keep the finding as-is.
5. **Scope each finding to this PR.** Anchor only on paths in `.changed-files.txt`. You may not anchor on unchanged files. If the issue is unrelated, drop it.
6. **Classify and cite** each finding:
   - **Bug** – would cause incorrect behavior or failure.
   - **Performance issue** – would cause N+1 queries, long-running transactions etc.
   - **Fragility** – would make change or debugging harder or cause subtle breakage.
   - **SOLID** – which principle and how it's violated (one line).
   - **Severity** – High, Medium, or Low.
   - **Confidence** – High, Medium, or Low (how certain the reviewer is).
   - **Evidence anchor** – exact file path plus line number(s) or symbol name, and one short impact clause that states what breaks and when.
7. **Suggest a fix** only when it's non-obvious; otherwise state what's wrong and what "good" looks like.

Produce a single unified review following the Output Format below — not separate "old" and "new" sections. The final output should read as one coherent review of the PR's current state.

## Validation

Before outputting the review, validate that:
- All findings are anchored to paths from `.changed-files.txt`.
- All anchors are for the correct lines in the changed files.
- All findings are classified and cited correctly.

## Output Format

Use this structure.
- If there are findings, include only sections that have findings.
- If there are zero findings across all sections, output this exact line and nothing else in finding sections: `No bugs/performance/fragility/SOLID findings.`

```markdown
Files reviewed: [list of files and lines changed]

## Bugs
- **[Severity: High|Medium|Low][Confidence: High|Medium|Low][Anchor: path:line or Symbol]** Brief description + impact ("what breaks and when"). Fix: …

## Performance issues
- **[Severity: High|Medium|Low][Confidence: High|Medium|Low][Anchor: path:line or Symbol]** Brief description. Suggestion: …

## Fragility
- **[Severity: High|Medium|Low][Confidence: High|Medium|Low][Anchor: path:line or Symbol]** Brief description. Suggestion: …

## SOLID
- **[Severity: High|Medium|Low][Confidence: High|Medium|Low][Anchor: path:line or Symbol]** [Principle]: brief explanation. Suggestion: …

## Summary
- Bugs: N | Performance issues: N | Fragility: N | SOLID: N
```

Keep each item to 1–3 sentences. Maximum 100 words per item.

