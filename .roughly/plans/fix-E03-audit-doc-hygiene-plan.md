> **Status:** Historical — implemented and merged in commit 0099afedc967434e256218a0047a6c6cafa343f0 on 2026-05-13. This plan was an active build/fix artifact; treat as historical reference only.

# Fix Plan: E03 audit doc-hygiene findings

Plan-format-version: 1

## Root Cause

The E03 epic file (`docs/planning/epics/E03-trust-and-ergonomics.md`) serves dual purposes: it is both the audit-target spec and the historical record of the release. AC text claims like "line counts preserved at 296 and 299" (S1 AC6) and "build 288, fix 291" (S3 AC6) were factually correct at each story's merge time but have since drifted because later stories (S2, S6, S11b-2) cumulatively added lines to `skills/build/SKILL.md` (now 298) and `skills/fix/SKILL.md` (now 299). The audit flagged these as PARTIAL with the recommendation: preserve historical accuracy via `(at-merge-time)` annotation rather than back-rewriting. Additionally, S2 AC5 states setup Step 6 is "gated on the same condition as build/fix" — the implementation correctly omits the "verify-all has 2+ meaningful checks" gate at install time (verify-all isn't populated yet), but this intentional asymmetry was only documented in epic prose, leaving the literal AC text open to re-flagging by future audits.

## File Table

| File | Action | Task(s) |
|------|--------|---------|
| docs/planning/epics/E03-trust-and-ergonomics.md | Modify | T1, T2, T3 |

## Tasks

### T1: Annotate S1 AC6 line-count claim with current state (~2 min)
**Files:** docs/planning/epics/E03-trust-and-ergonomics.md
**Action:** Modify the S1 AC6 bullet at L171 to preserve the at-merge-time claim while making current state explicit.
**Details:**
- Find the exact existing text at L171:
  ```
  - [x] Detection contract documented in [skills/build/SKILL.md:11](../../../skills/build/SKILL.md#L11) and synced verbatim to [skills/fix/SKILL.md:11](../../../skills/fix/SKILL.md#L11) — substitution-only; line counts preserved at 296 and 299.
  ```
- Replace with:
  ```
  - [x] Detection contract documented in [skills/build/SKILL.md:11](../../../skills/build/SKILL.md#L11) and synced verbatim to [skills/fix/SKILL.md:11](../../../skills/fix/SKILL.md#L11) — substitution-only; line counts preserved at 296 and 299 at S1 merge (current state: build 298, fix 299 after cumulative additions from S6 + S11b-2; both under 300 hard cap).
  ```
- Do not modify any other 296/299 reference in the file — the other occurrences (L26, L46, L48, L52, L66, L140, L160, L456) are correct historical snapshots and must remain untouched.
**Verify:**
```
grep -Fn 'line counts preserved at 296 and 299 at S1 merge' docs/planning/epics/E03-trust-and-ergonomics.md
```
Expected: exactly one match.
**UI:** no

### T2: Annotate S3 AC6 line-count claim with current state (~2 min)
**Files:** docs/planning/epics/E03-trust-and-ergonomics.md
**Action:** Modify the S3 AC6 bullet at L323 to preserve the at-merge-time claim while making current state explicit.
**Details:**
- Find the exact existing text at L323:
  ```
  - [x] No skill body exceeds 300 lines — build 288, fix 291; ample headroom for downstream stories
  ```
- Replace with:
  ```
  - [x] No skill body exceeds 300 lines — build 288, fix 291 at S3 merge (current state: build 298, fix 299 after S2 + S6 + S11b-2; both under 300 hard cap)
  ```
- Do not modify the L48 status update ("build is now 288/300 (12 lines headroom) and fix 291/300 (9 lines)") — that is a correct historical post-S3 snapshot inside the Risk register.
**Verify:**
```
grep -Fn 'build 288, fix 291 at S3 merge' docs/planning/epics/E03-trust-and-ergonomics.md
```
Expected: exactly one match.
**UI:** no

### T3: Document S2 AC5 intentional gate asymmetry inline (~3 min)
**Files:** docs/planning/epics/E03-trust-and-ergonomics.md
**Action:** Amend S2 AC5 at L260 with a parenthetical clarifying the intentional asymmetry between setup Step 6 and build/fix Stage 8.
**Details:**
- Find the exact existing text at L260:
  ```
  - [x] [skills/setup/SKILL.md](../../../skills/setup/SKILL.md) Step 6 gains `stop-hook-v1` offer in the initial setup flow, gated on the same condition as build/fix.
  ```
- Replace with:
  ```
  - [x] [skills/setup/SKILL.md](../../../skills/setup/SKILL.md) Step 6 gains `stop-hook-v1` offer in the initial setup flow, gated on the same condition as build/fix — with the intentional exception that the "verify-all has 2+ meaningful checks" gate is omitted at Step 6, because setup runs before verify-all is populated and the 2+ checks guard is inapplicable at install time.
  ```
- Do not modify Step 6 in `skills/setup/SKILL.md` itself — the implementation is correct; only the AC text needs the explanatory parenthetical. This keeps the fix scoped to documentation and preserves the prose-only constraint.
**Verify:**
```
grep -Fn 'intentional exception that the "verify-all has 2+ meaningful checks" gate is omitted at Step 6' docs/planning/epics/E03-trust-and-ergonomics.md
```
Expected: exactly one match. The `-F` flag is critical here — the substring contains `"` and a regex `.`-mismatch hazard if the flag is omitted.
**UI:** no

## Blast Radius

- **Do NOT modify:** any file outside `docs/planning/epics/E03-trust-and-ergonomics.md`. In particular, do not edit `skills/build/SKILL.md`, `skills/fix/SKILL.md`, `skills/setup/SKILL.md`, or the audit report itself (`docs/planning/epics/E03-trust-and-ergonomics-audit.md`).
- **Do NOT touch other 296/299 references** in the epic file at L26, L46, L48, L52, L66, L140, L160, L456 — these are historical status snapshots in the Risk register / Line-cap budget contract intro / Files-delivered sections and must remain accurate as historical records.
- **Watch for:** epic-file line numbers shift after each edit. Subsequent tasks should re-locate their target text via grep/Read rather than relying on cached line numbers.
- **Watch for:** the verify command's `grep` patterns include literal quote characters — ensure the Edit tool's replacement string preserves the existing markdown syntax (links, backticks, etc.) byte-for-byte except at the substitution point.
- **No behavioral changes.** No source code, hooks, agents, skill bodies, templates, CHANGELOG, or ADRs are touched. This is a pure documentation hygiene fix.
- **Verify-all baseline:** the dogfood Stop hook (`.claude/hooks/verify-all.sh`) should pass with exit 0 both before and after this fix — no line caps, drift checks, or other invariants change.
