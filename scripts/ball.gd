extends RigidBody2D
## Player-controlled ball used by Main.tscn.

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

@export_category("Launch")
@export var launch_power: float = 6.0
@export var min_drag: float = 8.0
@export var max_drag: float = 200.0
@export var pull_cooldown: float = 0.1
@export var invert_direction: bool = false

@export_category("Rest")
@export var rest_speed: float = 10.0
@export var rest_time_required: float = 0.3

var _aiming := false
var _drag_start := Vector2.ZERO
var _is_at_rest := true
var _still_time := 0.0
var _cooldown_remaining := 0.0
var _visual_scale := Vector2.ONE
var _was_touching := false
var _reset_pending := false
var _reset_position := Vector2.ZERO


func _ready() -> void:
	_update_collision_shape()
	queue_redraw()


func _physics_process(delta: float) -> void:
	_cooldown_remaining = maxf(_cooldown_remaining - delta, 0.0)

	var touching := get_contact_count() > 0
	if touching and not _was_touching and not _is_at_rest:
		_squish_on_impact()
	_was_touching = touching
	queue_redraw()

	if not _is_at_rest and not _aiming:
		if linear_velocity.length() < rest_speed:
			_still_time += delta
			if _still_time >= rest_time_required:
				_is_at_rest = true
				came_to_rest.emit()
		else:
			_still_time = 0.0


func _unhandled_input(event: InputEvent) -> void:
	if not input_enabled:
		return

	if event is InputEventKey and event.keycode == KEY_ESCAPE and event.pressed:
		_cancel_aim()
		return

	if not event is InputEventMouseButton:
		return

	if event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
		_cancel_aim()
		return

	if event.button_index != MOUSE_BUTTON_LEFT:
		return

	if event.pressed:
		if _is_at_rest and _cooldown_remaining <= 0.0:
			_aiming = true
			_drag_start = get_global_mouse_position()
			queue_redraw()
	else:
		if _aiming:
			_release_aim()


func _release_aim() -> void:
	var mouse_position := get_global_mouse_position()
	var drag := (_drag_start - mouse_position).limit_length(max_drag)
	_cancel_aim()

	if drag.length() < min_drag:
		return

	var launch_vector := drag
	if invert_direction:
		launch_vector = -launch_vector

	_is_at_rest = false
	_still_time = 0.0
	_cooldown_remaining = pull_cooldown
	apply_central_impulse(launch_vector * launch_power)
	launched.emit()


func _cancel_aim() -> void:
	_aiming = false
	_drag_start = Vector2.ZERO
	queue_redraw()


func _draw() -> void:
	draw_set_transform(Vector2.ZERO, 0.0, _visual_scale)
	draw_circle(Vector2.ZERO, radius, Color("#f6c85f"))
	draw_arc(Vector2.ZERO, radius, 0.0, TAU, 32, Color("#2d3748"), 2.0)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

	if not _aiming:
		return

	var drag := (_drag_start - get_global_mouse_position()).limit_length(max_drag)
	if drag.length() < 1.0:
		return

	var direction := drag.normalized().rotated(-rotation)
	if invert_direction:
		direction = -direction

	var power_ratio := clampf(drag.length() / max_drag, 0.0, 1.0)
	var line_color := Color("#42d77d").lerp(Color("#ef5350"), power_ratio)
	var line_length := 24.0 + 80.0 * power_ratio
	for index in range(8):
		var start := direction * (index * line_length / 8.0)
		var end := direction * (index * line_length / 8.0 + line_length / 16.0)
		draw_line(start, end, line_color, 3.0)


func _squish_on_impact() -> void:
	var impact_tween := create_tween()
	impact_tween.tween_property(self, "_visual_scale", Vector2(1.2, 0.8), 0.06)
	impact_tween.tween_property(self, "_visual_scale", Vector2.ONE, 0.18)


func _update_collision_shape() -> void:
	var collision_shape := get_node_or_null("CollisionShape2D") as CollisionShape2D
	if collision_shape == null:
		return

	var circle := collision_shape.shape as CircleShape2D
	if circle != null:
		circle.radius = radius


func reset_to(pos: Vector2) -> void:
	_reset_position = pos
	_reset_pending = true
	_aiming = false
	_is_at_rest = true
	_still_time = 0.0
	_cooldown_remaining = 0.0


func _integrate_forces(state: PhysicsDirectBodyState2D) -> void:
	if not _reset_pending:
		return

	state.transform = Transform2D(0.0, _reset_position)
	state.linear_velocity = Vector2.ZERO
	state.angular_velocity = 0.0
	_reset_pending = false
