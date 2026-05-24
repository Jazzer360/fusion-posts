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
| `okuma lb3000 mill-turn.cps` | 44210 | 2026-01-20 | Active. Customized for the Okuma LB15-II (older OSP control). See per-customization sections below. |

Historical numbered variants (`okuma 2.cps`, `okuma 2 2.cps`, `okuma 3.cps`) and the Autodesk Post Processor Training Guide PDF were removed from the working tree but remain in git history (initial commit) if ever needed.

---

## Active Customizations

### `okuma.cps`

- **Re-grouped post properties with `groupDefinitions` for sidebar layout.**
  - The stock post lumped most properties under generic groups (`preferences` / `configuration` / `formats` / `multiAxis`) with no display titles or ordering, so Fusion sorted them alphabetically and labeled them with the raw keys. The properties block is now reorganized into nine cohesive groups, displayed in the order below; the new top-level `groupDefinitions = { ... }` block (added immediately above `properties = { ... }`) controls each group's title, description, and `order` index. Property *definitions* inside the main `properties = { ... }` literal are reordered to match the same group sequence so the file reads top-to-bottom in display order. All property keys and types are unchanged -- only `group:` values and definition position were touched, so `getProperty("name")` callers and any saved Fusion configurations keep working.
  - Group keys → display titles → property keys (in display order):
    1. `machine` "Machine Configuration": `rotaryTableAxis`, `useChipConveyor`.
    2. `homePositions` "Home & Retract Positions": `safePositionMethod`, `forceHomeOnIndexing`, `gotoSecondaryHomeAtEnd`, `gotoSecondaryHomeAtStop`, `secondaryHomePositionNumber`.
    3. `tool` "Tool & Spindle": `preloadTool`, `safeToolChange`, `offsetCode`, `toolLifeMonitor`, `loadMonitorVal`, `dwellAfterStop`.
    4. `cycles` "Cycles & Smoothing": `useG284`, `useSmoothing`, `useSmoothingNURBS` (plus the injected `useParametricFeed` from `parametricFeeds.cpi`).
    5. `multiAxis` "Multi-Axis": `useTableDirectionCodes`, `tiltedWorkPlaneMethod`, `fixtureOffsetWCS`, `rotaryOffsetWCS`, `useClampCodes`, `centerPointOutput`, `useCAS`, `useTPOC`.
    6. `tombstone` "Tombstone & Pattern Reuse": `tombstoneRotarySpacing`, `tombstoneRotaryInitial`, `reuseMultiWCSSubprograms`.
    7. `probing` "Probing": `useRenishawProbing`, `singleResultsFile`.
    8. `programBehavior` "Program Behavior": `optionalStop`, `outputAsSubroutine` (plus the injected `useSubroutines` / `useFilesForSubprograms` from `subprograms.cpi`).
    9. `output` "Program Output & Formatting": `showSequenceNumbers`, `sequenceNumberStart`, `sequenceNumberIncrement`, `separateWordsWithSpace`, `showNotes` (plus the injected `writeMachine` / `writeTools` from `writeProgramHeader.cpi`).
  - Injected-property note: five user properties are added at runtime from `// >>>>> INCLUDED FROM include_files/*.cpi` blocks via `properties.<name> = { ... }` rather than being part of the main `properties` literal. Each had its `group:` value updated in place with an inline `// CUSTOM: re-grouped (was "...")` comment so an upstream re-vendor of those `.cpi` files is easy to re-reconcile. The five and their new groups: `useParametricFeed` → `cycles`, `writeMachine` → `output`, `writeTools` → `output`, `useSubroutines` → `programBehavior`, `useFilesForSubprograms` → `programBehavior`.
  - `groupDefinitions` is the standard Autodesk Post API mechanism for naming and ordering property groups. If a particular Fusion build doesn't honor it, the properties still work -- they'd just be shown grouped by the raw key (`machine`, `homePositions`, etc.) in alphabetical order, with no group descriptions.
  - When adding a new property, set its `group:` to one of the nine keys above and place the definition next to its siblings inside `properties = { ... }`. Don't reintroduce `"preferences"` / `"configuration"` / `"formats"` as group values -- they have no `groupDefinitions` entry and would surface as a stray alphabetical group at the bottom of the sidebar.
  - Marker comments: `// CUSTOM: post property groups with display titles, descriptions, and ordering` (`groupDefinitions` block), `// CUSTOM: re-grouped (was "...")` (each injected-property site).

- **Optional `G30 P<n>` return-to-secondary-home at program end.**
  - Properties (group `homePositions`):
    - `gotoSecondaryHomeAtEnd` (boolean, default `false`) — master enable.
    - `secondaryHomePositionNumber` (integer, default `5`, range 1–9) — the `P` value.
  - Output: `G30 P<n>` is emitted in `onClose`, after the final `writeRetract(Z)` and the optional XY-home retract, and before `setSpindleLoadMonitor(false)`. By that point spindle is stopped, coolant is off, the work plane is canceled, and Z is at retract height — so the absolute move to the secondary reference point is safe.
  - Marker comment: `// CUSTOM: optional G30 P<n>` (one site in `properties`, one in `onClose`).

