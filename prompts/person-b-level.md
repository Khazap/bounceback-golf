# Prompt for Person B: Level and goal

Copy everything below the line into your AI agent, opened in your clone of the repo.

---

You are helping me build my part of a game jam game. I'm a beginner with Godot (I know a little Python/JavaScript), so explain editor steps click by click, keep code simple and commented, and teach me as we go.

== THE GAME ==
Jam theme: "Bounceback". 48-hour jam, web game, team of 3.
"Bounceback Golf": a 2D game that mixes golf with Getting Over It. You control a bouncy ball. Hold left click, drag, release to launch it. Drag direction sets the launch direction and drag length sets the power. The goal is to climb an obstacle course up to a hole at the top. If you fall, you fall, and you climb back up yourself. No checkpoints, tokens or special surfaces in the MVP.

== TECH ==
- Godot 4.7.2 (standard, not .NET), GDScript only. Use Godot 4 syntax and APIs, never Godot 3 (e.g. @export, @onready, signal.connect(callable), TileMapLayer, not TileMap).
- Renderer: Compatibility (already set). The game ships as a web build on itch.io.
- Repo: https://github.com/Khazap/bounceback-golf (I've cloned it; you're working in it). TEAM.md in the repo has the team plan.
- Default viewport is 1152x648 with stretch mode canvas_items. +Y is down, so climbing means negative Y.

== TEAM RULES (important) ==
- 3 people work in parallel. Each person owns specific files. ONLY create or edit files I own (listed below). Editing someone else's .tscn causes merge conflicts we can't fix during a jam.
- Never edit project.godot or .gitignore (Person C owns those). If Godot's editor changes project.godot by itself, discard that change with: git checkout -- project.godot. If I need a project setting changed, tell me what to ask Person C.
- Never commit the .godot/ folder (already gitignored).
- Commit the .uid and .import files Godot creates next to my own scripts and assets.
- Git workflow: commit small and often. Before pushing: git pull --rebase, then git push. If there's a conflict in a file I don't own, stop and tell me.
- You may write .tscn files as text if you're confident they're valid Godot 4 format. Otherwise, give me click-by-click editor steps. After any scene change, have me open it in Godot and press play to check.

== SHARED CONTRACTS (all 3 people build against these; do not change them) ==
Folders: scenes/ball/, scenes/level/, scenes/ui/, scripts/, art/, audio/

Ball (owned by Person A):
- Scene res://scenes/ball/Ball.tscn. Root node is a RigidBody2D named "Ball", script res://scripts/ball.gd
- Root is in group "ball"
- signal launched, signal came_to_rest
- var input_enabled: bool, func reset_to(pos: Vector2)
- Ball radius is about 16 px. The ball owns all the bounciness (its own PhysicsMaterial). The Camera2D is a child of the Ball.

GameManager (owned by Person C): autoload named "GameManager", res://scripts/game_manager.gd
- var stroke_count: int, var elapsed_time: float, var is_playing: bool
- signal stroke_count_changed(count: int), signal game_won
- func start_game(), func add_stroke(), func win()

Level (owned by Person B): res://scenes/level/Level.tscn, root Node2D named "Level"
- Contains a Marker2D named "SpawnPoint" (direct child) where the ball starts
- Contains the Goal (res://scenes/level/Goal.tscn): an Area2D that calls GameManager.win() when a body in group "ball" enters
- The level does NOT contain the Ball. Main.tscn adds it.

Main (owned by Person C): res://scenes/Main.tscn puts Level + Ball + HUD together and handles restart/win.

== MY ROLE: PERSON B, LEVEL AND GOAL ==
I own: scenes/level/ (Level.tscn, Goal.tscn, LevelTest.tscn, anything else in there), scripts/goal.gd and any other level scripts, and the tileset/level art I add to art/.

Tasks (in order):
1. Tileset: set up a simple tileset with a physics layer so tiles are solid. Placeholder colored squares are fine. A free CC0 pack (e.g. from kenney.nl) is also fine; tell me what to download, and I'll put it in art/. Use a TileMapLayer for the level geometry. Plain StaticBody2D shapes are fine for odd angles and slopes.
2. Help me plan the level on paper first: a climb from bottom to top in 3-4 sections that get harder (wide ledges first, then smaller ledges, walls to bank shots off, overhangs, angled surfaces). Keep it around 1-2 screens wide and roughly 6-10 screens tall. Use default physics materials on the level. Don't add bounce to the level, because the ball handles that.
3. Goal.tscn: an Area2D root with script scripts/goal.gd. Give it a cup/hole visual and a flag. On body_entered, if the body is in group "ball", call GameManager.win() once (guard against double calls). Shape the cup so the ball drops into it, and put the detection area at the bottom of the cup.
   If the GameManager autoload doesn't exist yet when you test (Person C is pushing it in the first hours), look it up with get_node_or_null("/root/GameManager") so it doesn't crash, and print("GOAL!") as a fallback.
4. Level.tscn: root Node2D named "Level", with a Marker2D named "SpawnPoint" at the bottom, the geometry, and the Goal instanced at the top.
   - Falls should drop the ball back onto lower parts of the course, never out of the world. Enclose the sides and the bottom with walls.
   - No unreachable or "softlock" spots where the ball gets stuck and can't be launched out.
5. Get a rough but climbable Level.tscn pushed by about hour 8 so Person C can put it into Main.tscn. Keep improving it after that.
6. LevelTest.tscn (my own test scene): instance Level.tscn plus a Camera2D. Once Person A pushes Ball.tscn, instance the Ball at SpawnPoint and play through the level. Before that, use a temporary RigidBody2D circle (radius 16) in group "ball" to test the goal.
7. Shot range: Person A will tell me the max height and distance of a full-power shot. Make ledge gaps a mix of easy (about 50% of max), medium (about 75%) and hard (about 90%). Never require 100%.

Done when: the level can be climbed from bottom to top, falls hurt without being impossible to recover from, reaching the hole calls GameManager.win(), and Level.tscn follows the contract exactly.

After the MVP (only if the team agrees): special surfaces (jelly: extra bounce, honey: no bounce, ice: no friction, bumpers), checkpoints, a bouncy castle art pass, background, moving platforms.

Start by checking the repo contents and that Godot 4.7.2 is what I'm using, then give me a short plan and begin with task 1.
