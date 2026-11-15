extends CanvasLayer
## HUD: the text that stays on screen while you play.
## A CanvasLayer draws on top of the game and ignores the camera, so the
## labels stay in the corners even when the camera follows the ball.

## Main listens to this and does the actual Bounce Back.
signal bounce_back_pressed

@onready var strokes_label: Label = $StrokesLabel
@onready var coins_label: Label = $CoinsLabel
@onready var bounce_back_button: Button = $BounceBackButton
@onready var time_label: Label = $TimeLabel


func _ready() -> void:
	# Update the texts whenever GameManager says a number changed.
	GameManager.stroke_count_changed.connect(_on_stroke_count_changed)
	GameManager.coins_changed.connect(_on_coins_changed)
	_on_stroke_count_changed(GameManager.stroke_count)  # show the current values now
	_on_coins_changed(GameManager.coins)
	# The buttons' focus_mode is "none", so Space/Enter can't press them by accident.
	$MenuButton.pressed.connect(_on_menu_pressed)
	bounce_back_button.pressed.connect(bounce_back_pressed.emit)


## Main calls this to grey out the button when Bounce Back isn't possible
## (no coins, or no earlier shot to go back to).
func set_bounce_back_enabled(enabled: bool) -> void:
	bounce_back_button.disabled = not enabled


func _on_coins_changed(count: int) -> void:
	coins_label.text = "Coins: %d" % count


func _on_menu_pressed() -> void:
	AudioManager.play("click")
	get_tree().change_scene_to_file("res://scenes/ui/Title.tscn")


func _on_stroke_count_changed(count: int) -> void:
	strokes_label.text = "Strokes: %d" % count


func _process(_delta: float) -> void:
	# The timer changes every frame, so we just redraw it every frame.
	time_label.text = format_time(GameManager.elapsed_time)


## Turns seconds into "m:ss", e.g. 75.4 -> "1:15".
## "static" means it doesn't need a HUD node to run (the win screen reuses it).
static func format_time(seconds: float) -> String:
	var minutes := int(seconds / 60.0)
	var secs := int(seconds) % 60
	return "%d:%02d" % [minutes, secs]  # %02d = at least 2 digits, pad with 0