- **Output as subroutine (RTS instead of M02).**
  - Property (group `programBehavior`):
    - `outputAsSubroutine` (boolean, default `false`) — when on, the program ends with `RTS` instead of `M02` so it can be `CALL`ed from a separate main program. The opening `O<programName>` header doubles as the subroutine entry label; any internal subprograms appended via `writeSubprograms()` follow the closing `RTS` exactly as in the `M02` case.
  - File extension: Fusion always writes the file with the default `.MIN` extension. The `extension` global is read once at script load and `getProperty()` does not return user-set values at module scope, so the extension cannot be flipped from a property at run time. **Rename the posted file to `.SSB` by hand after posting.**
  - Implementation site: in `onClose`, the `onCommand(COMMAND_END)` call (which maps to `M2`) is replaced with `writeBlock("RTS")` when the property is on.
  - Marker comment: `// CUSTOM: emit the program as a callable subroutine` (property + the `onClose` site).

- **Optional `G30 P<n>` before every `M00` program stop.**
  - Property (group `homePositions`):
    - `gotoSecondaryHomeAtStop` (boolean, default `true`) — emit `G30 P<n>` immediately before each `M00`. Reuses `secondaryHomePositionNumber` for the `P` value.
  - Output: in `onCommand` for `COMMAND_STOP`, a `G30 P<n>` block is written before the `M00`.
  - Marker comment: `// CUSTOM: optional G30 P<n> before every M00` (one site in `properties`, one in `onCommand`).

- **Buffer every visible Manual NC and emit as its own section-style block.**
  - Default Autodesk behavior fires most Manual NC commands immediately inside `onManualNC` (via `expandManualNC`), which lands their output mid-wrap-up of the previous section (between coolant-off and spindle-stop, or between writeRetract and the new tool call) and gives them no visual separation from surrounding NC code.
  - Customization: `onManualNC` pushes **every** command onto the `manualNC` buffer except `COMMAND_ACTION` (side-effect-only payloads like `SpindleLoadMonitor:<n>`, which are consumed inline and emit no NC). Each buffered entry captures the Manual NC operation's `operation-comment` at push time.
  - `executeManualNC([command])` is the single drain entry point. For each buffered item it emits: a blank line, a synthetic `(Manual NC: <Type>)` header (derived from `getCommandStringId(command)` via `manualNCTypeLabel` — e.g. `COMMAND_OPTIONAL_STOP` → `Optional Stop`), optionally a `(<operation-comment>)` line if Fusion supplied a non-empty operation name, then the expanded NC content. The type-label header is the workhorse — Fusion doesn't always populate Manual NC operation names, but the type is always known. Comment-like commands (`COMMAND_DISPLAY_MESSAGE` / `COMMAND_PRINT_MESSAGE` / `COMMAND_COMMENT`, detected via `isManualNCCommentLike`) skip both headers since their own output is already a comment. Consecutive buffered items sharing the same command type AND same captured operation-comment are grouped under one header (handles multi-line Pass Through, which Fusion delivers as several `COMMAND_PASS_THROUGH` calls). Items are removed from the buffer as they're drained. Optional `command` arg filters the drain to one command type.
  - `writeComment` was extended to expand the literal two-character sequence `\n` to a real newline before its existing `/\r?\n/` split, so multi-line comments authored in Fusion's single-line Manual NC "Comment" field (which has no way to enter a real newline) wrap onto multiple `(...)` lines in the output.
  - Drain sites:
    1. In `onSection`, after the previous section's wrap-up (`writeRetract(Z)` / `disableLengthCompensation()` / etc., which run at the top of the next section when a tool change / new WCS / new workplane is detected) and **before** the new section's own `(operation-comment)` header. Replaces the old `flushBufferedManualNCStops()` / late-stage `executeManualNC()` pair.
    2. In `onClose`, after the program-end wrap-up (final retract, optional `G30 P<n>`, `setSpindleLoadMonitor(false)`, `TLFOFF`, chip-conveyor `M278`) and before `M02` / `RTS`. Drains anything queued after the last machining section.
  - Marker comment: `// CUSTOM: buffer every visible Manual NC` (in `onManualNC`), `// CUSTOM: Drain the buffered Manual NC commands` (on `executeManualNC`), `// CUSTOM: pretty type label` (on `manualNCTypeLabel`), `// CUSTOM: command ids whose own expanded output is already a comment block` (on `isManualNCCommentLike`), `// CUSTOM: flush every buffered Manual NC` (call site in `onSection`), `// CUSTOM: also treat the literal two-character sequence \n` (in `writeComment`).

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
  - Property (group `tombstone`):
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
  - OO88 fixture-offset adjustment: the `CALL OO88` macro computes the recalculated WCS by rotating the original work origin by `PA`/`PB`/`PC`, *assuming the WCS was probed at 0 deg* on the rotary axis. In practice each WCS is probed at its own home angle (the tombstone rotated so the part faces the spindle), which equals `rank*spacing + initial`. So `writeFixtureOffset(abc, reset)` subtracts `toRad(rank*spacing + initial)` from the tombstone rotary coord of a local `oo88Abc` (wrapping into `[0, 2*PI)`) before formatting `PA`/`PB`/`PC`. Examples: `spacing=90, initial=0`, WCS2 (rank=1) at machine B135 -> `PB=45` (= 135 - 90); `initial=90`, WCS1 (rank=0) at machine B45 -> `PB=315` (= 45 - 90, wrapped). The subtraction is skipped on reset calls (`reset == true`) so the cancel path keeps `PA`/`PB`/`PC` at 0 to cleanly tear down OO88. `PX`/`PY`/`PZ` (the work origin) and `PH`/`PP` (the WCS / recalculated WCS numbers) are untouched.
  - Probing sections skip OO88 entirely: `writeFixtureOffset` returns early when `isProbeOperation()` is true (non-reset calls only). Probing happens with the tombstone rotated to the WCS's own home angle (part facing the spindle), so the WCS is established in its un-rotated frame; emitting `CALL OO88 ... PB=<machineB> ... PH=<workOffset>` would tell the controller "WCS was probed at B0 but we're now at B<machineB>" and the probe macros would measure in the wrong place. The stock `writeWCS` call earlier in `onSection` has already emitted `G15 H<workOffset>` to select the WCS for the probe operation. Leaving `state.twpIsActive` untouched (via the early return placed *above* the trailing `state.twpIsActive = abc.isNonZero()` assignment) keeps the next section's `cancelWorkPlane` from emitting a spurious cancel `CALL OO88 PB=0` block.
  - Skipped for `_section.isMultiAxis()` (simultaneous 5-axis): there the abc is the initial tool axis, not a WCS indexing position.
  - Validation: if more than one unique WCS is used and `(count - 1) * spacing >= 360`, the post errors out at `onOpen` to prevent the rotary from wrapping around to a duplicate orientation. (For a 4-sided tombstone with 4 WCS and 90 deg spacing, the last offset is 270 deg < 360 - passes.)
  - Marker comment: `// CUSTOM: tombstone rotary WCS` (property definitions + helper block above `onOpen` + the three application sites).

