extends RigidBody2D
## The player-controlled ball.
##
## Input and rest detection will be added in the next pass. Keeping the
## drawing here means Ball.tscn has no dependency on external art files.

signal launched
signal came_to_rest

@export_category("Ball")
@export var radius: float = 16.0:

	set(value):
		radius = maxf(value, 1.0)
		_update_collision_shape()
		queue_redraw()

@export var bounce: float = 0.6
@export var input_enabled: bool = true

var _reset_pending: bool = false
var _reset_position: Vector2


func _ready() -> void:
	# The collider's radius is authored in Ball.tscn. This redraws the visual
	# whenever the exported radius is changed in the Inspector.
	_update_collision_shape()
	queue_redraw()


func _update_collision_shape() -> void:
	var collision_shape := get_node_or_null("CollisionShape2D") as CollisionShape2D
	if collision_shape == null:
		return

	var circle := collision_shape.shape as CircleShape2D
	if circle != null:
		circle.radius = radius


func _draw() -> void:
	# A simple high-contrast visual keeps the test scene usable without art.
	draw_circle(Vector2.ZERO, radius, Color("#f6c85f"))
	draw_arc(Vector2.ZERO, radius, 0.0, TAU, 32, Color("#2d3748"), 2.0)


func reset_to(pos: Vector2) -> void:
	# RigidBody2D transforms should be changed during the physics step. The
	# pending flag lets _integrate_forces apply the teleport safely.
	_reset_position = pos
	_reset_pending = true


func _integrate_forces(state: PhysicsDirectBodyState2D) -> void:
	if not _reset_pending:
		return

	state.transform = Transform2D(0.0, _reset_position)
	state.linear_velocity = Vector2.ZERO
	state.angular_velocity = 0.0
	_reset_pending = false
