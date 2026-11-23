# Portable Cleaner and HUD Update

## Implemented

- The existing night shop sells one **Limpiadora Automática Portable** per profile for **$5,200**. It is built from a compact procedural mesh assembly and is parented to the player's camera carry mount after purchase. The carrying prompt takes priority over the ordinary `E` deposit action.
- While carried, a green/red ghost preview follows a grounded placement point. Installation is restricted to the existing circular pond and a configured segment of the actual water ribbon called **Arroyo de la Rana**. Invalid `E` input leaves the model in the player's hand. Successful installation reparents the same model, plays a short placement animation and starts the rotor/status lamp.
- The operating machine banks **$1 per in-game minute** at base level. Income and storage are configurable in `data/economy/automated_cleaner.json`. The initial storage is **$180**; it stops when full and resumes after collection. The bank is never paid out automatically, and income does not accrue offline.
- Income levels are **$1, $2, $3, $4, $6, $8 per minute**, with configured costs **$900, $1,800, $3,600, $7,200, $12,500**. Storage levels are **$180, $360, $600, $900, $1,300, $1,800**, with configured costs **$700, $1,400, $3,000, $6,200, $11,500**. The existing discount upgrade also affects the new upgrade costs. Values are centrally editable.
- E near the installed machine opens its status panel. It shows operational state, income rate, banked money and storage fill; its controls collect the bank once or switch the machine off. Shop upgrades unlock only after installation and remain independently gated by affordability and night-time shop access.
- Area signs use the existing player-facing root script, with the readable +Z front directed toward the player. The shop's Label3D billboard remains enabled so it is readable from its normal kiosk approach.
- Boss-area entry shows the vacuum-required line before vacuum ownership. After the player owns the vacuum, a genuine exit/re-entry shows **“¡Aspiradora, yo te elijo!”** once. The ownership and one-time flag are saved per profile.
- The small duplicate bag line has been removed from the top-left status stack. The bottom-right sack uses an original SVG silhouette, a fill-mask shader, an animated percentage fill and a foreground current/capacity counter. The displayed capacity comes from the live player inventory and updates through the existing inventory signal.

## Save compatibility

`TRushProfiles.SAVE_VERSION` is now **4**. Existing older profiles remain loadable; absent fields default to no cleaner, no intro flags and the existing vacuum upgrade state. Each slot stores cleaner ownership, installation/location/position, operational state, bank, levels and sub-minute elapsed time. Vacuum ownership and both boss-dialogue flags are stored with progress. A profile reload reconstructs one machine and does not transfer its bank into the wallet. Only time accumulated while the game is running counts; the elapsed sub-minute remainder is saved.

## Validation

- `git diff --check`: passed.
- Godot **4.7.2.stable.official.ed1daf0bf** headless import completed with exit code 0. Godot registered the cleaner script class. It also reported that the system certificate store could not be read and editor settings could not be saved in this environment.
- Headless project startup (`--headless --path . --quit-after 5`) completed with exit code 0. The same environment emitted log-file write and certificate-store errors.
- `tests/major_update_smoke.gd`: all **65 assertions passed**. Coverage includes purchase price/duplication, both placement zones, invalid placement, installation, operational toggle, storage/income upgrades, cap/collection, sign facing math, actual bag capacity/fill, boss dialogue, save/reload state and no duplicate wallet transfer. At shutdown, Godot emitted dummy-renderer RID/ObjectDB/resource leak warnings; these did not fail the assertions.
- The graphical project was launched with `Godot.exe --path .` using the configured renderer, and its `TRush (DEBUG)` process remained alive. The initial scene configured by the project is `res://scenes/ui/main_menu.tscn`. The desktop capture bridge timed out twice, so the visible frame and gameplay visuals could not be inspected.
- Performance profiling and visual inspection on target hardware remain untested. The cleaner model is procedural, has no added collision body, and uses one animated rotor plus one status light; it adds no per-frame world scan or spawned debris loop.

## Known limits

- Placement points follow a configured circular-pond radius and a configured Frog Stream segment rather than sampling arbitrary water geometry. The stream coordinates are tied to the current world map data and should be updated together if the water route changes.
- The model has no dedicated sound asset or splash particles. Its operational feedback is the turning filter drum and pulsing lamp.
- The affordability, balance curve and HUD layout still need playtesting in the graphical build.
