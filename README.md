# TRush

**TRush** is a 3D first-person ecological restoration game built with Godot 4.7.

## Current systems

- First-person movement, mouse look and sprint.
- Click-to-collect waste with a limited bag.
- 240 × 240 explorable world with a deep forest, waste valley, decorative rocky highlands, animated stream/pond, trail network and overlook landmark.
- Roots Lookout radar with a $1000 one-time unlock, configurable-range coverage and live red markers for actual ordinary garbage.
- Top-down minimap with player direction, water, trails, landmarks, region clues and separate boss markers.
- Startup menu with three independent named save slots, load/new-game flows and confirmed overwrite or deletion.
- Persistent options for audio levels, mouse sensitivity, brightness, FOV, MSAA quality, resolution, fullscreen and UI labels/theme/accent/font scale.
- Three configurable Garbage Mountain boss archetypes with vacuum combat, staged damage, controlled physical drops, rewards and saved encounter progress.
- Mobile garbage bosses with telegraphed seismic attacks, plus player health and a five-second respawn at the recycling station that preserves the bag.
- A daily fruit basket with three servings; eating one grants a random temporary movement/vacuum/defense boost or restores health.
- An expensive portable automated cleaner: carry its physical model, install it at the circular pond or Frog Stream, collect its capped passive bank, and invest in independent income/storage upgrades.
- A large bottom-right bag silhouette HUD with a clipped animated fill and the player's actual upgraded capacity.
- Contextual boss-area vacuum dialogue, with the post-purchase introduction shown once per profile.
- Named humanoid waste bosses: Plastón, Don Chatarra and Mestizón, assembled from bottles, metal, tires and compressed trash.
- Wind animated grass plus `MultiMesh` batches for grass, shrubs, berries and tree canopies.
- Four collectible waste categories with different recycling rewards.
- Upgraded recycling station with animated deposit feedback.
- Rounded HUD panels, timed notifications, mission prompts, pause menu and session statistics.
- Day and night phases: waste collection during the day, upgrades during the night.
- Five upgrade tracks: movement speed, bag capacity, recycling value, collection range and day duration.
- Forest restoration milestones with smoother, more detailed and faster wandering wildlife: hornero, zorro gris and venado de campo.
- A circular, contained pond with concentric water ripples, veined lily pads and a frog that hops between them.
- More recognizable pickups with shared detailed models for plastic, metal, glass, tires, bags and cardboard.
- Progressive zone discovery milestones and four restoration achievements.
- Interactive bestiary with educational species descriptions and persistent unlocks.
- Prestige reset with persistent upgrades and a prestige reward.
- Versioned per-profile save data in `user://trush_profile_1.cfg` through `_3.cfg`; legacy `user://trush_save.cfg` is copied to slot 1 when needed. Global settings live in `user://trush_settings.cfg`.

## Controls

- **W A S D**: move
- **Mouse**: look
- **Shift**: sprint
- **Left click**: collect waste while it is daytime
- **F**: vacuum nearby waste or damage an aimed garbage boss after purchasing the vacuum upgrade
- **E**: deposit the bag near the recycling station
- **E** near the cleaner: install it in an approved water zone or open its management panel
- **R** near the basket: eat one of the three daily fruits and receive a random effect; near Roots Lookout, unlock/toggle the radar
- **Esc**: release mouse; click to capture again

## Run locally

Import `project.godot` using Godot 4.7 and press F5.

See [docs/GODOT_GITHUB_WORKFLOW.md](docs/GODOT_GITHUB_WORKFLOW.md) for the GitHub Desktop workflow and [docs/AUTOMATED_VALIDATION.md](docs/AUTOMATED_VALIDATION.md) for CI validation.

## Validation status

Godot 4.7.2 headless import and project startup completed, and the expanded 65-assertion gameplay smoke suite passed. Headless output still reports certificate/log-write issues and dummy-renderer resource/ObjectDB leak warnings at shutdown. The game was also launched with the normal renderer and remains open on its configured main-menu scene, but the desktop capture bridge timed out twice, so visual inspection is not confirmed. Target-hardware performance profiling remains outstanding. Models remain procedural; no external sound assets or final character animation are included.

See [docs/PORTABLE_CLEANER_UPDATE.md](docs/PORTABLE_CLEANER_UPDATE.md) for the new machine economy, placement, save fields and validation limits. See [docs/MAJOR_UPDATE_NAVIGATION.md](docs/MAJOR_UPDATE_NAVIGATION.md) for profiles, radar, menu/options, seismic combat and known limitations. [docs/MEGA_UPDATE.md](docs/MEGA_UPDATE.md) documents the preceding world-expansion milestone.
