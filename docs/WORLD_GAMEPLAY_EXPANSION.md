# TRush world and gameplay expansion

The current world spans 240 x 240 world units around the original central recycling hub.

## Included
- Deep forest, waste valley, rocky highlands with traversable procedural hills, an eastern stream and pond, trails between regions, and a roots overlook landmark.
- Up to 128 tree placements across the main forest and deep-forest region, 324 clustered grass patches, procedural shrubs and randomized rocks.
- Four waste visual categories (plastic bottle, aluminum can, paper/cardboard and glass container) with differentiated recycling rewards.
- Recycling station with sorting-bin visuals and a short scale pulse on deposit.
- Short FOV feedback tween when collecting waste.
- Wildlife actor refinements: facial details, species silhouettes, idle movement and bounded wandering around each animal's habitat.
- Progression markers for Arroyo (35%) and Borde Salvaje (70%), persisted as unlocked zone milestones.
- Three garbage mountain mini-bosses, configured in `data/bosses/garbage_mountains.json`, with separate health, damage stages, vacuum targeting, physical drops, defeat rewards and persistent drop/boss progress.
- Boss drops are ordinary `TrashPickup` items; each occupies one bag space and only counts as recovered when collected individually.
- Procedural terrain color variation, distance fog, animated water and instance-driven wind in grass.
- Batched grass, shrub, berry and tree-canopy meshes reduce independent scene nodes and draw submissions.
- Rounded HUD panels, buttons and timed notifications; mission text, bestiary, pause/menu panel, session stats and restoration achievements.

## Current limitations
- Natural assets and hills use procedural primitive and surface meshes; they are not final authored or scanned art.
- Static hills use trimesh collision, while roads and water surfaces are visual only on the globally walkable ground.
- Boss combat, drop extraction, drop restoration from save data, bag caps and one-time rewards were code-reviewed and covered by project startup, but were not driven through a manual gameplay session.
- Sound assets are absent, so damage/release feedback is visual; the CPU particle burst is intentionally small.
- No graphical FPS, GPU, draw-call or memory profile was captured. A graphical inspection on target hardware remains necessary.
