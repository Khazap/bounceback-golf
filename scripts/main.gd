extends Node2D
## Main: puts the Level, the Ball and the HUD together and runs one round.
## - Puts the ball on the level's SpawnPoint and starts the game.
## - Every time the ball is launched, adds a stroke.
## - When the game is won, stops the ball from being shot.
## - Press R at any time to restart.

# @onready means "fill this in once the scene is ready", when the child
# nodes exist. $Name is a shortcut for get_node("Name").
@onready var ball: RigidBody2D = $Ball
@onready var spawn_point: Marker2D = $Level/SpawnPoint


func _ready() -> void:
	# Signal connections: "when X happens, call Y".
	# Each time the ball is launched, GameManager counts a stroke.
	ball.launched.connect(GameManager.add_stroke)
	# When GameManager says the game is won, run our _on_game_won function.
	GameManager.game_won.connect(_on_game_won)
	restart()


## Puts everything back to the start of a run.
func restart() -> void:
	ball.reset_to(spawn_point.global_position)
	ball.input_enabled = true
	GameManager.start_game()
	# TODO (task 6): hide the win screen here.


func _on_game_won() -> void:
	ball.input_enabled = false  # no more shots after winning
	# TODO (task 6): show the win screen here instead of printing.
	print("You won! Strokes: ", GameManager.stroke_count)


# _unhandled_input gets key and mouse events that no UI element used.
func _unhandled_input(event: InputEvent) -> void:
	# "pressed" = key went down. "not echo" = ignore the auto-repeat you get
	# from holding the key down, so holding R only restarts once.
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_R:
			restart()
