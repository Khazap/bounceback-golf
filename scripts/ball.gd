extends RigidBody2D
## The dog ball you play as.
##
## How a shot works:
##   1. Wait for the glowing ring + "ding": that means you can aim.
##   2. Press the left mouse button anywhere and drag. The dog stretches and a
##      dotted line shows the aim. Like a slingshot: drag AWAY from the target.
##   3. Let go to launch. Longer drag = more power (up to MAX_DRAG).
##   Right-click or Esc while dragging cancels the shot.
##
## How it bounces:
##   After every shot, the first MIN_BOUNCES landings ALWAYS bounce up (at
##   least MIN_BOUNCE_SPEED), so you can't stick a soft landing.
##   After that: hits faster than STOP_SPEED bounce hard (BOUNCE), slower
##   ones on flat ground stop dead. On slopes it never stops: it slides off.
##
## Special surfaces:
##   Ice (light blue)  - slippery, you only stop when almost still.
##   Jelly (pink)      - flings you up at JELLY_SPEED every time you land on it.
##   Mud (brown)       - sticky, stops you dead instantly. No bounces.
##
## Main.tscn uses these (don't rename them):
##   signal launched, signal came_to_rest, var input_enabled, func reset_to()

signal launched      # sent once per shot (Main counts it as a stroke)
signal came_to_rest  # sent once each time the ball stops moving

## Main sets this to false after you win, so you can't keep shooting.
var input_enabled: bool = true

# --- Shooting
const POWER := 6.0          # launch speed per pixel dragged
const MAX_DRAG := 200.0     # dragging further than this adds no more power
const MIN_DRAG := 8.0       # tiny drags are ignored (counts as a misclick)

# --- Bouncing and stopping
const BOUNCE := 0.93        # 0 = no bounce, 1 = never loses height. 0.93 keeps 86% each bounce
const FRICTION := 0.8       # grip on the ground (0 = ice, 1 = rubber)
const STOP_SPEED := 500.0   # slower than this (pixels/second) on flat ground = stop dead
                            # (500 = hops lower than about 4 tiles stop instead)
const MAX_SPEED := 1800.0   # top speed, so long falls never skip through a ledge
const REST_TIME := 0.2      # how long it must be stopped before you can aim again
const MIN_BOUNCES := 2      # every shot bounces at least this many times
const MIN_BOUNCE_SPEED := 320.0  # those forced bounces go up at least this fast (about 2 tiles high)

# --- Special surfaces (the level builder decides where they are)
const JELLY_SPEED := 1100.0  # jelly flings you up this fast (about 19 tiles high)
const ICE_STOP_SPEED := 40.0 # on ice you only stop when nearly still, so you slide

# --- Look and feel
const MAX_STRETCH := 0.35   # how much the dog stretches at full power (35%)
const SQUISH_SPEED := 250.0 # landing faster than this makes the dog squish
const SOUND_SPEED := 160.0  # landing faster than this makes a bounce sound

# The dog picture sits inside "Stretch". Stretching that node squashes the
# picture in any direction we want (see _set_stretch below).
@onready var stretch: Node2D = $Stretch
@onready var dog: Sprite2D = $Stretch/Dog

var aiming := false            # true while the mouse button is held
var drag_start := Vector2.ZERO # where the mouse was pressed (world position)
var at_rest := true            # true when the ball is stopped and can shoot
var still_time := 0.0          # how long the ball has been stopped
var air_time := 0.0            # time since launch (so we don't stop it instantly)
var bounces_left := 0          # forced bounces still to do for this shot
var was_on_ground := false     # touching the ground last physics step?
var was_on_jelly := false      # touching jelly last physics step?
var last_velocity := Vector2.ZERO  # speed last physics frame (for squish and sound)
var stretch_angle := 0.0       # which way the dog is being stretched
var squish_tween: Tween
var reset_pending := false
var reset_position := Vector2.ZERO


func _ready() -> void:
	physics_material_override.bounce = BOUNCE
	physics_material_override.friction = FRICTION
	# body_entered fires whenever the ball touches something new.
	# (It needs contact_monitor on, which Ball.tscn sets.)
	body_entered.connect(_on_body_entered)
	# Wear the skin chosen in the shop, scaled so it's always 40 pixels tall
	# (a bit bigger than the 32-pixel physics circle, so it looks chunky).
	dog.texture = GameManager.equipped_skin_texture()
	dog.scale = Vector2.ONE * (40.0 / dog.texture.get_height())


func _process(_delta: float) -> void:
	# The physics ball rolls and spins. Every frame we turn the Stretch node
	# back to a fixed screen angle, so the dog stays upright and readable.
	stretch.global_rotation = stretch_angle
	if aiming:
		_update_aim_stretch()
	queue_redraw()  # redraw the aim line and ready ring every frame


func _physics_process(delta: float) -> void:
	last_velocity = linear_velocity
	air_time += delta
	# Rest detection: stopped for REST_TIME seconds = ready to aim again.
	if not at_rest:
		if linear_velocity.length() < 10.0:
			still_time += delta
			if still_time >= REST_TIME:
				at_rest = true
				came_to_rest.emit()
				if input_enabled:
					AudioManager.play("ready", 0.6)
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
	air_time = 0.0
	bounces_left = MIN_BOUNCES
	apply_central_impulse(shot * POWER)
	launched.emit()
	AudioManager.play("launch", 0.5 + 0.5 * shot.length() / MAX_DRAG)


