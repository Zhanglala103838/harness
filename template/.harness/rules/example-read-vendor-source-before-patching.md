# R-vendor-read · Read vendor source before patching third-party components

> **Status**: active (example — keep or tailor)
> **Severity**: warn (enforced via PR review — no grep-able signature)
> **Added**: <YYYY-MM-DD>
> **Check script**: `null` (review-only)

---

## Why

Most recurring component-library bugs (UI frameworks, wrappers, generated SDKs) are rooted in a behavior documented only in the vendor's source — default prop values, internal state machines, transition timing, lifecycle hooks. Teams that patch based on guesses iterate 3–5 times before reaching the real root cause. Each iteration ships shims (`setTimeout` / `wx:if` toggles / extra `nextTick`) that leave the symptom intact and introduce UX degradation.

- Pattern 1: bug attributed to "hot-reload flake" → actually a vendor default transition that triggers layout thrash
- Pattern 2: bug attributed to "CSS specificity" → actually vendor component's internal `scoped` style isolation
- Pattern 3: bug attributed to "race condition" → actually vendor `onShow` firing before the async mount `definitionFilter` completes

In every case the fix was one line in the vendor source's documented config — unreachable without reading the source.

## The boundary

Before dispatching or writing a fix that touches a third-party component library (UI kit, SDK, wrapper, generated client), the author must:

1. **Locate the vendor source path** (e.g. `node_modules/<lib>/…`, installed package directory, generated output).
2. **Read the relevant file(s)**: prop defaults, internal methods, template/markup structure, style (transitions, transforms, timing).
3. **Cite the vendor file path + line in the fix PR / dispatch prompt** — not as decoration, but as the ground truth the fix is built on.

If the author cannot cite vendor source, the fix is speculation and should not merge.

## How to apply

1. Does this change touch code that integrates with a third-party library (import, wrap, extend, style-override)?
2. Is the symptom "the component is behaving strangely / non-deterministically / timing-dependent"?
3. If yes to both → reading vendor source is mandatory before proposing a fix. Cite the file:line in the PR description.

## Example — violation

```
PR title: fix: dialog flicker
PR body:  Added 100ms setTimeout before mount to avoid flicker on iOS.
          (no vendor source citation)
```

This is a symptom patch. The timing workaround hides a vendor default transition that has a proper config option.

## Example — correct

```
PR title: fix: dialog flicker on iOS by disabling default scale transition
PR body:
  Root cause: vendor-ui/dialog/index.js:64 — default `transition='scale'`
  triggers a transform animation that causes native component reflow
  on iOS WebKit. Setting `transition="none"` disables the animation.
  No timing workaround needed.
```

## Retirement criteria

Retire if all third-party component integrations migrate to a typed, fully-documented SDK with test fixtures covering the edge cases that previously required source reading. In practice, most codebases keep this rule indefinitely.

## Related anti-patterns (hard forbid)

- ❌ Using `setTimeout` / `nextTick` / `wx:if` flips to hide a symptom without knowing the vendor cause
- ❌ Mixing a tech fix with UX copy decisions in the same dispatch (copy changes go to the design/product owner, not the dev fixing the bug)
- ❌ Same file hits ≥ 3 rounds of bugfix with different diagnoses — stop patching, escalate for root-cause re-analysis (see R-three-strikes)

## Related rules

- `R-three-strikes` — when a file accumulates 3 rounds of failed fixes, escalate rather than iterate.
