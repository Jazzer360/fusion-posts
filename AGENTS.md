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


---

## Working Workflow

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
