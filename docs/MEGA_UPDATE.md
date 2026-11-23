# TRush mega update: world and garbage mountains

> This page records the preceding world-expansion milestone. The current startup scene, three-profile saves, minimap/radar, UI options and seismic boss changes are documented in [MAJOR_UPDATE_NAVIGATION.md](MAJOR_UPDATE_NAVIGATION.md).

## Audit and branch

- The project is a Godot 4.7.2 first-person game with `scenes/main/main.tscn` as its entry scene.
- `scripts/main.gd` owns world generation, day/night, economy, upgrades, restoration, saves and UI wiring. Player movement, ordinary pickups, wildlife and HUD construction live in separate scripts.
- Before this update, the world was a flat 120 x 120 plane; ordinary garbage was the only entity in the vacuum collection group. Several project edits and untracked Godot binaries/import UID files were already present. They were preserved.
- Work stayed on `feat/trush-ecosystem-progression-vacuum-expansion`; no branch switch or commit was made. HEAD at audit time: `33e83bd` (`Cluster grass patches and refine blade geometry`).
- Neither `Godot.exe` nor `Godot_v4.7.2-stable_win64_console.exe` was modified.

## World regions

The walkable plane is now 240 x 240 world units. The center keeps the recycling station, shop and rest hut. Four paths lead out to:

- **Deep forest** near (-67, -68): denser tree placement, varied crown silhouettes and fallen logs.
- **Waste valley** near (66, -65): tire and scrap dressing plus three separate garbage mountain encounters.
- **Rocky highlands** near (-70, 66): three procedural, walkable hills with static trimesh collision.
- **East water region** near (70, 68): a shallow pool, short stream surface with vertex-wave animation and shoreline reeds.
- **Roots overlook** near (0, 99): a stone landmark at the end of an exploration route.

Region helpers live in `scripts/environment/world_region_generator.gd`. The biome JSON records the region layout; the current runtime still defines its placement data in `scripts/main.gd`.

## Garbage mountain encounters

Encounter data is centralized in `data/bosses/garbage_mountains.json` and the shared behavior is in `scripts/environment/garbage_mountain_boss.gd` / `scenes/boss/garbage_mountain_boss.tscn`.

| Archetype | HP | Direct reward | Regular drops | Final drops |
|---|---:|---:|---:|---:|
| Plastic Mountain | 520 | $180 | 24 | 7 |
| Scrap Mountain | 860 | $340 | 28 | 9 |
| Mixed Waste Mountain | 1,100 | $520 | 36 | 12 |

The player must unlock the existing vacuum, aim at the boss and hold **F** in range to deal damage. Vacuum levels increase damage by 35% per level after level one; magnet skill levels add 8% each. Stages at 66% and 32% health change the debris arrangement and HUD color. The boss is not in the ordinary garbage group and cannot be picked up by click or vacuum. It does not add to restoration while intact.

Vacuum contact releases one ordinary `TrashPickup` at a time. A defeat queues a bounded final batch, at most two instantiated pickups per frame. Each pickup occupies one bag slot, follows the regular click/vacuum collection rules and contributes to recovery only when picked up. It never puts anything directly in the bag. Defeat pays cash and XP once; boss HP, defeat IDs, drop count and uncollected released pickup records are saved.

The HUD shows the nearest boss within 22 m or the boss under the crosshair. Shop, pause, bestiary, stats, skills and menu overlays hide the panel.

### Character and encounter visual follow-up

