extends Node
## GameManager: global game state (levels, strokes, timer, coins, records, win).
## Registered as an autoload named "GameManager", so any script can call
## GameManager.add_stroke(), GameManager.win(), etc. without finding the node.

## Emitted every time the stroke count changes (the HUD listens to this).
signal stroke_count_changed(count: int)
## Emitted every time the coin count changes (the HUD listens to this).
signal coins_changed(count: int)
## Emitted at the start of every run (coins listen to this to reappear).
signal game_started
## Emitted when the ball touches lava (Main sends the ball back to the start).
signal lava_touched
## Emitted once when the player reaches the hole.
signal game_won

## All the levels. "id" is used to save records, so don't change it later.
const LEVELS := [
	{"id": "tower", "name": "1. The Tower", "path": "res://scenes/level/Tower.tscn",
		"blurb": "A tall stone tower. The Big Fall waits near the top."},
	{"id": "caves", "name": "2. Lava Caves", "path": "res://scenes/level/LavaCaves.tscn",
		"blurb": "Touch lava and you're back at the start. Jelly bounces, mud sticks."},
	{"id": "mountain", "name": "3. The Mountain", "path": "res://scenes/level/Mountain.tscn",
		"blurb": "Just a mountain. Ice, jelly and mud all the way up."},
]

const SAVE_PATH := "user://records.cfg"  # in the browser this is saved in the page's storage

## Which level is being played (index into LEVELS). The level select sets it.
var level_index: int = 0
## How many shots the player has taken this run.
var stroke_count: int = 0
## How many coins the player is holding right now.
var coins: int = 0
## Seconds since the run started. Only counts up while is_playing is true.
var elapsed_time: float = 0.0
## True while a run is in progress (false before start and after winning).
var is_playing: bool = false

## Personal records per level id, e.g.
## {"tower": {"height": 140, "strokes": 52, "time": 431.2}}
var records := {}
var _records_dirty := false  # records changed but not saved yet
var _save_timer := 0.0


func _ready() -> void:
	_load_records()


func _process(delta: float) -> void:
	# delta = seconds since the last frame, so adding it up gives a timer.
	if is_playing:
		elapsed_time += delta
	# Save new records at most every 2 seconds (saving every frame is wasteful).
	_save_timer += delta
	if _records_dirty and _save_timer > 2.0:
		_save_records()


func current_level() -> Dictionary:
	return LEVELS[level_index]


## Starts (or restarts) a run: zero the counters and start the timer.
func start_game() -> void:
	stroke_count = 0
	coins = 0
	elapsed_time = 0.0
	is_playing = true
	stroke_count_changed.emit(stroke_count)  # so the HUD shows "Strokes: 0"
	coins_changed.emit(coins)
	game_started.emit()


## Call once per shot (Main connects the ball's "launched" signal to this).
func add_stroke() -> void:
	stroke_count += 1
	stroke_count_changed.emit(stroke_count)


## A coin calls this when the ball touches it.
func add_coin() -> void:
	coins += 1
	coins_changed.emit(coins)


## Spends one coin. Returns false (and spends nothing) if you have none.
func spend_coin() -> bool:
	if coins <= 0:
		return false
	coins -= 1
	coins_changed.emit(coins)
	return true


## Called by the Goal when the ball enters the hole.
## The is_playing check makes sure game_won is only emitted once per run.
func win() -> void:
	if not is_playing:
		return
	is_playing = false
	game_won.emit()


# --- Personal records ----------------------------------------------------------

## Gets one record for a level, or `default` if there isn't one yet.
func get_record(level_id: String, key: String, default = null):
	return records.get(level_id, {}).get(key, default)


## Called all the time while playing. Saves the height if it's a new best.
func update_height(meters: int) -> void:
	var id: String = current_level().id
	if meters > get_record(id, "height", 0):
		_set_record(id, "height", meters)


## Called when you finish a level. Returns a list of what was beaten,
## e.g. ["strokes", "time"], so the win screen can say "New record!".
func record_finish() -> Array:
	var id: String = current_level().id
	var beaten := []
	var best_strokes = get_record(id, "strokes")
	if best_strokes == null or stroke_count < best_strokes:
		_set_record(id, "strokes", stroke_count)
		beaten.append("strokes")
	var best_time = get_record(id, "time")
	if best_time == null or elapsed_time < best_time:
		_set_record(id, "time", elapsed_time)
		beaten.append("time")
	_save_records()
	return beaten


func _set_record(level_id: String, key: String, value) -> void:
	if not records.has(level_id):
		records[level_id] = {}
	records[level_id][key] = value
	_records_dirty = true


func _load_records() -> void:
	var file := ConfigFile.new()
	if file.load(SAVE_PATH) != OK:
		return  # no save yet (first time playing)
	for id in file.get_sections():
		records[id] = {}
		for key in file.get_section_keys(id):
			records[id][key] = file.get_value(id, key)


func _save_records() -> void:
	var file := ConfigFile.new()
	for id in records:
		for key in records[id]:
			file.set_value(id, key, records[id][key])
	file.save(SAVE_PATH)
	_records_dirty = false
	_save_timer = 0.0
