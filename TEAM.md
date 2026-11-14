# Bounceback Golf: team plan

**Jam theme:** Bounceback · **Engine:** Godot 4.7.2 (standard, GDScript) · **Target:** web build on itch.io

**MVP:** a bouncy ball you launch by dragging and releasing. You climb an obstacle course and reach the hole at the top. If you fall, you fall, and you climb back up yourself.

**Goal:** have the MVP playable in the browser by **hour 16–20**.

Each person has a ready-made AI agent prompt in [`prompts/`](prompts/):
[Person A](prompts/person-a-ball.md) · [Person B](prompts/person-b-level.md) · [Person C](prompts/person-c-game-ui.md)

---

## Getting started (everyone)

1. Install **Godot 4.7.2** (standard, not .NET). Everyone must use the exact same version.
2. Clone the repo: `git clone https://github.com/Khazap/bounceback-golf.git`
3. In Godot's Project Manager, click **Import** and pick `project.godot`. Don't create a new project.
4. Paste your prompt from `prompts/` into your AI agent, opened in your clone.

## Team rules

- **Only edit files you own.** Two people editing the same `.tscn` file causes merge conflicts that are very hard to fix. If you need a change in someone else's file, ask them.
- **`project.godot` and `.gitignore` belong to Person C.** If Godot changes `project.godot` by itself on your machine, discard it: `git checkout -- project.godot`
- **Never commit `.godot/`** (already ignored). Do commit the `.uid` and `.import` files next to your own scripts and assets.
- **Commit small and often.** Before pushing: `git pull --rebase`, then `git push`.

## Shared contracts (don't change without telling the team)

| Thing | Agreement |
|---|---|
| Folders | `scenes/ball/`, `scenes/level/`, `scenes/ui/`, `scripts/`, `art/`, `audio/` |
| Ball | `res://scenes/ball/Ball.tscn`, root `RigidBody2D` named `Ball`, script `res://scripts/ball.gd`, in group `"ball"`, radius about 16 px, Camera2D as a child |
| Ball signals | `launched` (once per shot), `came_to_rest` (once per stop) |
| Ball API | `var input_enabled: bool = true`, `func reset_to(pos: Vector2)` |
| GameManager | Autoload `GameManager` (`res://scripts/game_manager.gd`): `stroke_count`, `elapsed_time`, `is_playing`; signals `stroke_count_changed(count)`, `game_won`; functions `start_game()`, `add_stroke()`, `win()` |
| Level | `res://scenes/level/Level.tscn`, root `Node2D` named `Level`, with a direct child `Marker2D` named `SpawnPoint`. Does **not** contain the Ball |
| Goal | `res://scenes/level/Goal.tscn`, an `Area2D` that calls `GameManager.win()` when a body in group `"ball"` enters |
| Main | `res://scenes/Main.tscn` (Person C) puts Level, Ball and HUD together |
| Physics | The ball owns all the bounciness. The level uses default materials |

---

## Person A: Ball and controls

**Owns:** `scenes/ball/`, `scripts/ball.gd`, ball art and sounds.

- [ ] Ball: `RigidBody2D`, circle collider, bouncy `PhysicsMaterial`, Continuous CD on
- [ ] Drag-to-launch (slingshot by default, `invert_direction` toggle). Power from drag length, with a max
- [ ] Only launch when the ball is almost stopped. Right-click or Esc cancels aiming
- [ ] Aim line or arrow showing direction and power
- [ ] Camera2D that follows the ball smoothly
- [ ] `launched` and `came_to_rest` signals, `input_enabled`, `reset_to(pos)`
- [ ] Own test room (`BallTest.tscn`). Tune power, gravity and bounce
- [ ] Tell Person B the max height and distance of a full-power shot

**Done when:** a new player figures out how to shoot within 10 seconds, and bouncing around feels fun.

## Person B: Level and goal

**Owns:** `scenes/level/`, `scripts/goal.gd` and other level scripts, the tileset and level art.

- [ ] Tileset with a physics layer (placeholder art is fine), using a `TileMapLayer`
- [ ] Sketch the climb on paper: 3–4 sections that get harder
- [ ] `Goal.tscn`: cup and flag, calls `GameManager.win()` once
- [ ] `Level.tscn` with `SpawnPoint` at the bottom and the Goal at the top
- [ ] Falls land lower on the course, never out of the world. No spots where the ball gets stuck
- [ ] Push a rough level by **hour 8**
- [ ] Own test scene (`LevelTest.tscn`). Gaps sized against Person A's shot range

**Done when:** the level can be climbed from bottom to top, and falls hurt without being impossible to recover from.

## Person C: Game flow, UI and web build

**Owns:** `project.godot`, `.gitignore`, `scripts/game_manager.gd`, `scripts/main.gd`, `scenes/Main.tscn`, `scenes/ui/`, music and UI sounds.

- [ ] **First hour:** push the `GameManager` autoload (others depend on it)
- [ ] **Hours 0–2:** web export (Thread Support off), upload to itch.io as a draft, and confirm it runs
- [ ] `Main.tscn`: level, ball at `SpawnPoint`, HUD, stroke counting, R to restart
- [ ] HUD: strokes and timer
- [ ] Title screen with Play and how to play. Set as the main scene
- [ ] Win screen: strokes, time, Play Again
- [ ] Re-upload the web build after each big merge

**Done when:** the full flow works in the browser: title, play, reach the hole, win screen, play again.

---

## Sync points

| Hour | Check |
|---|---|
| 2 | Empty web build works on itch.io. Repo works for all 3 people |
| 8 | First merge: the ball bounces around the rough level inside `Main.tscn` |
| 16–20 | **MVP is done:** full loop playable in the browser |
| After MVP | Choose features from the backlog |
| 44 | Final build. Only fixes after this point |

## Backlog (only after the MVP works)

1. Squish visual and sound effects
2. Surface types: jelly, honey, ice, bumpers
3. Checkpoints, then tokens and a bounce-back button
4. Overcharge or squish meter
5. Art pass, music, bouncy castle theme
