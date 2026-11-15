extends Node
## GameManager: global game state (strokes, timer, coins, win).
## Registered as an autoload named "GameManager", so any script can call
## GameManager.add_stroke(), GameManager.win(), etc. without finding the node.

## Emitted every time the stroke count changes (the HUD listens to this).
signal stroke_count_changed(count: int)
## Emitted every time the coin count changes (the HUD listens to this).
signal coins_changed(count: int)
## Emitted at the start of every run (coins listen to this to reappear).
signal game_started
## Emitted once when the player reaches the hole.
signal game_won

## How many shots the player has taken this run.
var stroke_count: int = 0
## How many coins the player is holding right now.
var coins: int = 0
## Seconds since the run started. Only counts up while is_playing is true.
var elapsed_time: float = 0.0
## True while a run is in progress (false before start and after winning).
var is_playing: bool = false


func _process(delta: float) -> void:
	# delta = seconds since the last frame, so adding it up gives a timer.
	if is_playing:
		elapsed_time += delta


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