- **Reuse multi-WCS subprograms (G91 pattern dedup).**
  - Property (group `tombstone`):
    - `reuseMultiWCSSubprograms` (boolean, default `false`) - when on, sections that share a Fusion pattern ID (i.e. copies generated by the setup's "Use Multiple WCS Offsets" option) are emitted as a single incremental (G91) pattern subprogram and CALLed from each WCS instance, instead of one subprogram per WCS.
  - Requires the stock `useSubroutines` post property to be set to a mode that includes Patterns (e.g. `"All Operations & Patterns"` or `"Patterns"`). Has no effect under `"All Operations"` because that mode never invokes pattern detection.
  - Behavior: a custom branch in `subprogramIsValid` (SUB_PATTERN path) skips the default world-frame `areSpatialBoxesSame` / `areSpatialBoxesTranslated` checks - those fail for rotary-tombstone clones because the copies are rotated, not translated, in world coords. Instead, any same-`patternId` section is accepted as a valid clone and `subprogramState.incrementalSubprogram` is forced to `true`. The existing `subprogramStart` / `subprogramEnd` plumbing then wraps the body in `G91` ... `G90` via `setAbsIncMode`, so per-CALL deltas are emitted in each WCS-local frame.
  - Still rejected: sections that are `isMultiAxis()` (simultaneous 4/5-axis - body would contain rotary moves that can't be safely incrementalized), `isTCPSupportedByOperation(section)` (TCP requires absolute positions), or whose tool is `TOOL_PROBE` (probing macros bake the WCS-specific `PS=<probeWorkOffset>` into the body, so a shared subprogram would call the wrong work offset for all but one WCS instance).
  - Caveat: any path that emits an absolute block (e.g. `writeRetract` with `G90 G53`) inside the subprogram body will fight the incremental output formats. Pattern subprograms are not expected to contain mid-body retracts, but verify on first use.
  - Marker comment: `// CUSTOM: reuse multi-WCS subprograms` (property definition + the bypass branch in `subprogramIsValid`).


---

### `okuma lb3000 mill-turn.cps`

- **Re-grouped post properties with `groupDefinitions` for sidebar layout.**
  - The stock post lumped most properties under generic groups (`preferences` / `configuration` / `formats` / `multiAxis`) with no display titles or ordering, so Fusion sorted them alphabetically and labeled them with the raw keys. The properties block is now reorganized into eight cohesive groups, displayed in the order below; the new top-level `groupDefinitions = { ... }` block (added immediately above `properties = { ... }`) controls each group's title, description, and `order` index. Property *definitions* inside `properties` are reordered to match the same group sequence so the file reads top-to-bottom in display order. All property keys and types are unchanged -- only `group:` values and definition position were touched, so `getProperty("name")` callers and any saved Fusion configurations keep working.
  - Group keys → display titles → property keys (in display order):
    1. `machine` "Machine Configuration": `gotYAxis`, `gotSecondarySpindle`, `gotChipConveyor`, `maximumSpindleSpeed`, `maxTool`, `maxToolOffset`, `xAxisMinimum`.
    2. `homePositions` "Home Positions": `homePositionX`, `homePositionY`, `homePositionZ`, `homePositionW`.
    3. `spindle` "Spindle & C-Axis": `turningModeCommand`, `useGearRanges`, `optimizeCAxisSelect`, `useShortestDirection`.
    4. `cycles` "Cycles, Feeds & Arcs": `useCycles`, `feedPerRevForDrilling`, `useSimpleThread`, `useYAxisForDrilling`, `useParametricFeed`, `useRadius`.
    5. `barPuller` "Bar Puller": `useToolBarPuller`, `toolBarPullerNumber`, `barPullerZOffset`.
    6. `stockHandling` "Stock Handling": `useTailStock`, `usePartCatcher`, `autoEject`, `transferUseTorque`.
    7. `programBehavior` "Program Behavior": `optionalStop`, `safeStartAllOperations`, `loadMonitoring`.
    8. `output` "Program Output & Formatting": `showSequenceNumbers`, `sequenceNumberStart`, `sequenceNumberIncrement`, `separateWordsWithSpace`, `writeVersion`, `writeMachine`, `writeTools`, `showNotes`.
  - `groupDefinitions` is the standard Autodesk Post API mechanism for naming and ordering property groups. If a particular Fusion build doesn't honor it, the properties still work -- they'd just be shown grouped by the raw key (`machine`, `homePositions`, etc.) in alphabetical order, with no group descriptions.
  - When adding a new property, set its `group:` to one of the eight keys above and place the definition next to its siblings inside `properties = { ... }`. Don't reintroduce `"preferences"` / `"configuration"` / `"formats"` / `"multiAxis"` as group values -- they have no `groupDefinitions` entry and would surface as a stray alphabetical group at the bottom of the sidebar.
  - Marker comment: `// CUSTOM: post property groups with display titles, descriptions, and ordering` (`groupDefinitions` block).

- **Tool-based bar puller (no secondary spindle required).**
  - Our LB3000 has no programmable bar feeder and no secondary spindle. Instead we use a tool with gripping fingers that engages the bar, the chuck unclamps, the bar feeds out by the pull distance, the chuck re-clamps, and the puller retracts.
  - Properties (group `barPuller`):
    - `useToolBarPuller` (boolean, default `false`) - master enable. When on, Fusion's `Bar Pull` operation (cycle type `secondary-spindle-pull`) is rerouted through the tool-based puller routine instead of erroring with "Secondary spindle is not available."
    - `toolBarPullerNumber` (integer, 1-99, default `1`) - Fusion tool number of the puller tool. The tool's offset register is assumed to match its number (e.g. tool 6 -> `T060606` when `maxToolOffset <= 99`).
    - `barPullerZOffset` (spatial, default `0`) - Z offset of the grip position relative to the start of the unmachined stock (the chuck-side boundary of the deepest previously-machined feature, tracked automatically by the post). Positive = toward tailstock, negative = toward chuck. Use to bias the grip a hair into the unmachined region or away from a delicate machined shoulder.
  - Stock diameter is read from the active setup's workpiece bounding box (`getWorkpiece().upper - .lower`). Pull feedrate and clamp/unclamp dwell come from the Fusion bar-pull operation (`cycle.feedrate`, `cycle.dwell`).
  - The puller tool's **X offset** must be set so commanding `X0` places the fingers at the ideal grip position on the bar. The **Z offset** is calibrated normally (program Z = part WCS Z, just like every other turret tool). The grip Z is computed dynamically at post time, not baked into the tool's machine offsets.
  - **Minimum-Z tracking (`minMachinedZ`).** Module-level `var minMachinedZ` is initialized lazily on first use to `getWorkpiece().upper.z` (the front face of the original stock). `updateMinMachinedZ()` is called from `onSectionEnd` and, for sections that are not stock-transfer / sub-spindle cycles, reads `currentSection.getGlobalZRange().getMinimum()` and updates the running minimum. For radial machining sections (`getMachiningDirection(currentSection) == MACHINING_DIRECTION_RADIAL`), the cylindrical tool body extends `tool.diameter / 2` past the commanded Z toward the chuck, so that radius is subtracted before the comparison. The skip relies on `machineState.stockTransferIsActive` -- `writeToolBarPullerCycle` sets it to true at the end of the bar-pull, and the post resets it at the start of the next section's `onSection`, so during the bar-pull section's own `onSectionEnd` it is true. (The `operation:cycleType` parameter is **not** exposed on Fusion's bar-pull sections, and `isSubSpindleCycle("secondary-spindle-pull")` returns false, so those checks remain as a defensive fallback but never fire today.) The bar-puller routine adjusts the tracker explicitly via `minMachinedZ += pullDistance`.
  - **Stock-shift compensation.** After the bar feeds out by `pullDistance`, every previously machined feature physically moves +Z by the same amount. `writeToolBarPullerCycle` does `minMachinedZ += pullDistance` after the pull, so subsequent grip-Z calculations use the new bar position.
  - **Grip Z calculation.** `gripZ = minMachinedZ + getProperty("barPullerZOffset")`. The bar puller positions to `Z<gripZ>` for engagement and feeds to `Z<gripZ + pullDistance>` during the pull. If `useToolBarPuller` is off the tracker is never updated (the helper short-circuits), so there's no runtime cost when the feature is disabled.
  - Emitted sequence (in `writeToolBarPullerCycle`):
    1. Comment header (operation comment + `(BAR PULL (TOOL-BASED))`).
    2. Stop spindle, coolant off, optional stop; rapid X and Z to their `homePosition*` retracts so the tool change is clear.
    3. Tool change `T<n><n><n>` (or `T<n*1000+n>` if `maxToolOffset > 99`) via `tool1Format`.
    4. `G94` feed-per-minute mode.
    5. Rapid `X<stockDiameter>` then rapid `Z<gripZ>` (part WCS frame).
    6. Feed `X0` (engage on bar) at `cycle.feedrate`.
    7. `M84` unclamp main chuck + dwell (skipped if `cycle.dwell == 0`).
    8. Feed `Z<gripZ + pullDistance>` (positive `pullDistance` = bar pulled outward in +Z).
    9. `M83` clamp main chuck + dwell.
    10. Feed `X<stockDiameter>` (clear the fingers).
    11. `writeRetract(X)` then `writeRetract(Z)` back to home.
    12. `minMachinedZ += pullDistance` (stock-shift compensation).
    13. Set `machineState.stockTransferIsActive = true` so the next section's normal startup runs cleanly.
  - Only the `secondary-spindle-pull` cycle is supported. `secondary-spindle-return` and `secondary-spindle-grab` will error out if the property is on - they have no meaningful equivalent without a sub-spindle.
  - Marker comments: `// CUSTOM: tool-based bar puller` (property block + `writeToolBarPullerCycle` helper + short-circuit branch in `onCycle`), `// CUSTOM: bar puller minimum-Z tracking` (state + helpers above `writeToolBarPullerCycle`), `// CUSTOM: compute the grip Z dynamically` and `// CUSTOM: the stock has physically shifted` (inside the helper), `// CUSTOM: accumulate the deepest machined Z` (call site in `onSectionEnd`).

- **Configurable turning-mode entry code (G270 / M109 / None).**
  - Stock post emits `G270` (ENABLE_TURNING) before every turning section. The LB15-II's OSP control does not implement `G270` at all. What older Okumas actually need at the same point is `M109` (disable C-axis indexing) so the main spindle is free to rotate -- after any prior live-tool/milling section the C-axis is still engaged via `M110`, and trying to spin the spindle in that state errors out.
  - Property (group `spindle`):
    - `turningModeCommand` (enum, default `"g270"`) - one of:
      - `"g270"` -> emit `G270` via `gPlaneModal` (stock behavior).
      - `"m109"` -> emit `M109` (DISABLE_C_AXIS) via `mFormat`. Use on the LB15-II.
      - `"none"` -> emit nothing.
  - Implementation: a small helper `writeTurningModeEntry()` (placed immediately above `startSpindle`) reads the property and dispatches accordingly. All three stock emission sites for `ENABLE_TURNING` now call this helper instead of `writeBlock(gPlaneModal.format(getCode("ENABLE_TURNING", ...)))`:
    1. `onSection`, in the previous-spindle-was-LIVE -> new-section-is-TURNING transition branch.
    2. `onSection`, in the general turning-section startup block (after the live-spindle branch).
    3. `onClose`, after the final retract before chip-conveyor / `M30`.
  - Skipping the `gPlaneModal` call in the `"m109"` / `"none"` paths is safe because `G270` was never a real G17/G18/G19 plane code -- the stock post abuses `gPlaneModal` solely for modal de-dup, and the next legitimate plane code (`gPlaneModal.format(18)` on the line right after) re-establishes G18 correctly.
  - Marker comment: `// CUSTOM: configurable turning-mode entry code` (property block + `writeTurningModeEntry` helper + each of the 3 call sites).

- **Optional spindle gear-range output (M41 low / M42 high).**
  - The LB15-II has a 2-speed spindle gearbox: `M41` (low range) and `M42` (high range). Gear selection is required on every spindle startup -- the stock post never emits any M40-series code. Rules used here (per the machine's recommended-speed chart):
    - Main spindle turning / facing / boring -> `M42` (high range).
    - Drilling on the Z-axis centerline (drill held in turret, main spindle spinning the part) -> `M42` (high range, same as turning).
    - Live-tool sections (milling, off-center indexed drilling) -> `M41` (low range; the live-tool drive uses the low gear path).
    - Detection rule in the code: `M41` if `getSpindle(TOOL) == SPINDLE_LIVE`, else `M42`. This matches the user's three cases above because on-center axial drilling on a lathe is `SPINDLE_MAIN` (the main spindle spins the part), not `SPINDLE_LIVE`.
  - Property (group `spindle`):
    - `useGearRanges` (boolean, default `false`) - master enable. Off keeps stock behavior (no gear-range output). On for the LB15-II.
  - Implementation: in `startSpindle`, immediately before the existing `writeBlock(gSpindleModeModal.format(spindleMode), scode, spindleDir)`, a `gearCode` word is built (`mFormat.format(41)` or `mFormat.format(42)` based on `getSpindle(TOOL)`) and inserted into the same block, producing output like `G96 S500 M42 M4` (matches the hand-written reference program's format exactly). When the property is off `gearCode` is `""`, which `writeBlock` skips.
  - **Dedup:** `gearCode` is suppressed when the gear hasn't changed since the last emission. A module-level `lastEmittedGear` tracks the last-emitted gear value (41 or 42, reset to `undefined` in `onOpen`). On a section that requests the same gear, `gearCode = ""` so the `M41`/`M42` word does not appear -- the first section of each gear emits it, subsequent same-gear sections (and intra-section G96/G97 mode swaps within a single tool) don't.
  - Only affects the `startSpindle` site. `COMMAND_SPINDLE_CLOCKWISE` / `_COUNTERCLOCKWISE` in `onCommand` (which re-start the spindle after a `COMMAND_STOP`, e.g. across `M00`) intentionally do **not** re-emit the gear code -- the gear is already engaged from the prior startup and persists across spindle stops.
  - Marker comment: `// CUSTOM: spindle gear-range output` (property block) and `// CUSTOM: optional M41 (low / live tool) / M42 (high / main spindle) gear-range code, suppressed when the gear hasn't actually changed` (the emission site in `startSpindle`), `// CUSTOM: last gear-range M-code (41 or 42) actually emitted` (`lastEmittedGear` declaration).

- **Configurable Y-axis presence (turret 1).**
  - The stock `defineMachine` hard-codes `turret1GotYAxis = true`, which forces the post to emit `G138` (ENABLE_Y_AXIS, which also switches X to radius mode) for every live-tool section -- including radial drilling, which Fusion classifies as `MACHINING_DIRECTION_RADIAL` (G19 plane). On the LB15-II there is no Y-axis: radial drilling is supposed to be done with C-axis indexing + diameter-mode X (e.g. `G181 X-.5 Z.. C180 ...`), not `G138 X<radius> Y0.`. The existing `useYAxisForDrilling` property only gates the **axial** drilling branch and does nothing for radial machining.
  - Property (group `machine`):
    - `gotYAxis` (boolean, default `false`) - declares whether turret 1 has a real Y-axis. Default `false` for LB15-II / older Okuma lathes. Set to `true` on a machine that actually has Y.
  - Implementation: in `defineMachine`, `turret1GotYAxis = getProperty("gotYAxis")` instead of the hard-coded `true`. When off, `gotYAxis` flows through everywhere the post checks it: the `if (gotYAxis && ...)` gate at the top of `onSection` that emits `G138` is never satisfied, so `xFormat` stays at the diameter scale and no `Y` word is output. The radial-machining safety check in `updateMachiningMode` (`if (!gotYAxis) { if (!isMultiAxis && !yAxisWithinLimits) error(...) }`) will catch any toolpath that genuinely needs Y travel and error out -- which is the correct behavior on a no-Y machine.
  - Caveat: any milling toolpath that has actual Y motion (e.g. a slot machined off-center without polar interpolation) will error. 2D contour ops using `G137` polar interpolation are unaffected (polar interp keeps `usePolarInterpolation = true`, the `G138` gate is bypassed, and X/Y in the toolpath are converted to polar XC coords).
  - Marker comment: `// CUSTOM: declare whether the machine actually has a Y-axis` (property definition) and `// CUSTOM: turret 1 Y-axis presence is user-configurable` (the `defineMachine` site).

- **Force feed-per-revolution (G95) on drilling cycles.**
  - Property (group `cycles`):
    - `feedPerRevForDrilling` (boolean, default `true`) - when on, drilling sections are emitted in G95 (feed-per-revolution) mode regardless of the Fusion operation's feed-mode setting. Lets the operator override spindle RPM at the control without invalidating the feedrate (matches the hand-written reference program's `F0.005`-style drill feeds).
  - Implementation: helper `getEffectiveFeedMode(section)` placed immediately above `formatFeedMode`. Returns `FEED_PER_REVOLUTION` when the property is on and `isDrillingCycle(section, false)` is true, else returns the section's natural `feedMode`. The one `onSection` call site (`var feedMode = formatFeedMode(currentSection.feedMode)`) is rewritten to `formatFeedMode(getEffectiveFeedMode(currentSection))`.
  - Mechanism: `formatFeedMode(FEED_PER_REVOLUTION)` emits `G95` and sets `machineState.feedPerRevolution = true` plus `feedFormat = fprFormat`. Downstream, `getFeed()` already has a "section's feedMode is per-min but machine is in G95 -> divide by spindleSpeed" branch (line ~1192) — it fires naturally because the *natural* `currentSection.feedMode` is still `FEED_PER_MINUTE` for typical in/min drill ops. So `getFeed(cycle.feedrate)` converts the Fusion per-min value to per-rev and formats it with `fprFormat`. No other call sites need adjustment because the parametric-feed path is bypassed for drilling (`if (getProperty("useParametricFeed") && !isDrillingCycle(true))` at line ~2000).
  - Marker comment: `// CUSTOM: force feed-per-revolution (G95) on drilling sections` (property), `// CUSTOM: return the feed mode we want to drive the section with` (helper), `// CUSTOM: optionally force feed-per-rev (G95) for drilling sections` (onSection call site).

- **Bar pull prelude emitted at the previous section's end.**
  - Problem: With the stock arrangement, the bar-pull section header (`(BAR PULL1)` from Fusion's `onSection` + `(BAR PULL TOOL-BASED)` from `writeToolBarPullerCycle`) appeared *before* the wrap-up gcode (spindle stop, coolant off, optional stop, retract X/Z) that ends the previous machining operation. The output was functionally correct but read as if the wrap-up belonged to the bar-pull body.
  - Fix: in `onSectionEnd`, when the next section is a tool-based bar pull (`getProperty("useToolBarPuller")` on AND `nextSection.hasCycle("secondary-spindle-pull")`), emit the prelude (`COMMAND_STOP_SPINDLE`, `COMMAND_COOLANT_OFF`, `writeRetract(X)`, `writeRetract(Z)`, `COMMAND_OPTIONAL_STOP`) *before* the next section's `onSection` writes the operation comment. Order matches the canonical wrap-up used everywhere else in the post: spindle stop → coolant off → retract → optional stop, i.e. **home before M01**. A module-level flag `barPullPreludeEmitted` signals `writeToolBarPullerCycle` to skip its own copy of the prelude (and is reset to false after consumption so the next bar-pull, if it isn't preceded by the helper, still emits the prelude itself).
  - Guarded by `!machineState.stockTransferIsActive` so an in-progress stock transfer (e.g. a bar pull that immediately precedes another bar pull) doesn't double-stop the spindle.
  - Marker comment: `// CUSTOM: when true, the previous section's onSectionEnd has already emitted` (flag declaration), `// CUSTOM: if the next section is a tool-based bar pull` (onSectionEnd emit site), `// CUSTOM: prelude (spindle stop, coolant off, optional stop, retracts) is` (gate inside `writeToolBarPullerCycle`).

- **Output cleanup: initial home, canonical section wrap-up order, cohesive bar-pull section.**
  - Goal: every section's NC reads the same way -- start with the comment/tool change, do its work, and end with **retract X → retract Z → optional stop** so the cycle visually closes at home with `M01`. Program opens at home.
  - Changes:
    1. **Initial home in `onOpen`.** After the existing setup blocks (`G90 G80`, `G50 S<maxRPM>`, etc.), `onOpen` resets `gMotionModal` and emits `writeRetract(X); writeRetract(Z);` so the very first NC motion is `G0 X<home> / Z<home>` -- before any section header. Also resets the bar-pull tracking flags and `minMachinedZ` at the top of `onOpen` because they are module-level and would otherwise leak between posts in the same engine instance.
    2. **Removed the redundant per-section `writeRetract(X, Z)`.** The stock "Position all axes at home" block at the top of every section's `onSection` used to emit a duplicate `G0 X<home> Z<home>` immediately after the operation comment. That duplicate is now gone -- the previous section's wrap-up already left the machine at home (or, for the first section, `onOpen` did). The block's `if (newSpindle) onCommand(COMMAND_STOP_SPINDLE)` is preserved.
    3. **Bar-pull section gets a complete, self-contained wrap-up.** `writeToolBarPullerCycle` now ends with `writeRetract(X); writeRetract(Z); onCommand(COMMAND_OPTIONAL_STOP);` so the bar-pull section closes at home with an `M01`, exactly like a turning/milling/drilling section. A new module-level flag `barPullWroteOwnWrapup` (declared near `barPullPreludeEmitted`) is set to `true` after the wrap-up emits.
    4. **Stopped setting `machineState.stockTransferIsActive = true` at the end of `writeToolBarPullerCycle`.** Reason: the old flag was reused to short-circuit the next section's spindle/coolant restart, but it had two unwanted side effects -- it forced the next section's `onSection` wrap-up into the `SPINDLE_SYNCHRONIZATION_OFF` branch (emitting a bogus `M150 (SYNCHRONIZED ROTATION OFF)` line, even though no sync was active for the tool-based puller), and it caused the wrap-up to be skipped entirely when `partCutoff` was true (so the bar-pull → part-off transition ended with no `M01` and no retract before the next tool change). The new `barPullWroteOwnWrapup` flag replaces it surgically: the next section's `onSection` wrap-up block (the big `if (!isFirstSection() && insertToolCall && !(stockTransferIsActive && partCutoff))` at the top) is short-circuited only when the previous section was a bar pull, and the flag is consumed (reset to `false`) at that point.
    5. **`updateMinMachinedZ` no longer relies on `stockTransferIsActive`.** With #4, that signal is no longer set during a bar-pull section, so a new direct check `if (currentSection.hasCycle && currentSection.hasCycle("secondary-spindle-pull")) return;` skips the bar-pull section's `onSectionEnd` update. The previous `stockTransferIsActive` and `operation:cycleType` checks remain as defensive fallbacks but are now unreachable for the bar-puller flow.
    6. **N-prefix on the bar-puller tool change line.** `writeToolBarPullerCycle` now sets `showSequenceNumbers = "true"` (when `getProperty("showSequenceNumbers") == "toolChange"`) immediately before `writeBlock(pullerToolWord)`, so the puller tool call reads e.g. `N4 T070707` instead of bare `T070707`, matching the appearance of every other section's tool change.
  - Resulting flow for a typical transition: `...last cut.../ M9 / M5 / G0 X<home> / Z<home> / M01 / <blank> / (NEXT SECTION) / N# T<next> / ...`. The bar-pull section reads the same: `(BAR PULL1) / (BAR PULL TOOL-BASED) / N# T<puller> / G94 / ...pull moves... / G0 X<home> / Z<home> / M01`.
  - Marker comments: `// CUSTOM: when true, the bar-pull section just wrote its own complete wrap-up` (flag declaration), `// CUSTOM: emit initial home retract so the program starts at the home position` (in `onOpen`), `// CUSTOM: redundant writeRetract(X, Z) removed` (in `onSection`'s position-at-home block), `// CUSTOM: if the previous section was a tool-based bar pull, it already emitted its own wrap-up` (the new early-out branch in `onSection`'s wrap-up gate), `// CUSTOM: bar-pull section's own wrap-up` (inside `writeToolBarPullerCycle`), `// CUSTOM: emit an N<seqno> on the puller tool change line` (also in `writeToolBarPullerCycle`).

- **Paired commands stay inside their cycle, deduped across sections.**
  - Goal: every paired turn-on / turn-off code (`M03`/`M05`, `M13`/`M12`, `M08`/`M09`, `M110`/`M109`, `G137`/`G136`, `M41`/`M42`) is **emitted within the section that needs it**, in the canonical wrap-up order, and is **not re-emitted when nothing has changed**. A cycle that turned something on should turn it off before the section's `M01`, not have its cleanup spill into the next section's header.
  - Changes (all in addition to the **Output cleanup** entry above):
    1. **`COMMAND_STOP_SPINDLE` dedup in `onCommand`.** A new guard reads the per-spindle active flag (`machineState.liveToolIsActive` / `subSpindleIsActive` / `mainSpindleIsActive`, which `getCode("STOP_SPINDLE"|"START_SPINDLE_CW"|"_CCW", ...)` already keeps current as side effects) and `break`s without emitting when the relevant spindle isn't currently running. This fixes the stray `M12` that used to appear at the top of any section whose `previousSpindle` was reported by Fusion as `SPINDLE_LIVE` (e.g. `(PART1)` right after a bar pull) -- `liveToolIsActive` is already `false` at that point, so nothing is emitted. `forceSpindleSpeed = true` is intentionally *not* set in the skip path -- if the spindle wasn't running, the next `startSpindle` will naturally emit a fresh start.
    2. **Spindle-direction (`M03` / `M04`) dedup in `startSpindle`.** A snapshot `__spindleAlreadyOn` is captured at the very top of the function (before the `spindleDir = mFormat.format(getCode("START_SPINDLE_CW", ...))` call, which would flip the corresponding `machineState.*SpindleIsActive` flag to `true` as a side effect and defeat the check). If the spindle was already on and `lastSpindleDirection === tool.clockwise`, `spindleDir` is set to `""` so the M-word is dropped from the `writeBlock` line. This removes the redundant `M03` that the stock post emits on every G96↔G97 mode swap inside a single section (e.g. `G96 S656 M42 M3` → `G96 S656` after dedup, since the spindle is already running CW from the section's start).
    3. **`previousSpindle == SPINDLE_MAIN` wrap-up now stops the spindle.** The stock `onSection` wrap-up branch only called `COMMAND_STOP_SPINDLE` when `previousSpindle == SPINDLE_LIVE`; for a turning-to-anything transition the `M05` was deferred to the next section's "Position all axes at home" block (where it lands *after* the comment header, in the wrong section). A new `else` branch on the same `if` always calls `COMMAND_STOP_SPINDLE` -- combined with the dedup in #1, this puts `M05` reliably **before** the retract / `M01` and silently skips when there's nothing to stop.
    4. **Polar / Y-axis teardown moved BEFORE the bar-pull prelude in `onSectionEnd`.** Previously the order was: bar-pull prelude → polar interp off (`G136`) → polar coords off → Y-axis disable. That left `G136` *after* the bar-pull-prelude's `M01`. Reordering puts the cycle's own cleanup codes inside the cycle's section, ahead of the wrap-up's retract / `M01`. (For non-bar-pull transitions the polar/Y teardown also fires before the next section's `onSection` wrap-up, which preserves the same in-cycle ordering.)
    5. **`onCycleEnd` skips `G180` for the bar-pull cycle.** The stock `onCycleEnd` always emits `G180` (cycle cancel) for any non-expanded cycle, which left a stray `G180` after the tool-based bar pull's `M01`. The new early-return -- `if (getProperty("useToolBarPuller") && cycleType == "secondary-spindle-pull") { skipThreading = true; return; }` -- skips the cycle-cancel because the bar-pull body never invoked a `G18x` canned cycle.
    6. **Module-state reset in `onOpen`.** `lastEmittedGear`, `lastSpindleDirection`, and the three `machineState.*SpindleIsActive` flags are all reset (alongside the existing bar-pull flag resets) so a previous post run can't leak dedup state into the current one.
  - Net effect on a typical roughing → contour transition: was `M9 / G0 X<home> / Z<home> / M01 / <blank> / (NEXT) / M05 / ...`; now `M05 / M09 / G0 X<home> / Z<home> / M01 / <blank> / (NEXT) / ...`. Bar-pull cycle: was `... / G0 X<home> / Z<home> / M01 / G180 / G136 / <blank> / (NEXT) / ...`; now `G136 / ... / G0 X<home> / Z<home> / M01 / <blank> / (NEXT) / ...` (and the bar-pull section's `G136` lands inside the cycle's polar-using section, not the bar-pull's).
  - Marker comments: `// CUSTOM: skip M05/M12 when the relevant spindle isn't currently running` (`onCommand(COMMAND_STOP_SPINDLE)` dedup), `// CUSTOM: snapshot whether the relevant spindle is already running` (`startSpindle` snapshot), `// CUSTOM: suppress the M03/M04 spindle-direction word` (`startSpindle` dedup site), `// CUSTOM: stop the main spindle too` (the new `else` branch in `onSection`'s wrap-up), `// CUSTOM: run polar / Y-axis teardown BEFORE the bar-pull prelude` (`onSectionEnd` reorder), `// CUSTOM: tool-based bar pull doesn't use a canned drilling cycle` (`onCycleEnd` early-return).

---


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
