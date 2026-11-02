# SellNPC development entry point

Before making changes, read the current `SellNPC/WORKFLOW.md` and `SellNPC/TESTING.md` from the repository branch. `master` of this multi-addon repository has not adopted equivalent root documents; use these addon-scoped records for SellNPC until repository-wide adoption is agreed.

Preserve prior working behavior and keep experimental code on a development branch. Update cumulative `TESTING.md` without discarding past test history. Review the current profile and all diffs before publishing. Separate Lua syntax/mock simulation from real Windower/FFXI verification. Keep attribution for upstream SellNPC.

When packaging a SellNPC test ZIP, include `SellNPC/README.md`, `SellNPC/WORKFLOW.md`, and `SellNPC/TESTING.md` inside the addon folder alongside source, not as extra files at the outer ZIP root.
