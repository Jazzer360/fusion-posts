# Fusion 360 Post-Processor Customizations

Development workspace for personal customizations of Autodesk Fusion 360 post-processors.

**Posts:** Okuma milling (OSP controller), Okuma LB3000 mill-turn lathe.

See [`AGENTS.md`](AGENTS.md) for development conventions, file inventory, and AI assistant guidance.

## Reference

- Post Processor API: https://cam.autodesk.com/posts/reference/index.html
- Autodesk public post library: https://cam.autodesk.com/hsmposts

## Layout

This folder sits at `%APPDATA%\Autodesk\Fusion 360 CAM\Posts`, so Fusion picks up edits directly under "Personal Posts" in the Post Process dialog. No build step required.
