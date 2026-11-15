extends CanvasLayer
## Win screen: an overlay shown on top of Main when the ball reaches the hole.
## It starts hidden. Main calls show_results() when the game is won.

## Main listens to this and restarts the run (same as pressing R).
signal play_again_pressed

# preload loads hud.gd so we can reuse its format_time() helper.
const HUD = preload("res://scripts/hud.gd")

@onready var strokes_label: Label = %StrokesLabel
@onready var time_label: Label = %TimeLabel
@onready var play_again_button: Button = %PlayAgainButton
@onready var title_button: Button = %TitleButton


func _ready() -> void:
	hide()
	# Pressing Play Again just passes the message on to Main.
	play_again_button.pressed.connect(play_again_pressed.emit)
	title_button.pressed.connect(_on_title_pressed)
	# Both buttons make a click sound.
	play_again_button.pressed.connect(AudioManager.play.bind("click"))
	title_button.pressed.connect(AudioManager.play.bind("click"))


## Fills in the numbers and shows the overlay.
## `beaten` lists the records you just broke, e.g. ["strokes", "time"].
func show_results(strokes: int, time_seconds: float, beaten: Array = []) -> void:
	var id: String = GameManager.current_level().id
	strokes_label.text = "Strokes: %d" % strokes
	time_label.text = "Time: " + HUD.format_time(time_seconds)
	# Second line: the best ever (which may be what you just did).
	var best_line := "Best: %d strokes · %s" % [GameManager.get_record(id, "strokes", strokes),
		HUD.format_time(GameManager.get_record(id, "time", time_seconds))]
	if beaten.is_empty():
		%RecordLabel.text = best_line
	else:
		%RecordLabel.text = "NEW RECORD! (" + " + ".join(beaten) + ")\n" + best_line
	if GameManager.last_bonus > 0:
		%RecordLabel.text += "\nFirst clear! +%d coins for the shop" % GameManager.last_bonus
	show()
	play_again_button.grab_focus()  # so Enter works too


func _on_title_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/ui/Title.tscn")
