extends Node2D
## Main: loads the chosen level, adds the Ball and the HUD, and runs one round.
## - Puts the ball on the level's SpawnPoint and starts the game.
## - Every time the ball is launched, adds a stroke.
## - Bounce Back: spend 1 coin to go back to where you took your last shot.
## - Lava: back to the start (your Bounce Back history is kept, so a coin can save you).
## - Tracks how high you've climbed, and saves your best height.
## - When the game is won, stops the ball and saves strokes/time records.
## - Press R at any time to restart.

const METERS_PER_TILE := 1.0  # 1 tile (32 pixels) = 1 meter of height

# @onready means "fill this in once the scene is ready", when the child
# nodes exist. $Name is a shortcut for get_node("Name").
@onready var ball: RigidBody2D = $Ball
@onready var hud: CanvasLayer = $HUD
@onready var win_screen: CanvasLayer = $WinScreen

var level: Node2D          # the level scene we loaded (Tower, Lava Caves or Mountain)
var spawn_point: Marker2D  # where the ball starts

## Where the ball was each time you took a shot, oldest first.
## Bounce Back takes the last one off the end (so pressing it again goes
## back one more shot, as long as you have coins).
var shot_positions: Array[Vector2] = []
var run_best_height := 0  # highest point this run, in meters


func _ready() -> void:
	# Load the level the player picked in the menu and put it first, so it's
	# drawn behind the ball.
	level = load(GameManager.current_level().path).instantiate()
	add_child(level)
	move_child(level, 0)
	spawn_point = level.get_node("SpawnPoint")
	# Move the ball there right now, before physics runs, so it never starts
	# inside a wall (each level's start is somewhere else).
	ball.global_position = spawn_point.global_position

	# Signal connections: "when X happens, call Y".
	ball.launched.connect(GameManager.add_stroke)   # count a stroke...
	ball.launched.connect(_on_ball_launched)        # ...and remember where we shot from
	GameManager.game_won.connect(_on_game_won)
	GameManager.lava_touched.connect(_on_lava_touched)
	win_screen.play_again_pressed.connect(restart)  # same as pressing R
	hud.bounce_back_pressed.connect(bounce_back)    # the HUD button (B key is below)
	GameManager.coins_changed.connect(_update_bounce_back_button.unbind(1))
	restart()


## Puts everything back to the start of a run.
func restart() -> void:
	ball.reset_to(spawn_point.global_position)
	ball.input_enabled = true
	shot_positions.clear()
	run_best_height = 0
	GameManager.start_game()
	win_screen.hide()
	_update_bounce_back_button()


func _process(_delta: float) -> void:
	# Height = how far above the start the ball is. Up is negative Y, so it's
	# spawn.y minus ball.y.
	var height := int(maxf(0.0, spawn_point.global_position.y - ball.global_position.y) / 32.0 * METERS_PER_TILE)
	if height > run_best_height:
		run_best_height = height
		GameManager.update_height(height)
	hud.set_height(height, GameManager.get_record(GameManager.current_level().id, "height", 0))


func _on_ball_launched() -> void:
	# The ball is still where it was standing when "launched" fires.
	shot_positions.append(ball.global_position)
	_update_bounce_back_button()


## Spend 1 coin: the ball jumps back to where it took its last shot.
## Works even while the ball is flying or falling. Doesn't count as a stroke.
func bounce_back() -> void:
	if not _can_bounce_back():
		return
	GameManager.spend_coin()
	ball.reset_to(shot_positions.pop_back())
	AudioManager.play("bounceback")
	_update_bounce_back_button()


func _can_bounce_back() -> bool:
	return GameManager.is_playing and GameManager.coins > 0 and not shot_positions.is_empty()


func _update_bounce_back_button() -> void:
	hud.set_bounce_back_enabled(_can_bounce_back())


func _on_lava_touched() -> void:
	if not GameManager.is_playing:
		return
	AudioManager.play("lava")
	ball.reset_to(spawn_point.global_position)


func _on_game_won() -> void:
	ball.input_enabled = false  # no more shots after winning
	_update_bounce_back_button()
	var beaten := GameManager.record_finish()
	win_screen.show_results(GameManager.stroke_count, GameManager.elapsed_time, beaten)


# _unhandled_input gets key and mouse events that no UI element used.
func _unhandled_input(event: InputEvent) -> void:
	# "pressed" = key went down. "not echo" = ignore the auto-repeat you get
	# from holding the key down, so holding R only restarts once.
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_R:
			restart()
		elif event.keycode == KEY_B:
			bounce_back()