func _stop_aiming() -> void:
	aiming = false
	_set_stretch(Vector2.RIGHT, 1.0, 1.0)


# --- Physics: speed cap, stop dead, teleport --------------------------------

## Runs every physics step, in this order:
##   1. teleport (if reset_to was called)  2. speed cap
##   3. forced bounce on landing           4. otherwise maybe stop dead
func _integrate_forces(state: PhysicsDirectBodyState2D) -> void:
	if reset_pending:
		state.transform = Transform2D(0.0, reset_position)
		state.linear_velocity = Vector2.ZERO
		state.angular_velocity = 0.0
		reset_pending = false
		return

	state.linear_velocity = state.linear_velocity.limit_length(MAX_SPEED)

	# Each contact has a "normal": the direction pointing away from the
	# surface. Pointing up (y below -0.5) means we're on the ground, not a wall.
	# We also check what we're touching: special surfaces are in a group
	# called "ice", "jelly" or "mud" (the level builder puts them there).
	var on_ground := false
	var on_ice := false
	var on_jelly := false
	var on_mud := false
	for i in state.get_contact_count():
		if state.get_contact_local_normal(i).y < -0.5:
			on_ground = true
		var thing := state.get_contact_collider_object(i) as Node
		if thing:
			on_ice = on_ice or thing.is_in_group("ice")
			on_jelly = on_jelly or thing.is_in_group("jelly")
			on_mud = on_mud or thing.is_in_group("mud")

	# Mud: sticky. Stop dead the moment we touch it (but not right after launching from it).
	if on_mud and air_time > 0.15:
		state.linear_velocity = Vector2.ZERO
		state.angular_velocity = 0.0
		bounces_left = 0
		was_on_ground = on_ground
		return

	# Jelly: every time we land on it, it flings us up at JELLY_SPEED.
	if on_jelly and not was_on_jelly and air_time > 0.05:
		var jv := state.linear_velocity
		jv.y = -JELLY_SPEED
		state.linear_velocity = jv
		was_on_jelly = true
		was_on_ground = on_ground
		AudioManager.play("jelly", 0.8, randf_range(0.9, 1.1))
		return
	was_on_jelly = on_jelly

	# Forced bounces: the moment we land (not on ground -> on ground), if this
	# shot still owes bounces, kick the ball back up at least MIN_BOUNCE_SPEED.
	# (Up is negative Y, so "at least this fast upward" = minf with a negative.)
	if on_ground and not was_on_ground and bounces_left > 0 and air_time > 0.05:
		var v := state.linear_velocity
		v.y = minf(v.y, -MIN_BOUNCE_SPEED)
		state.linear_velocity = v
		bounces_left -= 1
		was_on_ground = on_ground
		return  # skip the stop check this step, or it would cancel the bounce
	was_on_ground = on_ground

	# Stop dead: no forced bounces left, slow, AND touching flat ground. (A
	# normal with y < -0.9 is nearly straight up = flat. Slopes are steeper.)
	# air_time > 0.15 so a weak shot isn't cancelled the moment it starts.
	# On ice we only stop when almost still, so you slide (maybe off the edge).
	var stop_speed := ICE_STOP_SPEED if on_ice else STOP_SPEED
	if bounces_left == 0 and air_time > 0.15 and state.linear_velocity.length() < stop_speed:
		for i in state.get_contact_count():
			if state.get_contact_local_normal(i).y < -0.9:
				state.linear_velocity = Vector2.ZERO
				state.angular_velocity = 0.0
				break


## Teleports the ball and stops it (used by Main for spawn, R and Play Again).
func reset_to(pos: Vector2) -> void:
	# A RigidBody2D should only be moved inside _integrate_forces, so we just
	# remember the position here and apply it on the next physics step.
	reset_position = pos
	reset_pending = true
	_stop_aiming()
	at_rest = true
	still_time = 0.0
	bounces_left = 0


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


# --- Squish and sound when landing ------------------------------------------

func _on_body_entered(_body: Node) -> void:
	var speed := last_velocity.length()
	if speed > SOUND_SPEED:
		# Louder for harder hits, slightly random pitch so it doesn't get boring.
		AudioManager.play("bounce", clampf(speed / 1200.0, 0.2, 1.0), randf_range(0.9, 1.15))
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


# --- Drawing: aim line and "ready" ring -------------------------------------

func _draw() -> void:
	# _draw uses the ball's own (spinning) coordinates. This undoes the spin,
	# so everything points the real direction on screen.
	draw_set_transform(Vector2.ZERO, -rotation, Vector2.ONE)

	# Ready ring: a soft pulsing circle when you're allowed to aim.
	if at_rest and input_enabled and not aiming:
		var pulse := 0.5 + 0.5 * sin(Time.get_ticks_msec() / 150.0)
		draw_arc(Vector2.ZERO, 26.0 + 3.0 * pulse, 0.0, TAU, 40, Color(1, 0.85, 0.2, 0.5 + 0.5 * pulse), 4.0)
		return

	if not aiming:
		return
	var shot := _get_shot()
	if shot.length() < 1.0:
		return
	var power := shot.length() / MAX_DRAG
	var color := Color("#42d77d").lerp(Color("#ef5350"), power)  # green -> red
	var direction := shot.normalized()
	var length := 30.0 + 110.0 * power
	for i in 8:  # 8 dots
		var p := direction * (24.0 + i * length / 8.0)
		draw_circle(p, 3.0, color)
