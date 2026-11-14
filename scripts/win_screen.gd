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


## Fills in the numbers and shows the overlay.
func show_results(strokes: int, time_seconds: float) -> void:
	strokes_label.text = "Strokes: %d" % strokes
	time_label.text = "Time: " + HUD.format_time(time_seconds)
	show()
	play_again_button.grab_focus()  # so Enter works too


func _on_title_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/ui/Title.tscn")
