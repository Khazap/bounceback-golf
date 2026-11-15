extends Area2D
## Lava: touch it and the ball goes back to the start of the level.
## (Main does the actual teleport when GameManager.lava_touched fires.)
## The level builder sets `size`; the lava draws itself, no image needed.

@export var size := Vector2(64, 32)  # width and height in pixels, from the top-left corner

var time := 0.0


func _ready() -> void:
	# Make the touch area the same size as the drawing.
	var shape := RectangleShape2D.new()
	shape.size = size
	var collision := CollisionShape2D.new()
	collision.shape = shape
	collision.position = size / 2.0  # shapes are centered, our rect starts at the corner
	add_child(collision)
	body_entered.connect(_on_body_entered)


func _process(delta: float) -> void:
	time += delta
	queue_redraw()


func _draw() -> void:
	# Glowing orange that slowly pulses, with a bright top edge and bubbles.
	var pulse := 0.5 + 0.5 * sin(time * 2.0)
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.85, 0.25 + 0.1 * pulse, 0.05))
	draw_rect(Rect2(0, 0, size.x, 5), Color(1.0, 0.75, 0.2))
	for i in int(size.x / 40.0) + 1:
		var x := fmod(i * 40.0 + 13.0, size.x)
		var rise := fmod(time * 0.7 + i * 0.37, 1.0)  # each bubble rises, pops, repeats
		draw_circle(Vector2(x, size.y * (1.0 - rise)), 3.0 + 2.0 * rise, Color(1, 0.8, 0.3, 1.0 - rise))


func _on_body_entered(body: Node) -> void:
	if body.is_in_group("ball"):
		GameManager.lava_touched.emit()
