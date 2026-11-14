extends Area2D
## TEMPORARY stand-in for Person B's Goal. Same rule as the real one:
## when a body in group "ball" enters, tell GameManager we won.
## Delete this file once the real Level is in Main.tscn.


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node) -> void:
	if body.is_in_group("ball"):
		GameManager.win()
