extends RigidBody2D

@export var launch_power := 4.5
@export var max_pull := 360.0
@export var grab_radius := 240.0
@export var floor_top := 472.0
@export var collision_radius := 205.0
@export var floor_tolerance := 12.0
@export var pull_stretch := 0.45
@export var pull_cooldown := 5

@onready var sprite: Sprite2D = $Sprite2D

var dragging := false
var grounded := true
var drag_start := Vector2.ZERO
var base_scale := Vector2.ONE
var cooldown_remaining := 0.0


func _ready() -> void:
	freeze = true
	lock_rotation = true
	base_scale = sprite.scale

	contact_monitor = true
	max_contacts_reported = 4

	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)


func _physics_process(delta: float) -> void:
	cooldown_remaining = maxf(cooldown_remaining - delta, 0.0)


func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed and not dragging and cooldown_remaining <= 0.0:
				var mouse_position := get_global_mouse_position()

				if mouse_position.distance_to(global_position) <= grab_radius:
					dragging = true
					drag_start = global_position
					freeze = true
					linear_velocity = Vector2.ZERO
					angular_velocity = 0.0

			elif not event.pressed and dragging:
				dragging = false
				grounded = false
				sprite.scale = base_scale

				var mouse_position := get_global_mouse_position()
				var launch_vector := (drag_start - mouse_position).limit_length(max_pull)

				if launch_vector.length() > 8.0:
					freeze = false
					apply_central_impulse(launch_vector * launch_power)
					cooldown_remaining = pull_cooldown

	if event is InputEventMouseMotion and dragging:
		var mouse_position := get_global_mouse_position()
		var pull_offset := (mouse_position - drag_start).limit_length(max_pull)
		var target_position := drag_start + pull_offset

		target_position.y = min(target_position.y, floor_top - collision_radius)
		global_position = target_position

		var stretch := Vector2(
			1.0 + abs(pull_offset.x) / max_pull * pull_stretch,
			1.0 + abs(pull_offset.y) / max_pull * pull_stretch
		)

		sprite.scale = base_scale * stretch


func is_resting_on_floor() -> bool:
	var floor_center_y := floor_top - collision_radius
	var near_floor: bool = abs(global_position.y - floor_center_y) <= floor_tolerance
	return near_floor and linear_velocity.length() < 35.0


func _on_body_exited(body: Node) -> void:
	if body.name == "Floor":
		grounded = false


func _on_body_entered(body: Node) -> void:
	if body.name != "Floor":
		return

	grounded = true

	var squish_tween := create_tween()
	squish_tween.tween_property(
		sprite,
		"scale",
		base_scale * Vector2(1.18, 0.82),
		0.06
	)
	squish_tween.tween_property(
		sprite,
		"scale",
		base_scale,
		0.22
	)