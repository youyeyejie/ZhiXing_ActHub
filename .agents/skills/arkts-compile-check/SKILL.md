---
name: arkts-compile-check
description: Check ArkTS compilation status for this HarmonyOS Next project by running the module resource compile step in the `Code/` directory. Use when agent needs to verify whether ArkTS code currently participates in compilation, reproduce compile diagnostics, or confirm whether a page/component/module is actually compiled. Only referenced code is checked by this flow; unreferenced files can be skipped by dead code elimination.
---

# ArkTS Compile Check

Use this skill to perform a fast ArkTS-related compile check for the repository's `entry` module.

## Workflow

1. Confirm the compile check should run from the `Code/` directory.
2. Try to execute the command directly, while keeping the working directory at `Code/`:
   - `hvigorw --mode module -p module=entry@default default@ProcessCompiledResources`
     (assuming hvigorw already in PATH and do not check it)
     Imporant note: If hvigorw not found, just skip the check rather than search for it.
3. Capture the full diagnostics and identify the first blocking error before suggesting fixes.
4. If the user wants to verify a specific page, component, or module, first confirm it is reachable from the current app/module reference graph.
5. If the target code is not referenced, state clearly that this compile pass may skip it because of dead code elimination.

## Important Constraint

This check only validates code that is actually pulled into the current compilation graph.

- A standalone `.ets` file that is never imported, routed to, or rendered can be skipped.
- A component/page added only on disk is not enough; it must be referenced by reachable code to participate in the check.
- If the user asks whether a new file "compiles", wire it into an existing entry path first, or explain that the current compile result is not conclusive for that file.

## Output Rules

- Report the exact command used and that it ran under `Code/`.
- Separate results into:
  - compile passed
  - compile failed with diagnostics
  - compile result is inconclusive because the target code is unreferenced
- When there are errors, quote only the minimal lines needed and then explain the root cause in plain language.

## Files

- Skill script: `.agent/skills/arkts-compile-check/scripts/check-arkts-compile.ps1`
- Project working directory for the command: `Code/`
