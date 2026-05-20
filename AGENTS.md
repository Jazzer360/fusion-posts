# Fusion 360 Post-Processor Development Workspace

This folder is a development workspace for customizing Autodesk Fusion 360 / Manufacturing post-processors. It lives at Fusion's user-posts location so edits are picked up directly by Fusion for testing.

> **Location:** `%APPDATA%\Autodesk\Fusion 360 CAM\Posts` (Windows). Fusion auto-discovers `.cps` files here under the "Personal Posts" library.

---

## Conventions for AI Assistants

When asked to modify a post, follow these rules:

1. **Posts are JavaScript** with a `.cps` extension. Treat them as JS for syntax, but they run inside Fusion's post-processor engine — *not* Node.js. There is no `require`, no `npm`, no filesystem, and no DOM. Only the Post API documented at https://cam.autodesk.com/posts/reference/index.html is available.
2. **No build step, no package manager, no test runner.** Iteration is: edit `.cps` → run a toolpath through the post inside Fusion → inspect generated NC code. The user handles the Fusion side.
3. **Reference documentation:** https://cam.autodesk.com/posts/reference/index.html — always consult this when unsure about an API (`writeBlock`, `gFormat`, `createFormat`, `onSection`, `onLinear`, `getProperty`, etc.). Fetch the page if needed rather than guessing.
4. **Preserve the public post structure.** The base posts come from Autodesk's public repository and are periodically updated. Keep customizations:
   - Minimally invasive (don't refactor surrounding code).
   - Clearly marked with a comment starting with `// CUSTOM:` so they can be re-applied when the upstream post is updated. Grep for `CUSTOM:` to find every customization site.
   - Gated by a user-defined property (added to the `properties` object near the top of the post) whenever feasible, so behavior is toggleable from Fusion's Post Properties UI without editing the post.
5. **Match the surrounding style.** The Autodesk posts use ES5-style code (`var`, function expressions, no arrow functions, no template literals, no `let`/`const`, no destructuring). Do not introduce ES6+ syntax. Fusion's embedded engine is not full modern JS.
6. **Property definitions** live in the `properties = { ... }` object near the top of the file. Each entry has `title`, `description`, `group`, `type` (`boolean` | `integer` | `number` | `enum` | `string`), `value` (default), optional `range` for numerics, optional `values` array for enums, and `scope: "post"`. Read with `getProperty("name")`.

---

## Upstream-update workflow (branch-based)

The base posts come from Autodesk's public library and get updated periodically. To reconcile updates with our customizations:

1. **`main`** always holds the latest customized post we use day-to-day.
2. When Autodesk publishes a new revision:
   - Create a branch from `main`: `git checkout -b upstream/<revision>-<yyyy-mm-dd>` (e.g. `upstream/44230-2026-07-01`).
   - On that branch, **replace** the relevant `.cps` file with the unmodified new public version and commit it as a single "vendor drop" commit. This gives us a clean diff between old-public and new-public.
   - Then re-apply customizations on top (grep for `// CUSTOM:` on `main` to find every site). Commit those separately so the re-application is reviewable.
   - Merge the branch back into `main` (or fast-forward) once Fusion-tested.
3. The "vendor drop → re-apply" sequence keeps the history clear: one commit is purely Autodesk's diff, subsequent commits are ours.

`Compare-Object (Get-Content a.cps) (Get-Content b.cps)` in PowerShell, or `git diff --no-index` / `git diff <branch>`, are the diff tools of choice.

---

## File Inventory

| File | Upstream Revision | Upstream Date | Status |
|------|-------------------|---------------|--------|
| `okuma.cps` | 44220 | 2026-04-01 | Active. Customized with optional `G30 P<n>` at program end (see below). |
| `okuma lb3000 mill-turn.cps` | 44210 | 2026-01-20 | Active. No customizations yet. |

Historical numbered variants (`okuma 2.cps`, `okuma 2 2.cps`, `okuma 3.cps`) and the Autodesk Post Processor Training Guide PDF were removed from the working tree but remain in git history (initial commit) if ever needed.

---

## Active Customizations

### `okuma.cps`

- **Optional `G30 P<n>` return-to-secondary-home at program end.**
  - Properties (group `homePositions`):
    - `gotoSecondaryHomeAtEnd` (boolean, default `false`) — master enable.
    - `secondaryHomePositionNumber` (integer, default `5`, range 1–9) — the `P` value.
  - Output: `G30 P<n>` is emitted in `onClose`, after the final `writeRetract(Z)` and the optional XY-home retract, and before `setSpindleLoadMonitor(false)`. By that point spindle is stopped, coolant is off, the work plane is canceled, and Z is at retract height — so the absolute move to the secondary reference point is safe.
  - Marker comment: `// CUSTOM: optional G30 P<n>` (one site in `properties`, one in `onClose`).

- **Output as subroutine (RTS instead of M02).**
  - Property (group `preferences`):
    - `outputAsSubroutine` (boolean, default `false`) — when on, the program ends with `RTS` instead of `M02` so it can be `CALL`ed from a separate main program. The opening `O<programName>` header doubles as the subroutine entry label; any internal subprograms appended via `writeSubprograms()` follow the closing `RTS` exactly as in the `M02` case.
  - File extension: Fusion always writes the file with the default `.MIN` extension. The `extension` global is read once at script load and `getProperty()` does not return user-set values at module scope, so the extension cannot be flipped from a property at run time. **Rename the posted file to `.SSB` by hand after posting.**
  - Implementation site: in `onClose`, the `onCommand(COMMAND_END)` call (which maps to `M2`) is replaced with `writeBlock("RTS")` when the property is on.
  - Marker comment: `// CUSTOM: emit the program as a callable subroutine` (property + the `onClose` site).

- **Optional `G30 P<n>` before every `M00` program stop.**
  - Property (group `homePositions`):
    - `gotoSecondaryHomeAtStop` (boolean, default `true`) — emit `G30 P<n>` immediately before each `M00`. Reuses `secondaryHomePositionNumber` for the `P` value.
  - Output: in `onCommand` for `COMMAND_STOP`, a `G30 P<n>` block is written before the `M00`.
  - Marker comment: `// CUSTOM: optional G30 P<n> before every M00` (one site in `properties`, one in `onCommand`).

- **Buffer Manual NC `Stop` / `Optional Stop` between sections.**
  - Default Autodesk behavior fires Manual NC `COMMAND_STOP` / `COMMAND_OPTIONAL_STOP` immediately inside `onManualNC` (via `expandManualNC`), which lands the `M00` / `M01` in the middle of the previous section's wrap-up (between coolant-off and spindle-stop / retract).
  - Customization: those two commands are pushed onto the `manualNC` buffer (alongside `COMMAND_PASS_THROUGH`), with the Manual NC operation's `operation-comment` captured at push time. A dedicated `flushBufferedManualNCStops()` runs early in the next `onSection` — after `writeRetract(Z)` / `disableLengthCompensation()` of the previous section but before the new section's own comment header — and writes a blank line + `(Manual NC name)` comment, then the stop block (which carries any injected `G30 P<n>`). Consecutive buffered stops sharing the same captured comment are grouped under one header. Items are removed from the buffer once flushed so the existing later `executeManualNC()` call doesn't re-emit them.
  - Marker comment: `// CUSTOM: buffer program stops` / `// CUSTOM: flush buffered Manual NC stops` (one site in `onManualNC`, one in `executeManualNC` / new `flushBufferedManualNCStops`, one in `onSection`).

- **Renishaw Inspection Plus (`O9901`) probing macros.**
  - Property (group `probing`):
    - `useRenishawProbing` (boolean, default `true`) — when on, supported probing cycles emit `CALL O9901 PM=<mode> ...` instead of the Autodesk Okuma defaults.
  - Cycles ported so far:
    - `probing-xy-rectangular-boss` → rapid (G00 XY then G00 Z) to the start position above the boss, then `CALL O9901 PM=11 PD=<width1> PE=<width2> PW=<-depth> PS=<probeWorkOffset>`. `PW` is the incremental Z plunge from the start position to the measurement depth (negative).
    - `probing-xy-circular-boss` → rapid (G00 XY then G00 Z) to the start position above the boss, then `CALL O9901 PM=3 PD=<width1> PW=<-depth> PS=<probeWorkOffset>`. `PW` is the incremental Z plunge from the start position to the measurement depth (negative).
    - `probing-xy-circular-hole` → rapid XY to the hole center, drop Z to measurement depth (`z - depth`), then `CALL O9901 PM=2 PD=<width1> PS=<probeWorkOffset>`.
    - `probing-x-channel` / `probing-y-channel` → drop Z into the channel (`z - depth`), then `CALL O9901 PM=4 PA=<1|2> PD=<width1> PS=<probeWorkOffset>`. `PA` enum: `1` X, `2` Y.
    - `probing-x-wall` / `probing-y-wall` → stay above the wall (`z`), then `CALL O9901 PM=5 PA=<1|2> PD=<width1> PW=<-depth> PS=<probeWorkOffset>`. `PA` enum: `1` X, `2` Y. `PW` is the incremental Z plunge to the measurement depth (negative).
    - `probing-x` / `probing-y` → rapid to a start point offset from the surface by `probeClearance + toolRadius` in the opposite of the approach direction, drop Z to measurement depth (`z - depth`), then `CALL O9901 PM=1 PA=<±1|±2> PS=<probeWorkOffset>`. `PA` enum: `1` X+, `-1` X-, `2` Y+, `-2` Y-. Sign comes from `cycle.approach1` (`positive` → +, `negative` → -).
    - `probing-z` → rapid XY to the surface point, drop Z to `(z - depth + probeClearance)`, then `CALL O9901 PM=1 PA=-3 PS=<probeWorkOffset>` (Z-minus only — the Renishaw enum has no Z+).
  - When `useRenishawProbing` is on, the following standard Okuma probe calls are suppressed because the O9901 macro family handles probe spin and protected motion internally:
    - `CALL O9832` (probe spin-on) at section start.
    - `CALL O9833` (probe spin-off) at section end.
    - The leading `CALL O9810` protected entry move and the trailing `CALL O9810` retract — suppressed only for cycle types listed in `isRenishawProbeCycle` (so non-ported cycles still use the standard protected motion if they ever run with the property on).
  - Marker comment: `// CUSTOM: Renishaw` (property definition + `isRenishawProbeCycle` helper + each gated site).

- **Tombstone rotary WCS spacing.**
  - Property (group `multiAxis`):
    - `tombstoneRotarySpacing` (number, default `0`, range 0-360) - degrees of rotary-axis offset per WCS step. `0` disables the per-WCS spacing.
    - `tombstoneRotaryInitial` (number, default `0`, range 0-360) - fixed degrees added to every rotary command on top of the per-WCS spacing. Use when the program runs on a station whose home rotary position is not B0 (e.g. a tombstone shared with other programs).
  - Behavior: `initTombstoneRotaryWCS()` (called from `onOpen` after `defineMachine` / `activateMachine`) always resolves the rotary table axis coordinate (0=A, 1=B, 2=C) from `machineConfiguration.getAxisV()` / `getAxisU()` whenever the machine is multi-axis - preferring the cyclic table axis (the C axis on 5-axis configs, the single rotary on 4-axis configs). Axis detection is intentionally *not* gated on the tombstone properties so the rotary-normalization path in `applyTombstoneRotaryOffset` is reachable even when the user has no tombstone offset configured (see normalization note below). When `tombstoneRotarySpacing > 0`, it additionally scans every section, collects the unique `workOffset` values, sorts them ascending, and assigns each a 0-based rank.
  - At runtime, `applyTombstoneRotaryOffset(section, abc)` adds `toRad(rank * spacing + initial)` to the rotary coordinate of the abc Vector, then **always** normalizes the rotary coord modulo `2*PI` (even when no tombstone offset is applied). The normalization range is conditional:
    - **Offset applied (`totalDeg != 0`):** wrap into `(0, 2*PI]`. When natural + offset sums to exactly 0 (e.g. natural B-90 + initial 90), the result is mapped to `2*PI` rather than 0 so the downstream `abc.isZero()` checks in `setWorkPlane` / `defineWorkPlane` don't mistake the section for a "no rotation needed / cancel workplane" case (which would skip the OO88 setup entirely). The `2*PI` marker is collapsed back to `[0, 2*PI)` at the actual `positionABC` output site (in `setWorkPlane`) so the emitted rotary block reads `B0` rather than `B360`.
    - **No offset applied (`totalDeg == 0`):** wrap into `[0, 2*PI)`. A genuinely-zero section (natural rotary = 0) stays zero and correctly triggers the cancel-workplane path. The point of the always-on wrap in this branch is to fix a Fusion quirk: Fusion can produce two equivalent abc representations for operationally-identical sections that differ by exactly `2*PI` (e.g. one section's natural rotary = -PI/2, the next's = 3*PI/2 - both physically B270). Without normalization, the `Vector.diff(defineWorkPlane(prev), defineWorkPlane(curr)).length > 1e-4` check in `onSection` sees a `2*PI` delta and flags a new work plane, forcing a spurious full retract / OO88 rebuild between sections even though the rotary doesn't move.
  - Applied in two places so the offset / normalization reach every downstream sink:
    1. Inside `defineWorkPlane(_section, _setWorkPlane)`, immediately after `abc` is computed and BEFORE the `if (_setWorkPlane)` dispatch - so `positionABC(abc, true)` (non-tilted-workplane path) and `setWorkPlane(abc) -> writeFixtureOffset(abc)` (OO88 / G605 path) both receive the offset, and the diff check in `onSection` (which calls `defineWorkPlane(prev/curr, false)`) stays consistent.
    2. In `setWorkPlane(abc)`, immediately after the `machineABC` recomputation via `getWorkPlaneMachineABC(currentSection, false)` - so the physical rotary positioning on the tilted-workplane path tracks the offset too (`getWorkPlaneMachineABC` re-derives abc from the section workplane and would otherwise drop the offset).
  - Additionally, the program's opening `positionABC(...)` call in `onSection` (first section, tilted-workplane cancel path) uses `getTombstoneOpeningABC()` instead of `new Vector(0,0,0)`. That helper returns a Vector that honors `tombstoneRotaryInitial` only (per-WCS rank is applied later when the first section's workplane is set), so the program opens at the configured base rotary position (e.g. `G00 B45.` instead of `G00 B0.`).
  - OO88 fixture-offset adjustment: the `CALL OO88` macro computes the recalculated WCS by rotating the original work origin by `PA`/`PB`/`PC`, *assuming the WCS was probed at 0 deg* on the rotary axis. When `tombstoneRotaryInitial` is non-zero, the WCS is actually probed at that orientation, so `writeFixtureOffset(abc, reset)` subtracts `toRad(initial)` from the tombstone rotary coord of a local `oo88Abc` (wrapping into `[0, 2*PI)`) before formatting `PA`/`PB`/`PC`. Example: `tombstoneRotaryInitial=90`, machine rotary at B45 -> `PB=315` (= 45 - 90 = -45, wrapped). The subtraction is skipped on reset calls (`reset == true`) so the cancel path keeps `PA`/`PB`/`PC` at 0 to cleanly tear down OO88. `PX`/`PY`/`PZ` (the work origin) and `PH`/`PP` (the WCS / recalculated WCS numbers) are untouched.
  - Skipped for `_section.isMultiAxis()` (simultaneous 5-axis): there the abc is the initial tool axis, not a WCS indexing position.
  - Validation: if more than one unique WCS is used and `(count - 1) * spacing >= 360`, the post errors out at `onOpen` to prevent the rotary from wrapping around to a duplicate orientation. (For a 4-sided tombstone with 4 WCS and 90 deg spacing, the last offset is 270 deg < 360 - passes.)
  - Marker comment: `// CUSTOM: tombstone rotary WCS` (property definitions + helper block above `onOpen` + the three application sites).

