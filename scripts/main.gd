extends Node2D
## Main: puts the Level, the Ball and the HUD together and runs one round.
## - Puts the ball on the level's SpawnPoint and starts the game.
## - Every time the ball is launched, adds a stroke.
## - Bounce Back: spend 1 coin to go back to where you took your last shot.
## - When the game is won, stops the ball from being shot.
## - Press R at any time to restart.

# @onready means "fill this in once the scene is ready", when the child
# nodes exist. $Name is a shortcut for get_node("Name").
@onready var ball: RigidBody2D = $Ball
@onready var spawn_point: Marker2D = $Level/SpawnPoint
@onready var hud: CanvasLayer = $HUD
@onready var win_screen: CanvasLayer = $WinScreen

## Where the ball was each time you took a shot, oldest first.
## Bounce Back takes the last one off the end (so pressing it again goes
## back one more shot, as long as you have coins).
var shot_positions: Array[Vector2] = []


func _ready() -> void:
	# Signal connections: "when X happens, call Y".
	# Each time the ball is launched, GameManager counts a stroke...
	ball.launched.connect(GameManager.add_stroke)
	# ...and we remember where the shot was taken from.
	ball.launched.connect(_on_ball_launched)
	# When GameManager says the game is won, run our _on_game_won function.
	GameManager.game_won.connect(_on_game_won)
	# The win screen's Play Again button does the same thing as pressing R.
	win_screen.play_again_pressed.connect(restart)
	# The HUD's Bounce Back button (and the B key, below) call bounce_back.
	hud.bounce_back_pressed.connect(bounce_back)
	GameManager.coins_changed.connect(_update_bounce_back_button.unbind(1))
	restart()


## Puts everything back to the start of a run.
func restart() -> void:
	ball.reset_to(spawn_point.global_position)
	ball.input_enabled = true
	shot_positions.clear()
	GameManager.start_game()
	win_screen.hide()
	_update_bounce_back_button()


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


func _on_game_won() -> void:
	ball.input_enabled = false  # no more shots after winning
	_update_bounce_back_button()
	win_screen.show_results(GameManager.stroke_count, GameManager.elapsed_time)


# _unhandled_input gets key and mouse events that no UI element used.
func _unhandled_input(event: InputEvent) -> void:
	# "pressed" = key went down. "not echo" = ignore the auto-repeat you get
	# from holding the key down, so holding R only restarts once.
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_R:
			restart()
		elif event.keycode == KEY_B:
			bounce_back()
