# graphify
- **graphify** (`~/.claude/skills/graphify/SKILL.md`) - any input to knowledge graph. Trigger: `/graphify`
When the user types `/graphify`, invoke the Skill tool with `skill: "graphify"` before doing anything else.


## File Editing Rules
- Never perform a single `Edit` larger than 40 lines. Break large refactors into multiple small, sequential edits.
- Always read the target line range immediately before editing to verify exact indentation.
- If an `Edit` fails twice due to string mismatch, fall back to rewriting the file or using a Python script to apply the change cleanly.