- **Reuse multi-WCS subprograms (G91 pattern dedup).**
  - Property (group `multiAxis`):
    - `reuseMultiWCSSubprograms` (boolean, default `false`) - when on, sections that share a Fusion pattern ID (i.e. copies generated by the setup's "Use Multiple WCS Offsets" option) are emitted as a single incremental (G91) pattern subprogram and CALLed from each WCS instance, instead of one subprogram per WCS.
  - Requires the stock `useSubroutines` post property to be set to a mode that includes Patterns (e.g. `"All Operations & Patterns"` or `"Patterns"`). Has no effect under `"All Operations"` because that mode never invokes pattern detection.
  - Behavior: a custom branch in `subprogramIsValid` (SUB_PATTERN path) skips the default world-frame `areSpatialBoxesSame` / `areSpatialBoxesTranslated` checks - those fail for rotary-tombstone clones because the copies are rotated, not translated, in world coords. Instead, any same-`patternId` section is accepted as a valid clone and `subprogramState.incrementalSubprogram` is forced to `true`. The existing `subprogramStart` / `subprogramEnd` plumbing then wraps the body in `G91` ... `G90` via `setAbsIncMode`, so per-CALL deltas are emitted in each WCS-local frame.
  - Still rejected: sections that are `isMultiAxis()` (simultaneous 4/5-axis - body would contain rotary moves that can't be safely incrementalized), `isTCPSupportedByOperation(section)` (TCP requires absolute positions), or whose tool is `TOOL_PROBE` (probing macros bake the WCS-specific `PS=<probeWorkOffset>` into the body, so a shared subprogram would call the wrong work offset for all but one WCS instance).
  - Caveat: any path that emits an absolute block (e.g. `writeRetract` with `G90 G53`) inside the subprogram body will fight the incremental output formats. Pattern subprograms are not expected to contain mid-body retracts, but verify on first use.
  - Marker comment: `// CUSTOM: reuse multi-WCS subprograms` (property definition + the bypass branch in `subprogramIsValid`).


---

1. Make changes directly to the `.cps` file in this folder.
2. In Fusion 360 → Manufacturing → Post Process, pick the post (it shows under Personal Posts).
3. For boolean/numeric properties added to the post, the new fields show up in the Post Properties panel automatically — toggle/set there and re-post to validate.
4. Inspect the generated NC file. Iterate.
5. Commit incremental working changes to git. For risky or upstream-update work, use a branch (see Upstream-update workflow above).

## Quick Reference: Post API Essentials

- `writeBlock(...)` — emit one NC line. Arguments are individual formatted words.
- `writeln(text)` — emit a raw line.
- `writeComment(text)` — emit a comment (controller-appropriate syntax).
- `createFormat({...})` / `createOutputVariable(...)` — define how numeric values are formatted/output.
- Event handlers (called by the engine): `onOpen`, `onSection`, `onSectionEnd`, `onLinear`, `onRapid`, `onCircular`, `onCommand`, `onClose`, `onParameter`, `onCycle`, etc.
- `getProperty("name")` — read a user-configurable property declared in the `properties` object.
- `getSetting("path.to.setting", default)` — read a value from the post's internal `settings` object.
- `getSection(i)`, `currentSection`, `isFirstSection()`, `isLastSection()` — section iteration helpers.

Full reference: https://cam.autodesk.com/posts/reference/index.html

---

## Notes

- This file (`AGENTS.md`) is the canonical AI-assistant briefing — ecosystem-agnostic so it works with GitHub Copilot, Claude Code, Cursor, etc. No tool-specific stubs are required; most modern AI coding tools read `AGENTS.md` directly.
- No language runtime is required for development. `git` is the only required tool on the host.
