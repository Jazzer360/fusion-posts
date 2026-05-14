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
   - Clearly marked with a comment like `// CUSTOM: <reason>` so they can be re-applied when the upstream post is updated.
   - Ideally gated by a user-defined `property` (added to the `properties` and `propertyDefinitions` objects near the top of the post) so behavior is toggleable from Fusion's Post Properties UI.
5. **Do not introduce ES6+ syntax that may not be supported** by Fusion's embedded engine. The existing posts use ES5-style code (`var`, function expressions, no arrow functions in most places, no template literals). Match the surrounding style.
6. **Numbered duplicate files** (e.g. `okuma 2.cps`, `okuma 2 2.cps`) are Fusion's automatic duplicates created when the user clicks "Duplicate" on a post in the Manage Posts dialog. They represent historical snapshots of customizations. Do not delete them without asking — they are the user's change history prior to git.
7. **When updating to a newer upstream post:** the workflow is (a) drop the new public post in as a fresh file, (b) diff against the most recent customized variant to identify the deltas, (c) re-apply the custom deltas on top of the new public version. Use `Compare-Object` in PowerShell or `git diff --no-index` for diffing.

---

## File Inventory (as of repo initialization)

| File | Upstream Revision | Upstream Date | Notes |
|------|-------------------|---------------|-------|
| `okuma.cps` | 44220 | 2026-04-01 | Current public Okuma milling post. **No customizations applied yet.** This is the base to build from going forward. |
| `okuma 3.cps` | 44210 | 2026-01-20 | Previous public Okuma milling post **with the G30 P5 customization** (see below). |
| `okuma 2.cps` | 44084 | 2023-08-14 | Older public Okuma milling post with an earlier `G30 P2` customization. Historical. |
| `okuma 2 2.cps` | 44084 | 2023-08-14 | Same as `okuma 2.cps` but with `P2` changed to `P5`. The single-line evolution of the customization. |
| `okuma lb3000 mill-turn.cps` | 44210 | 2026-01-20 | Okuma LB3000 lathe (OSP-300L) mill-turn post. No customizations yet. |

### Known Customizations (carried forward from prior versions)

- **G30 P5 at program end** (mill posts only).
  - Adds `G30 P5` after the final `writeRetract` and before `setSpindleLoadMonitor(false)` in `onClose`.
  - Purpose: send the machine to the user's preferred secondary reference point at end of program (machine-side preset position #5).
  - Present in: `okuma 3.cps` (line ~2339), `okuma 2 2.cps` (line 3470).
  - **NOT yet applied to `okuma.cps`.**

---

## Working Workflow

1. Make changes directly to the `.cps` file in this folder.
2. In Fusion 360 → Manufacturing → Post Process, pick the post (it shows under Personal Posts).
3. Generate output for a representative toolpath. Inspect the NC file.
4. Iterate. Commit incremental working changes to git.
5. For risky changes, branch (`git checkout -b feature/...`).

## Quick Reference: Post API Essentials

- `writeBlock(...)` — emit one NC line. Arguments are individual formatted words.
- `writeln(text)` — emit a raw line.
- `writeComment(text)` — emit a comment (controller-appropriate syntax).
- `createFormat({...})` / `createOutputVariable(...)` — define how numeric values are formatted/output.
- Event handlers (called by the engine): `onOpen`, `onSection`, `onSectionEnd`, `onLinear`, `onRapid`, `onCircular`, `onCommand`, `onClose`, `onParameter`, `onCycle`, etc.
- `getProperty("name")` — read a user-configurable property.
- `properties` and `propertyDefinitions` objects (top of file) — declare user-configurable settings shown in Fusion's Post Properties dialog.
- `getSection(i)`, `currentSection`, `isFirstSection()`, `isLastSection()` — section iteration helpers.

Full reference: https://cam.autodesk.com/posts/reference/index.html

---

## Notes for the User

- This file (`AGENTS.md`) is the canonical AI-assistant briefing. Tools that look for `.github/copilot-instructions.md`, `CLAUDE.md`, or `.cursorrules` can be pointed here via a symlink or short stub if needed.
- No language runtime is required for development. `git` is the only required tool.
