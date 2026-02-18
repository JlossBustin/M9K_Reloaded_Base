# M9K Reloaded (M9KR) — Weapon Base for Garry's Mod

M9K Reloaded is a from-scratch rebuild of the classic M9K weapon base, designed to bring modern weapon mechanics and polished presentation to Garry's Mod. It serves as the shared foundation for all M9KR weapon packs (Small Arms, Extra Weapons, etc.), providing three specialized sub-bases that weapons inherit from depending on their type.

## Sub-Bases

| Base | Purpose |
|---|---|
| `carby_gun_base` | Standard firearms — pistols, SMGs, rifles, LMGs |
| `carby_shotty_base` | Shotguns — shell-by-shell reload, pump/semi/double/burst fire modes |
| `carby_scoped_base` | Scoped weapons — bolt-action rifles, DMRs, sniper rifles with full scope overlays |

## What's New Over Original M9K

### Fire Mode System
Weapons can define multiple fire modes (automatic, semi-auto, burst, single-shot, etc.) and players cycle between them in-game with `USE + RELOAD`. Each mode dynamically adjusts the weapon's firing behavior — burst mode fires a configurable number of rounds per trigger pull, semi locks to one shot, and so on.

### Safety Mode
`SHIFT + USE + RELOAD` engages the safety, lowering the weapon to a passive hold type and blocking all fire, ADS, and mode switching. The weapon remembers which fire mode was active before safety was engaged and restores it on exit.

### Tactical Reload & Chamber System
Weapons distinguish between tactical reloads (magazine swap with a round still chambered) and empty reloads (slide locked back, chamber empty). A tactical reload loads `magazine capacity + 1`, with the extra round representing what's already in the chamber — pulled from reserve ammo, not created from thin air.

### Suppressor System
Weapons flagged as suppressable can have a suppressor attached or detached in-game via `USE + ATTACK2`. Attaching/detaching plays a dedicated animation, swaps the world model, switches to silenced fire sounds, and changes the muzzle flash to a subdued effect. All state is fully networked so other players see the correct model and hear the correct sounds.

### Caliber-Driven Ballistics
Each weapon declares its caliber via a shell casing model path. The base uses this to automatically look up real-world ballistic data from a database of 40+ calibers (9x19mm through 23mm autocannon), providing:

- **Penetration** — bullets pass through surfaces based on caliber energy and material type (wood, concrete, metal, flesh), with exit wounds and reduced damage
- **Ricochet** — shallow-angle impacts can ricochet off hard surfaces, with caliber-appropriate bounce limits and a halved-damage ricochet round
- **Tracers** — caliber-specific tracer colors (NATO red, Soviet green, British white), frequency (every 3rd–5th round depending on weapon type), and beam width scaled to bullet diameter

### Custom Muzzle Flash System
Replaces all stock Source engine muzzle flash events with PCF particle-based effects, broken out by weapon category (rifle, pistol, SMG, shotgun, sniper, revolver, LMG, HMG, silenced). Includes optional dynamic lighting, heatwave distortion, and scotch flash sprites — all individually togglable via ConVars. Compatible with TFA Realistic Muzzleflashes 2.0.

### Shell Ejection
Custom shell casings are spawned as physics props with caliber-appropriate models, bounce behavior, and collision sounds. Casings are networked so other players see shells ejecting from world models in third person.

### Recoil & Spread
Camera recoil moves the player's actual aim (not just visual punch), with separate vertical, horizontal, and downward kick values per weapon. ADS reduces recoil significantly, and crouching stacks an additional reduction.

Spread is dynamic rather than a flat cone — the first shots from ADS are perfectly accurate, with spread increasing progressively during sustained fire and resetting when the player stops shooting.

### Shotgun Shell-by-Shell Reload
The shotgun base implements a proper state machine (`START → LOOP → WAIT → FINISH`) for inserting shells one at a time. Each shell insertion plays its own animation loop, and the reload can be cancelled mid-way by pressing fire — any shells already loaded are kept.

### Scoped Weapons
The scoped base provides a full scope overlay system with support for multiple optic types (ACOG, Mil-Dot, SVD, Elcan, Vortex AMG, Burris MTAC, red dot hybrid, and more). Each optic type has its own reticle scale. Scope view includes animated sway influenced by breathing, walking, sprinting, and lateral movement. The viewmodel is hidden during ADS for a clean scope picture.

### Belt-Fed LMG Visualization
Three methods for visually representing remaining belt ammo on LMGs: bodygroup switching (toggle belt mesh at ammo thresholds), bone scaling (individual bullet bones shrink to zero as ammo depletes), and multi-bodygroup (each round is an independent bodygroup). Belt visibility is managed during reloads with configurable hide/show timing.

### HUD
A custom HUD replaces the default GMod ammo display, showing the weapon name, current fire mode (color-coded), caliber designation, magazine count with a `+1` chamber indicator, reserve ammo, and health/armor. The HUD fades to low opacity after a few seconds of inactivity. An NPC squad tracker displays friendly citizen and medic icons when applicable.

### Other Features
- **Low ammo warning** — caliber-type-specific audio cues when the magazine drops below a configurable threshold (default 33%), with a distinct last-round sound
- **Tick-rate compensated fire rate** — RPM calculations account for server tick interval, ensuring consistent fire rates on both 33-tick and 66-tick servers
- **Viewmodel bone mods** — weapons can reposition, rescale, or re-angle individual viewmodel bones for precise first-person presentation
- **Server ConVars** — global damage multiplier (`M9KDamageMultiplier`), default clip multiplier (`M9KDefaultClip`), auto-strip empty weapons (`M9KWeaponStrip`)
- **Bullet impact effects** — material-aware impact particles (metal sparks, dust puffs, generic impacts), each toggleable via ConVar

## Requirements

- [Garry's Mod](https://store.steampowered.com/app/4000/Garrys_Mod/)
- At least one M9KR weapon pack (Small Arms, Extra Weapons, etc.)

## Controls

| Input | Action |
|---|---|
| `USE + RELOAD` | Cycle fire mode / exit safety |
| `SHIFT + USE + RELOAD` | Toggle safety on |
| `USE + ATTACK2` | Attach/detach suppressor (if available) |
