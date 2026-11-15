extends Control
## Main menu: game name, a bobbing dog, and the menu buttons.
## How to Play and Credits share one pop-up panel ("InfoOverlay").

const HOW_TO_TEXT := """• Wait for the gold ring around the dog (and the "ding"). That means you can aim.
• Click anywhere, drag AWAY from where you want to go, and let go. Longer drag = more power.
• Every shot bounces at least twice. Landings are never safe.
• Right-click or Esc cancels a shot.
• The hole is at the very top. You won't see it until you're close.
• Grab coins. Bounce Back (button or B) spends 1 coin to put you back where you took your last shot, even mid-fall.
• Each coin also pays into your Wallet the first time you ever grab it (+10 for finishing a level). Spend it on skins in the Shop.
• Surfaces: ice (light blue) slides, jelly (pink) flings you up, mud (brown) sticks. Lava sends you back to the start.

R = restart    B = Bounce Back    M = music on/off"""

# TODO: put your names in, and the dog artist's name once you know it.
const CREDITS_TEXT := """Bounceback Golf 2, made for the Hack Club Haven game jam.

Game, level and code: our team
Dog face: "xiaohongdog" sticker (artist credit to add)
Grass, dirt and stone tiles: (add who made them / where they're from)
Music and sound effects: generated in code (scripts/sound_maker.gd)

Made with Godot 4.7"""

@onready var dog: TextureRect = %Dog
@onready var play_button: Button = %PlayButton
@onready var music_button: Button = %MusicButton
@onready var sound_button: Button = %SoundButton
@onready var quit_button: Button = %QuitButton
@onready var info_overlay: ColorRect = %InfoOverlay


func _ready() -> void:
	GameManager.is_playing = false  # stop the game timer while in the menu

	dog.texture = GameManager.equipped_skin_texture()  # show the skin you're wearing
	play_button.pressed.connect(_on_play_pressed)
	%ShopButton.pressed.connect(_on_shop_pressed)
	%HowToButton.pressed.connect(_show_info.bind("How to Play", HOW_TO_TEXT))
	%CreditsButton.pressed.connect(_show_info.bind("Credits", CREDITS_TEXT))
	%CloseButton.pressed.connect(_close_info)
	music_button.pressed.connect(_on_music_pressed)
	sound_button.pressed.connect(_on_sound_pressed)
	quit_button.pressed.connect(get_tree().quit)
	# Every button makes a click sound.
	for button in find_children("*", "Button"):
		button.pressed.connect(AudioManager.play.bind("click"))

	# A web page can't be "quit", so hide that button in the browser.
	quit_button.visible = not OS.has_feature("web")
	_update_toggle_labels()
	play_button.grab_focus()  # Enter / Space presses Play

	# Make the dog bob up and down forever.
	var bob := create_tween().set_loops()
	bob.tween_property(dog, "position:y", dog.position.y - 16, 0.8).set_trans(Tween.TRANS_SINE)
	bob.tween_property(dog, "position:y", dog.position.y, 0.8).set_trans(Tween.TRANS_SINE)


## Play opens the level list: one big button per level, with your records.
func _on_play_pressed() -> void:
	var list: VBoxContainer = %LevelList
	for old in list.get_children():
		old.queue_free()  # rebuild fresh each time, so records are up to date
	for i in GameManager.LEVELS.size():
		var info: Dictionary = GameManager.LEVELS[i]
		var button := Button.new()
		button.custom_minimum_size = Vector2(0, 70)
		button.add_theme_font_size_override("font_size", 20)
		button.text = "%s\n%s" % [info.name, _records_text(info.id)]
		button.tooltip_text = info.blurb
		button.pressed.connect(_start_level.bind(i))
		button.pressed.connect(AudioManager.play.bind("click"))
		list.add_child(button)
	_show_panel("Choose a level", "levels")
	list.get_child(0).grab_focus()


func _records_text(id: String) -> String:
	var height = GameManager.get_record(id, "height", 0)
	var strokes = GameManager.get_record(id, "strokes")
	if strokes == null:
		return "Best height: %d m · not finished yet" % height
	var time: float = GameManager.get_record(id, "time")
	return "Best height: %d m · %d strokes · %d:%02d" % [height, strokes, int(time / 60.0), int(time) % 60]


# --- Shop (skins only) ---------------------------------------------------------

## The shop: one row per skin, with a picture, name, price and a button.
func _on_shop_pressed() -> void:
	var list: VBoxContainer = %ShopList
	for old in list.get_children():
		old.queue_free()
	for skin in GameManager.SKINS:
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 16)

		var picture := TextureRect.new()
		picture.texture = load(skin.path)
		picture.custom_minimum_size = Vector2(52, 52)
		picture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		picture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		row.add_child(picture)

		var label := Label.new()
		label.text = skin.name
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		label.add_theme_font_size_override("font_size", 22)
		row.add_child(label)

		var button := Button.new()
		button.custom_minimum_size = Vector2(170, 46)
		button.add_theme_font_size_override("font_size", 20)
		if skin.id == GameManager.equipped_skin:
			button.text = "Wearing"
			button.disabled = true
		elif skin.id in GameManager.owned_skins:
			button.text = "Wear"
		else:
			button.text = "Buy: %d coins" % skin.price
			button.disabled = GameManager.wallet < skin.price
		button.pressed.connect(_on_skin_button.bind(skin.id))
		button.pressed.connect(AudioManager.play.bind("click"))
		row.add_child(button)
		list.add_child(row)
	_show_panel("Shop · Wallet: %d coins" % GameManager.wallet, "shop")


func _on_skin_button(id: String) -> void:
	if id in GameManager.owned_skins:
		GameManager.equip_skin(id)
	elif GameManager.buy_skin(id):
		AudioManager.play("coin")
	dog.texture = GameManager.equipped_skin_texture()
	_on_shop_pressed()  # redraw the list with the new buttons/wallet


func _start_level(index: int) -> void:
	GameManager.level_index = index
	get_tree().change_scene_to_file("res://scenes/Main.tscn")


func _on_music_pressed() -> void:
	AudioManager.set_music_on(not AudioManager.music_on)
	_update_toggle_labels()


func _on_sound_pressed() -> void:
	AudioManager.set_sound_on(not AudioManager.sound_on)
	_update_toggle_labels()


func _update_toggle_labels() -> void:
	music_button.text = "Music: " + ("On" if AudioManager.music_on else "Off")
	sound_button.text = "Sound: " + ("On" if AudioManager.sound_on else "Off")


func _show_info(title: String, text: String) -> void:
	%InfoText.text = text
	_show_panel(title, "text")
	%CloseButton.grab_focus()


## Shows the pop-up with one of: "levels" (level list), "shop" or "text".
func _show_panel(title: String, mode: String) -> void:
	%InfoTitle.text = title
	%LevelList.visible = mode == "levels"
	%ShopList.visible = mode == "shop"
	%InfoText.visible = mode == "text"
	%CloseButton.text = "Close" if mode == "text" else "Back"
	info_overlay.show()


func _close_info() -> void:
	info_overlay.hide()
	play_button.grab_focus()


func _unhandled_input(event: InputEvent) -> void:
	# Esc closes the pop-up.
	if info_overlay.visible and event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		_close_info()
