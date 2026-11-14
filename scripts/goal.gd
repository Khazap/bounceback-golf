extends Area2D
## Goal: the hole at the top. When the ball drops in, the player wins.
## The Area2D sits at the bottom of the cup, so the ball has to fall in.


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node) -> void:
	if body.is_in_group("ball"):
		# GameManager.win() already ignores repeat calls during one run,
		# so we don't need our own "already won" flag here. (A flag here
		# would also break Play Again, because it would never reset.)
		GameManager.win()
