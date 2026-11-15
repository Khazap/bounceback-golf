extends Area2D
## A coin. Touch it with the ball to collect it (+1 coin).
## It's drawn with code (a gold circle), so it needs no image file.
## Collected coins come back when a new run starts (R, Play Again, Play).

const RADIUS := 11.0

var time := randf() * 10.0  # random start, so coins don't all spin in sync


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	GameManager.game_started.connect(_respawn)


func _process(delta: float) -> void:
	time += delta
	queue_redraw()


func _draw() -> void:
	# Fake a spinning coin: squash it sideways with a cosine (1 -> 0.15 -> 1).
	var spin := maxf(absf(cos(time * 3.0)), 0.15)
	var bob := sin(time * 2.0) * 3.0  # float up and down a little
	draw_set_transform(Vector2(0, bob), 0.0, Vector2(spin, 1.0))
	draw_circle(Vector2.ZERO, RADIUS, Color("#b8860b"))          # dark gold rim
	draw_circle(Vector2.ZERO, RADIUS - 3.0, Color("#ffd23f"))    # gold face
	draw_circle(Vector2(-3, -3), 2.5, Color(1, 1, 1, 0.8))       # shine


func _on_body_entered(body: Node) -> void:
	if body.is_in_group("ball") and visible:
		# Bank first (pays into the shop wallet the first time ever), then
		# add to this run's coins (for Bounce Back). The HUD shows both.
		GameManager.bank_coin(name)
		GameManager.add_coin()
		AudioManager.play("coin")
		hide()
		# Turn off detection. "set_deferred" waits until the physics step is
		# over, because Godot doesn't allow changing it in the middle of one.
		set_deferred("monitoring", false)


func _respawn() -> void:
	show()
	# Wait 2 physics steps before the coin can be collected again. On restart
	# the ball needs one step to jump back to the start; without this wait, a
	# ball sitting on this coin's spot would grab it again right away.
	await get_tree().physics_frame
	await get_tree().physics_frame
	monitoring = true
