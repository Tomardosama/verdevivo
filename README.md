# TRush

**TRush** is a 3D first-person ecological restoration game built with Godot 4.7.

## Current systems

- First-person movement, mouse look and sprint.
- Click-to-collect waste with a limited bag.
- Recycling station, deposits and money rewards.
- HUD with money, bag capacity, restoration percentage and day/night clock.
- Day and night phases: waste collection during the day, upgrades during the night.
- Five upgrade tracks: movement speed, bag capacity, recycling value, collection range and day duration.
- Forest restoration milestones with visible wandering wildlife: hornero, zorro gris and venado de campo.
- Interactive bestiary with educational species descriptions and persistent unlocks.
- Prestige reset with persistent upgrades and a prestige reward.
- Local save data in Godot's `user://trush_save.cfg`.

## Controls

- **W A S D**: move
- **Mouse**: look
- **Shift**: sprint
- **Left click**: collect waste while it is daytime
- **E**: deposit the bag near the recycling station
- **Esc**: release mouse; click to capture again

## Run locally

Import `project.godot` using Godot 4.7 and press F5.

See [docs/GODOT_GITHUB_WORKFLOW.md](docs/GODOT_GITHUB_WORKFLOW.md) for the GitHub Desktop workflow and [docs/AUTOMATED_VALIDATION.md](docs/AUTOMATED_VALIDATION.md) for CI validation.

## Validation status

The repository changes are reviewed statically, but a Godot runtime/import check must still be performed on a local Godot installation. Primitive meshes are placeholders pending final art, animation, sound, deeper biome simulation and balancing.
