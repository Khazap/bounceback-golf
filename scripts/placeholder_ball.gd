extends RigidBody2D
## TEMPORARY stand-in for Person A's real ball (scenes/ball/Ball.tscn).
## It has the same signals, variable and function as the team contract, so
## main.gd works the same with this one and with the real one.
## Delete this file once the real Ball is in Main.tscn.

signal launched
signal came_to_rest

var input_enabled: bool = true

const RADIUS := 16.0
const POWER := 6.0       # launch speed per pixel dragged
const MAX_DRAG := 200.0  # longer drags don't add more power

var drag_start = null    # where the mouse was pressed (null = not aiming)
var is_moving := false   # true from launch until the ball stops
var still_time := 0.0    # how long the ball has been (almost) still


func _draw() -> void:
	draw_circle(Vector2.ZERO, RADIUS, Color.WHITE)


## Teleports the ball and stops it. RigidBody2D is moved by the physics
## engine, so we set its position through the PhysicsServer2D.
func reset_to(pos: Vector2) -> void:
	linear_velocity = Vector2.ZERO
	angular_velocity = 0.0
	PhysicsServer2D.body_set_state(get_rid(), PhysicsServer2D.BODY_STATE_TRANSFORM, Transform2D(0.0, pos))
	drag_start = null
	is_moving = false


func _unhandled_input(event: InputEvent) -> void:
	if not input_enabled:
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			# Only start aiming when the ball is (almost) stopped.
			if linear_velocity.length() < 10.0:
				drag_start = event.position
		elif drag_start != null:
			# Slingshot: drag away from where you want to shoot.
			var drag: Vector2 = (drag_start - event.position).limit_length(MAX_DRAG)
			drag_start = null
			if drag.length() > 5.0:
				apply_central_impulse(drag * POWER)
				is_moving = true
				still_time = 0.0
				launched.emit()


func _physics_process(delta: float) -> void:
	# The ball counts as "at rest" after being slow for 0.3 seconds.
	if is_moving:
		if linear_velocity.length() < 10.0:
			still_time += delta
			if still_time > 0.3:
				is_moving = false
				came_to_rest.emit()
		else:
			still_time = 0.0
