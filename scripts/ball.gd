extends RigidBody2D
## The dog ball you play as.
##
## How a shot works:
##   1. When the ball has stopped, press the left mouse button anywhere.
##   2. Drag the mouse. The dog stretches and a dotted line shows the aim.
##      Like a slingshot: drag AWAY from where you want to go.
##   3. Let go to launch. Longer drag = more power (up to MAX_DRAG).
##   Right-click or Esc while dragging cancels the shot.
##
## Main.tscn uses these (don't rename them):
##   signal launched, signal came_to_rest, var input_enabled, func reset_to()

signal launched      # sent once per shot (Main counts it as a stroke)
signal came_to_rest  # sent once each time the ball stops moving

## Main sets this to false after you win, so you can't keep shooting.
var input_enabled: bool = true

# --- Tuning numbers. The level was tested with these, so change them carefully.
const POWER := 6.0          # launch speed per pixel dragged
const MAX_DRAG := 200.0     # dragging further than this adds no more power
const MIN_DRAG := 8.0       # tiny drags are ignored (counts as a misclick)
const REST_SPEED := 10.0    # slower than this counts as "stopped"
const REST_TIME := 0.3      # ...for this many seconds

# --- Bounciness (0 = no bounce, 1 = bounces forever)
# How bouncy the next hit is depends on how fast the ball is going:
#   faster than CRASH_SPEED  -> BOUNCE_CRASH  big falls pinball around wildly
#   faster than SETTLE_SPEED -> BOUNCE_NORMAL normal jump landings (the level
#                                             was tested with this, so you can
#                                             still land on ledges)
#   slower                   -> BOUNCE_SETTLE tiny hops die out, so you can
#                                             shoot again sooner
# (0.9 on every hit was tried: then nothing can ever land on a ledge.)
const BOUNCE_CRASH := 0.9
const BOUNCE_NORMAL := 0.6
const BOUNCE_SETTLE := 0.3
const CRASH_SPEED := 900.0   # pixels per second
const SETTLE_SPEED := 250.0
# Top speed. Long falls would otherwise get so fast that the ball could skip
# through a thin ledge in one frame. 1800 px/s = 30 px per frame, always safe.
const MAX_SPEED := 1800.0

# --- Look and feel
const MAX_STRETCH := 0.35   # how much the dog stretches at full power (35%)
const SQUISH_SPEED := 250.0 # landing faster than this makes the dog squish

# The dog picture sits inside "Stretch". Stretching that node squashes the
# picture in any direction we want (see _set_stretch below).
@onready var stretch: Node2D = $Stretch
@onready var dog: Sprite2D = $Stretch/Dog

var aiming := false            # true while the mouse button is held
var drag_start := Vector2.ZERO # where the mouse was pressed (world position)
var at_rest := true            # true when the ball is stopped and can shoot
var still_time := 0.0          # how long the ball has been slow
var last_velocity := Vector2.ZERO  # speed last physics frame (for the squish)
var stretch_angle := 0.0       # which way the dog is being stretched
var squish_tween: Tween
var reset_pending := false
var reset_position := Vector2.ZERO


func _ready() -> void:
	# body_entered fires whenever the ball touches something new.
	# (It needs contact_monitor on, which Ball.tscn sets.)
	body_entered.connect(_on_body_entered)


func _process(_delta: float) -> void:
	# The physics ball rolls and spins. Every frame we turn the Stretch node
	# back to a fixed screen angle, so the dog stays upright and readable.
	stretch.global_rotation = stretch_angle
	if aiming:
		_update_aim_stretch()
	queue_redraw()  # redraw the aim line every frame


func _physics_process(delta: float) -> void:
	last_velocity = linear_velocity
	# Pick the bounciness for the next hit based on how fast we're going now.
	var speed := linear_velocity.length()
	var wanted := BOUNCE_SETTLE
	if speed > CRASH_SPEED:
		wanted = BOUNCE_CRASH
	elif speed > SETTLE_SPEED:
		wanted = BOUNCE_NORMAL
	if physics_material_override.bounce != wanted:  # only touch it when it changes
		physics_material_override.bounce = wanted
	# Rest detection: slow for REST_TIME seconds in a row = stopped.
	if not at_rest:
		if linear_velocity.length() < REST_SPEED:
			still_time += delta
			if still_time >= REST_TIME:
				at_rest = true
				came_to_rest.emit()
		else:
			still_time = 0.0


