# Changelog

## [1.0.0] – 2026-09-25

- Initial release. Adds a **Bug Fixes** tab; every fix can be switched off on its own.
- **Coal quota overflow** – from day 62 (32 days past the quota table) the quota went negative
  (about -1.1e29) because `increaseQuota` grows it with an integer power. It now keeps growing
  x4 per day in floating point; earlier days are unchanged.
- **Save restore** – a missing or corrupt primary save loaded defaults (or nothing) even though an
  intact backup existed, and the next save then overwrote the backup too. The backup is now put
  back before loading (globals, records, hard-modifier records).
- **Stuck pause** – resuming with Esc could leave the game paused with no menu (the pause menu
  re-paused the tree in the same frame). The menu stops processing before it resumes.
- **Negative cash** – buying the maximum affordable employees could leave cash slightly below zero
  (float rounding, up to -65536 at large balances). Negative results are clamped to zero;
  fractional purchases are unchanged.
- **Loot duplication** – a pickup that had just been merged or fully collected could be merged or
  collected again in the same frame (8 coal could become 11). Spent pickups are now skipped.
- **Loot cap during bursts** – the world loot cap never engaged when thousands of drops happen in
  one frame (nukes, earthquakes): 3000 drops made 3000 pickups. Drops past the cap are now bundled
  for the rest of the frame (about 400 pickups), with no loot lost.
- **Explosion edges** – bombs and earthquakes never reached the bottom row and right column of
  their circle. The skipped tiles are now hit.
- **x0 employee boxes** – float dust left after promotions showed "x0" boxes with a sell button.
  Counts that display as zero are hidden like an exact zero.
