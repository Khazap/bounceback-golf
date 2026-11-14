# Prompt for Person A: Ball and controls

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
- signal launched            (emitted once per shot)
- signal came_to_rest        (emitted once when the ball stops after moving)
- var input_enabled: bool = true      (Person C sets false on the win screen)
- func reset_to(pos: Vector2) -> void (teleports the ball to pos, zero velocity)
- Ball radius is about 16 px. The Camera2D is a child of the Ball.

GameManager (owned by Person C): autoload named "GameManager", res://scripts/game_manager.gd
- var stroke_count: int, var elapsed_time: float, var is_playing: bool
- signal stroke_count_changed(count: int), signal game_won
- func start_game(), func add_stroke(), func win()

Level (owned by Person B): res://scenes/level/Level.tscn, root Node2D named "Level"
- Contains a Marker2D named "SpawnPoint" (direct child) where the ball starts
- Contains the Goal (res://scenes/level/Goal.tscn): an Area2D that calls GameManager.win() when a body in group "ball" enters
- The level does NOT contain the Ball. Main.tscn adds it.

Main (owned by Person C): res://scenes/Main.tscn puts Level + Ball + HUD together, connects Ball.launched to GameManager.add_stroke, and handles restart/win.

== MY ROLE: PERSON A, BALL AND CONTROLS ==
I own: scenes/ball/ (Ball.tscn, BallTest.tscn, anything else in there), scripts/ball.gd, and ball art/sounds I add to art/ and audio/.

Tasks (in order):
1. Ball.tscn: RigidBody2D root, CircleShape2D collider (radius 16, @export so we can tweak), simple visual (draw a circle in _draw() or use a Sprite2D). PhysicsMaterial on the ball with bounce around 0.6 (exported/tweakable). Enable continuous collision detection (continuous_cd = CCD_MODE_CAST_SHAPE) so fast shots don't pass through walls. The ball owns all the bounciness, and the level uses default materials.
2. Drag-to-launch (slingshot style):
   - Press left mouse button anywhere to start aiming (you don't have to click on the ball). Drag. Release to launch with apply_central_impulse.
   - By default the ball flies OPPOSITE the drag direction, like pulling back a slingshot. Add @export var invert_direction := false so the team can flip it if playtesters prefer.
   - Power = drag length * multiplier, clamped to a max. Export min drag (deadzone), max drag, power multiplier.
   - Right-click or Esc while aiming cancels the shot.
   - Only allow aiming/launching when the ball is at rest and input_enabled is true.
   - Handle mouse input directly in code (_unhandled_input with InputEventMouseButton/InputEventMouseMotion), not through the Input Map, so we don't touch project.godot.
3. Rest detection: the ball counts as "at rest" when linear_velocity.length() stays below a small threshold for about 0.3 s. Emit came_to_rest once per stop. Emit launched once per shot.
4. Aim indicator: while aiming, draw a dotted line or arrow from the ball in the launch direction. Its length shows power, and its color goes from green (weak) to red (max). Hide it when not aiming.
5. Camera2D as a child of Ball, with position smoothing enabled. Make it the current camera.
6. reset_to(pos): teleporting a RigidBody2D safely needs care. Set a flag and apply the new transform and zero velocities inside _integrate_forces(state). Reset aiming state too.
7. BallTest.tscn (my own throwaway test room): a few StaticBody2D walls, floors and ledges at different heights, with the Ball instanced in it. Use it to tune power, gravity_scale, bounce and damping until shots feel good and controllable.
8. Measure and tell me the maximum height and distance of a full-power shot, so I can tell Person B (who designs the level).

Done when: someone who has never played figures out how to shoot within 10 seconds, bouncing around feels fun, and Ball.tscn follows the contract exactly.

After the MVP (only if the team agrees): squish effect while charging and stretch on launch, impact squash, boing sound with pitch based on bounce strength (add signal bounced(strength: float)), a trail when moving fast.

Start by checking the repo contents and that Godot 4.7.2 is what I'm using, then give me a short plan and begin with task 1.