func _unhandled_input(event: InputEvent) -> void:
	if not input_enabled:
		return

	# Cancel the shot with Esc or right-click.
	var esc: bool = event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE
	var right_click: bool = event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_RIGHT
	if aiming and (esc or right_click):
		_stop_aiming()
		return

	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed and at_rest:
			aiming = true
			drag_start = get_global_mouse_position()
		elif not event.pressed and aiming:
			_launch()


## The drag as a vector pointing where the ball will fly (slingshot style).
func _get_shot() -> Vector2:
	return (drag_start - get_global_mouse_position()).limit_length(MAX_DRAG)


func _launch() -> void:
	var shot := _get_shot()
	_stop_aiming()
	if shot.length() < MIN_DRAG:
		return
	at_rest = false
	still_time = 0.0
	apply_central_impulse(shot * POWER)
	launched.emit()


func _stop_aiming() -> void:
	aiming = false
	_set_stretch(Vector2.RIGHT, 1.0, 1.0)


# --- Stretch while pulling ---------------------------------------------------

func _update_aim_stretch() -> void:
	var shot := _get_shot()
	if shot.length() < 1.0:
		_set_stretch(Vector2.RIGHT, 1.0, 1.0)
		return
	var power := shot.length() / MAX_DRAG  # 0.0 .. 1.0
	# Longer along the pull, a bit thinner across it, like a stretched rubber ball.
	_set_stretch(shot, 1.0 + MAX_STRETCH * power, 1.0 - MAX_STRETCH * 0.5 * power)


## Stretches the dog by `along` in `direction` and by `across` sideways,
## while keeping the dog's face upright.
## Trick: turn the Stretch node to face the direction, scale it, and turn the
## picture back by the same amount.
func _set_stretch(direction: Vector2, along: float, across: float) -> void:
	stretch_angle = direction.angle()
	stretch.global_rotation = stretch_angle
	stretch.scale = Vector2(along, across)
	dog.rotation = -stretch_angle


# --- Squish when landing -----------------------------------------------------

func _on_body_entered(_body: Node) -> void:
	var speed := last_velocity.length()
	if speed < SQUISH_SPEED or aiming:
		return
	# Squash flat in the direction we hit, then spring back.
	var amount := clampf(speed / 1200.0, 0.15, 0.4)
	if squish_tween:
		squish_tween.kill()
	_set_stretch(last_velocity, 1.0 - amount, 1.0 + amount * 0.6)
	squish_tween = create_tween()
	squish_tween.tween_property(stretch, "scale", Vector2.ONE, 0.25) \
		.set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)


# --- Aim line ----------------------------------------------------------------

func _draw() -> void:
	if not aiming:
		return
	var shot := _get_shot()
	if shot.length() < 1.0:
		return
	# _draw uses the ball's own (spinning) coordinates. This line undoes the
	# spin, so the dots point the real direction on screen.
	draw_set_transform(Vector2.ZERO, -rotation, Vector2.ONE)
	var power := shot.length() / MAX_DRAG
	var color := Color("#42d77d").lerp(Color("#ef5350"), power)  # green -> red
	var direction := shot.normalized()
	var length := 30.0 + 110.0 * power
	for i in 8:  # 8 dots
		var p := direction * (24.0 + i * length / 8.0)
		draw_circle(p, 3.0, color)


# --- Teleport (used by Main for spawn, R and Play Again) ---------------------

func reset_to(pos: Vector2) -> void:
	# A RigidBody2D should only be moved inside _integrate_forces, so we just
	# remember the position here and apply it on the next physics step.
	reset_position = pos
	reset_pending = true
	_stop_aiming()
	at_rest = true
	still_time = 0.0


func _integrate_forces(state: PhysicsDirectBodyState2D) -> void:
	state.linear_velocity = state.linear_velocity.limit_length(MAX_SPEED)
	if reset_pending:
		state.transform = Transform2D(0.0, reset_position)
		state.linear_velocity = Vector2.ZERO
		state.angular_velocity = 0.0
		reset_pending = false