- Bosses now have a readable humanoid outline built from compacted-waste torsos, scrap heads, glowing eyes, teeth, shoulders, articulated-looking arms and fists, legs, tire pads and metal boots. The three configured bosses have individual names: **Plastón, el Devorador**, **Don Chatarra** and **Mestizón, el Coloso**.
- Hornero, zorro gris and venado de campo use denser smooth meshes, layered coats, facial features, feather/antler details and animated limbs. Their wandering speeds and gait cadence have been increased modestly; night resting remains intact.
- A shared pickup visual builder now gives both starting trash and boss drops the same recognizable bottles, bags, capped containers, labeled cans, folded scrap, treaded tires, layered cardboard and glass bottles. Pickup collision and inventory behavior are unchanged.
- The pond surface is a subdivided plane clipped to a circular mask. Concentric ripples fade at the bank so the animated water stays inside the pond edge. Textured-look lily pads have visible veins, and a detailed tree frog hops to another pad every few seconds.
- Bosses now use bounded pursuit while collection is enabled, keep to a home radius and throw archetype-colored trash projectiles at the player. Projectile hits use the player's health interface; knockout prevents repeated damage during the recovery delay.
- The player has a 100-point health bar. At zero health, movement and collection stop; after five seconds the player respawns beside the recycling station at full health, keeps the current bag contents, and receives three seconds of hit protection.
- A modeled fruit basket beside the recycling station holds three fruits per day. Pressing **R** within range consumes one and randomly grants a 60-second speed, vacuum damage, vacuum range or damage-resistance boost, or restores 35 health. Fruit count and day number persist in the existing save file and the basket refills when the next day is started.

## Visual and performance work

- Added textured procedural ground color, distance fog, filmic tonemapping and animated water/grass shaders.
- Varied tree crown widths/heights and grouped canopy instances into four spatial batches for better culling.
- Grass, shrubs and berries now use `MultiMesh`; static mountain collision is generated once per hill. Rock/log decoration uses visual meshes, with collision only on larger obstacles.
- The recycling bins have lids and material labels; the hut has a floor, door, window and rafters.
- Boss hits use a small CPU debris burst and squash/wobble feedback. No audio assets exist, so there is no new sound effect.
- The three boss movement/attack configurations are data-driven alongside their health, drops and rewards. Only a few active bosses and short-lived projectiles are present, avoiding large per-frame entity scans.
- This is still stylized procedural geometry, not production PBR/scanned art. No target-hardware FPS/draw-call profile was captured.

## Validation performed

Commands run from the repository root with Godot 4.7.2 for the main update and follow-up:

```powershell
& '.\Godot.exe' --headless --editor --path . --quit
& '.\Godot.exe' --headless --path . --quit-after 420
git diff --check
```

The Godot import and startup commands returned exit code 0 with no script parse errors or startup script runtime errors. The latest editor check and 420-frame smoke check also completed without script errors. Godot could not read the Windows certificate store or write its `user://logs` and global editor settings in this restricted environment. The dummy headless renderer reported outstanding RIDs/ObjectDB instances at shutdown; that warning is recorded and was not treated as a graphical performance result. No automated gameplay test suite exists in the repository. The revised animals, frog hops, boss silhouettes, pond edge, fruit interaction, player knockout/revival and boss combat have not yet been inspected in a graphical gameplay run, and no target-hardware performance profile was captured.

## Known limitations

- The map surface is still a level plane with separate hill meshes; the paths and stream are visual overlays, not terrain cuts or water volumes. Hill surfaces have collision; the stream does not slow or block the player.
- The region JSON is descriptive metadata rather than the runtime source of region generation.
- Boss placement and region composition are deterministic code-defined layouts; decoration placement remains seeded/randomized within the regions.
- Boss combat relies on the existing vacuum purchase and daylight collection rule. The audio system has no imported content.
- Knockout currently freezes the first-person player and reports the five-second recovery through HUD messages; it does not include a ragdoll, downed animation or visual countdown. Respawn preserves the bag and grants brief invulnerability.
- Boss limbs and animal anatomy are still procedural mesh assemblies rather than skinned characters. They use a small number of extra mesh pieces for silhouette and facial detail; draw calls and frame time have not been measured on the target machine.
- A graphics-enabled run is still required to inspect shader appearance, scene scale, path readability, clipping and actual performance on the target machine.
