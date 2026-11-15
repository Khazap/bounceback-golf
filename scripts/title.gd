extends Control
## Title screen: game name, how to play, and a Play button.

@onready var play_button: Button = %PlayButton  # % = "unique name", found anywhere in the scene


func _ready() -> void:
	play_button.pressed.connect(_on_play_pressed)
	# Give the button keyboard focus, so Enter or Space also presses it.
	play_button.grab_focus()


func _on_play_pressed() -> void:
	AudioManager.play("click")
	# Swap the whole current scene (this title screen) for the game scene.
	get_tree().change_scene_to_file("res://scenes/Main.tscn")
