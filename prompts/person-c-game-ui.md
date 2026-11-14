# Prompt for Person C: Game flow, UI and web build

Copy everything below the line into your AI agent, opened in your clone of the repo.

---

You are helping me build my part of a game jam game. I'm a beginner with Godot (I know a little Python/JavaScript), so explain editor steps click by click, keep code simple and commented, and teach me as we go.

== THE GAME ==
Jam theme: "Bounceback". 48-hour jam, web game, team of 3.
"Bounceback Golf": a 2D game that mixes golf with Getting Over It. You control a bouncy ball. Hold left click, drag, release to launch it. Drag direction sets the launch direction and drag length sets the power. The goal is to climb an obstacle course up to a hole at the top. If you fall, you fall, and you climb back up yourself. No checkpoints, tokens or special surfaces in the MVP.

== TECH ==
- Godot 4.7.2 (standard, not .NET), GDScript only. Use Godot 4 syntax and APIs, never Godot 3 (e.g. @export, @onready, signal.connect(callable), change_scene_to_file).
- Renderer: Compatibility (already set). The game ships as a web build on itch.io.
- Repo: https://github.com/Khazap/bounceback-golf (I've cloned it; you're working in it). TEAM.md in the repo has the team plan.
- Default viewport is 1152x648 with stretch mode canvas_items. +Y is down.

== TEAM RULES (important) ==
- 3 people work in parallel. Each person owns specific files. ONLY create or edit files I own (listed below). Editing someone else's .tscn causes merge conflicts we can't fix during a jam.
- I (Person C) own project.godot and .gitignore. Keep project.godot changes minimal and push them quickly, because everyone's editor reads that file.
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
- signal came_to_rest        (emitted once when the ball stops)
- var input_enabled: bool = true      (I set it false when the game is won)
- func reset_to(pos: Vector2) -> void (teleports the ball, zero velocity)
- The Camera2D is a child of the Ball.

GameManager (owned by me, Person C): autoload named "GameManager", res://scripts/game_manager.gd
- var stroke_count: int, var elapsed_time: float, var is_playing: bool
- signal stroke_count_changed(count: int), signal game_won
- func start_game()   resets stroke_count and elapsed_time, sets is_playing = true
- func add_stroke()   increments stroke_count, emits stroke_count_changed
- func win()          if is_playing: sets is_playing = false, emits game_won (only once)
- elapsed_time counts up in _process while is_playing

Level (owned by Person B): res://scenes/level/Level.tscn, root Node2D named "Level"
- Contains a Marker2D named "SpawnPoint" (direct child) where the ball starts
- Contains the Goal, which calls GameManager.win() when the ball enters
- The level does NOT contain the Ball.

Main (owned by me): res://scenes/Main.tscn puts Level + Ball + HUD together.

== MY ROLE: PERSON C, GAME FLOW, UI AND WEB BUILD ==
I own: project.godot, .gitignore, scripts/game_manager.gd, scripts/main.gd, scenes/Main.tscn, scenes/ui/ (Title, HUD, WinScreen), other UI scripts, music and UI sounds.

Tasks (in order):
1. FIRST HOUR, because others depend on it: create scripts/game_manager.gd exactly matching the contract, register it as an autoload named "GameManager" in Project Settings, and push right away so Person B can call GameManager.win().
2. Web export pipeline (hours 0-2, before anything fancy):
   - Install export templates for 4.7.2 (Editor > Manage Export Templates > Download and Install).
   - Project > Export > Add > Web. Turn OFF Thread Support so it runs on itch.io without special headers.
   - Export to build/web/index.html. Add build/ to .gitignore.
   - Zip the contents of build/web and upload to itch.io as an HTML project ("This file will be played in the browser"). Set the embed size to 1152x648, keep the page as a Draft, and leave SharedArrayBuffer support off.
   - Confirm a placeholder scene runs in the browser. Walk me through each step.
3. Main.tscn (root Node2D "Main", script scripts/main.gd):
   - Instances Level.tscn and Ball.tscn, plus the HUD.
   - On _ready: put the ball at $Level/SpawnPoint (use reset_to), call GameManager.start_game(), connect ball.launched to GameManager.add_stroke, connect GameManager.game_won to show the win screen and set ball.input_enabled = false.
   - Press R to restart: ball.reset_to(spawn), GameManager.start_game(), hide the win screen, input_enabled = true. Handle the R key in code (_unhandled_input), or add a "restart" Input Map action, since I own project.godot.
   - Until Person A pushes Ball.tscn and Person B pushes Level.tscn (about hour 8), build Main with temporary placeholder nodes so I can work. Never create files at their paths. Swap in the real scenes when they arrive.
4. HUD (scenes/ui/HUD.tscn, a CanvasLayer): shows "Strokes: N" (updates from stroke_count_changed) and a timer from GameManager.elapsed_time formatted as m:ss. Also a small "R = restart" hint.
5. Title screen (scenes/ui/Title.tscn): game name, a Play button that loads Main.tscn, and one line of how to play ("Click and drag to aim, release to launch. Reach the hole at the top!"). Set Title.tscn as the project's main scene.
6. Win screen (scenes/ui/WinScreen.tscn, an overlay inside Main): "You made it!", strokes, time, a Play Again button (same as restart) and a Title button.
7. Re-export and re-upload the web build every time the team merges something big. Tell me if anything works in the editor but not in the browser.

Done when: the full flow works IN THE BROWSER on itch.io: title, play, launch (strokes count up), reach the hole, win screen, play again.

After the MVP (only if the team agrees): pause menu, music and an audio manager, connecting Person A's sound hooks, screen transitions, and later checkpoints with tokens and a "Bounce Back" button.

Start by checking the repo contents and that Godot 4.7.2 is what I'm using, then give me a short plan and begin with task 1.
