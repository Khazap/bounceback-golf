extends SceneTree
## Level builder: writes the 3 level scenes in scenes/level/ from the layouts below.
## It is a tool for us, not part of the game. Run it from a terminal:
##   Godot_console.exe --headless --path . --script res://scripts/level_builder.gd
## Change a layout, run it again, and the levels are rebuilt.
## (Don't hand-paint tiles in the editor: re-running this overwrites them.)
##
##   1. Tower.tscn     - tall tile tower: Foothills, Canyon, Cliffs, Big Fall, Summit.
##   2. LavaCaves.tscn - tile cave with a lava floor, lava patches, jelly, mud, ice.
##   3. Mountain.tscn  - one big mountain made of shapes (no tiles), terrace by terrace.
##
## Coordinates are in TILES (1 tile = 32 pixels). Rows are negative going up
## (row -10 is 10 tiles above the floor). A block is [x1, top_row, x2, bottom_row, material].

const TILE := 32

# Tile materials. "earth" becomes grass on top and dirt underneath.
const EARTH := "earth"
const STONE := "stone"
const SRC_GRASS := 0
const SRC_DIRT := 1
const SRC_STONE := 2

# Colors for things drawn with shapes instead of tiles.
const ROCK_COLOR := Color(0.25, 0.24, 0.28)
const SURFACE_COLORS := {"ice": Color(0.7, 0.92, 1.0), "jelly": Color(1.0, 0.45, 0.75), "mud": Color(0.42, 0.28, 0.12)}
const SURFACE_FRICTION := {"ice": 0.02, "jelly": 0.8, "mud": 1.0}


# =============================================================================
# LEVEL 1: THE TOWER (one screen wide, about 15 screens tall)
# =============================================================================
const T_TOP := -300
const T_WIDTH := 36
const TOWER := {
	"path": "res://scenes/level/Tower.tscn",
	"blocks": [
		# Frame: floor, walls, ceiling (extra thick so the camera never shows the void)
		[-18, 0, T_WIDTH + 17, 12, EARTH],
		[-18, T_TOP, -1, 0, STONE],
		[T_WIDTH, T_TOP, T_WIDTH + 17, 0, STONE],
		[-18, T_TOP - 12, T_WIDTH + 17, T_TOP - 1, STONE],
		# The divider: splits the tower into the climb (left) and the Big Fall shaft (right).
		[25, -190, 26, -58, STONE],
		# --- Foothills (rise 5 per step)
		[12, -5, 21, -3, EARTH], [24, -10, 35, -8, EARTH], [10, -15, 19, -13, EARTH],
		[0, -20, 7, -18, EARTH], [11, -25, 19, -23, EARTH], [24, -30, 31, -28, EARTH],
		[13, -35, 20, -33, EARTH], [0, -40, 6, -38, EARTH], [9, -46, 16, -44, EARTH],
		# --- Canyon (rise 6-7, left side only)
		[14, -52, 20, -50, EARTH], [3, -59, 8, -57, EARTH], [13, -66, 18, -64, EARTH],
		[0, -73, 4, -71, EARTH], [10, -80, 15, -78, EARTH], [19, -87, 24, -85, EARTH],
		[7, -94, 12, -92, EARTH], [0, -101, 3, -99, EARTH], [9, -108, 14, -106, EARTH],
		# --- Cliffs (tiny stone ledges, and an overhang that forces a flat shot)
		[19, -115, 22, -113, STONE], [10, -122, 13, -120, STONE], [0, -128, 3, -126, STONE],
		[8, -135, 11, -133, STONE], [17, -142, 20, -140, STONE], [6, -149, 9, -147, STONE],
		[16, -156, 19, -154, STONE], [5, -163, 8, -161, STONE], [14, -170, 17, -168, STONE],
		[21, -177, 24, -175, STONE], [10, -184, 14, -182, STONE],
		[9, -130, 17, -129, STONE],
		# --- The Big Fall (ledges hanging over the open shaft)
		[21, -192, 26, -190, STONE], [32, -199, 35, -197, STONE], [27, -207, 29, -205, STONE],
		[32, -215, 35, -213, STONE], [26, -223, 28, -221, STONE], [33, -231, 35, -229, STONE],
		# --- Summit (nothing catches you)
		[22, -239, 25, -237, STONE], [11, -246, 14, -244, STONE], [2, -253, 5, -251, STONE],
		[12, -261, 14, -259, STONE], [22, -268, 24, -266, STONE], [30, -275, 35, -273, STONE],
		[14, -284, 24, -282, STONE],  # summit (the hole is cut into it)
	],
	# Slippery rock slopes, as polygons in tile-corner coordinates.
	"slopes": [
		[Vector2(31, -20), Vector2(36, -26), Vector2(36, -20)],
		[Vector2(19, -124), Vector2(25, -128), Vector2(25, -127), Vector2(19, -123)],
		[Vector2(31, -203), Vector2(36, -206), Vector2(36, -203)],
		[Vector2(0, -268), Vector2(6, -262), Vector2(0, -262)],
	],
	"coins": [
		Vector2i(18, -16), Vector2i(1, -21), Vector2i(30, -31), Vector2i(22, -42),
		Vector2i(17, -53), Vector2i(1, -74), Vector2i(22, -88),
		Vector2i(31, -80), Vector2i(31, -120), Vector2i(31, -160),  # inside the shaft
		Vector2i(11, -123), Vector2i(19, -143), Vector2i(15, -171),
		Vector2i(28, -208), Vector2i(34, -232), Vector2i(3, -254), Vector2i(23, -269),
	],
	"cup": [Vector2i(18, -284), Vector2i(19, -284)],
	"spawn": Vector2(4.5, -0.75),
	"sign": "The hole is up there somewhere.\n↑",
}


# =============================================================================
# LEVEL 2: LAVA CAVES (one screen wide, about 7 screens tall, dark cave)
# Lava sends you back to the start. Jelly pads fling you up. Mud stops you dead.
# =============================================================================
const C_TOP := -135
const C_WIDTH := 36
const CAVES := {
	"path": "res://scenes/level/LavaCaves.tscn",
	"background": Color(0.16, 0.07, 0.06),
	"blocks": [
		[-18, 0, C_WIDTH + 17, 12, STONE],
		[-18, C_TOP, -1, 0, STONE],
		[C_WIDTH, C_TOP, C_WIDTH + 17, 0, STONE],
		[-18, C_TOP - 12, C_WIDTH + 17, C_TOP - 1, STONE],
		# the climb
		[12, -5, 15, -3, STONE], [20, -10, 24, -8, STONE],
		[29, -14, 35, -12, STONE],   # jelly pad
		[18, -24, 23, -22, STONE], [6, -29, 10, -27, STONE],  # mud
		[0, -35, 3, -33, STONE], [8, -41, 12, -39, STONE],    # lava patch on the right end
		[18, -48, 22, -46, STONE], [28, -55, 33, -53, STONE], # lava patch on the left end
		[18, -62, 21, -60, STONE],   # ice
		[6, -68, 10, -66, STONE], [0, -75, 3, -73, STONE],
		[9, -82, 12, -80, STONE],    # jelly pad
		[20, -95, 25, -93, STONE], [31, -102, 35, -100, STONE],
		[20, -108, 24, -106, STONE], # lava patch on the left end
		[8, -115, 12, -113, STONE],
		[16, -123, 26, -121, STONE], # summit (the hole is cut into it)
	],
	# Lava rectangles [x1, top_row, x2, bottom_row]. Tiles there are removed.
	"lava": [
		[9, 0, 35, 0],          # the whole cave floor except the start
		[11, -41, 12, -41], [28, -55, 29, -55], [20, -108, 20, -108],
	],
	# Surface strips on top of ledges: [x1, x2, top_row, kind]
	"surfaces": [
		[29, 35, -14, "jelly"], [6, 10, -29, "mud"], [18, 21, -62, "ice"], [9, 12, -82, "jelly"],
	],
	"coins": [
		Vector2i(20, -3), Vector2i(33, -16), Vector2i(2, -36), Vector2i(10, -42),
		Vector2i(30, -56), Vector2i(12, -83), Vector2i(23, -109), Vector2i(35, -103),
	],
	"cup": [Vector2i(21, -123), Vector2i(22, -123)],
	"spawn": Vector2(4.5, -0.75),
	"sign": "Lava = back to the start.\nPink jelly bounces. Brown mud sticks.\n↑",
}


# =============================================================================
# LEVEL 3: THE MOUNTAIN (no tiles: one big rock shape, climbed left to right)
# Each terrace = a steep face, then a shelf. Shelves can be rock, mud, jelly
# or ice. Rock/mud/jelly shelves tilt inward (you roll toward the next face);
# ice shelves are flat and slippery (you might slide back off the edge).
# =============================================================================
const MOUNTAIN_PATH := "res://scenes/level/Mountain.tscn"
# [face width, face height, shelf length, shelf surface]
const TERRACES := [
	[2, 4, 10, "rock"], [2, 5, 9, "rock"], [3, 6, 8, "rock"], [2, 6, 7, "mud"],
	[3, 7, 7, "rock"], [2, 7, 6, "jelly"], [3, 8, 6, "rock"], [2, 8, 5, "ice"],
	[3, 9, 6, "rock"], [2, 9, 5, "mud"], [3, 10, 5, "ice"], [2, 10, 5, "rock"],
	[3, 11, 5, "jelly"], [2, 11, 4, "ice"], [3, 12, 5, "rock"],
]
const MOUNTAIN_COLOR := Color(0.42, 0.37, 0.33)
const SNOW_COLOR := Color(0.93, 0.95, 1.0)


func _initialize() -> void:
	make_tile_images()
	if not ResourceLoader.exists("res://art/tiles/stone.png"):
		print("New tile images made. Open the project once (or run the editor import), then run this again.")
		quit()
		return
	var err := ResourceSaver.save(make_tileset(), "res://scenes/level/level_tileset.tres")
	assert(err == OK)
	var tileset: TileSet = load("res://scenes/level/level_tileset.tres")
	build_tile_level(TOWER, tileset)
	build_tile_level(CAVES, tileset)
	build_mountain()
	quit()


# =============================================================================
# Building tile levels (Tower, Lava Caves)
# =============================================================================

func build_tile_level(data: Dictionary, tileset: TileSet) -> void:
	var level := new_level()

	if data.has("background"):  # a dark cave wall behind everything
		var bg := Polygon2D.new()
		bg.name = "Background"
		bg.polygon = rect_points(Rect2(-40 * TILE, -400 * TILE, 120 * TILE, 420 * TILE))
		bg.color = data.background
		bg.z_index = -10
		_add(level, bg)

	var tiles := TileMapLayer.new()
	tiles.name = "Tiles"
	tiles.tile_set = tileset
	_add(level, tiles)

	# 1. Fill every block, remembering which material each cell is.
	var cells := {}  # Vector2i -> material
	for b in data.blocks:
		for x in range(b[0], b[2] + 1):
			for y in range(b[1], b[3] + 1):
				cells[Vector2i(x, y)] = b[4]
	# 2. Remove cells for the cup and for lava.
	for c in data.cup:
		cells.erase(c)
	for l in data.get("lava", []):
		for x in range(l[0], l[2] + 1):
			for y in range(l[1], l[3] + 1):
				cells.erase(Vector2i(x, y))
	# 3. Earth cells with open air above get grass, the rest dirt.
	for cell in cells:
		var src := SRC_STONE
		if cells[cell] == EARTH:
			src = SRC_DIRT if cells.has(cell + Vector2i.UP) else SRC_GRASS
		tiles.set_cell(cell, src, Vector2i.ZERO)

	# 4. Slopes, lava and special surfaces.
	for i in data.get("slopes", []).size():
		var pts := PackedVector2Array()
		for p in data.slopes[i]:
			pts.append(p * TILE)
		add_shape_body(level, "Slope%d" % i, pts, ROCK_COLOR, "", 0.0)
	for l in data.get("lava", []):
		add_lava(level, Rect2(l[0] * TILE, l[1] * TILE, (l[2] - l[0] + 1) * TILE, (l[3] - l[1] + 1) * TILE))
	for s in data.get("surfaces", []):
		# a strip on top of the ledge, sticking up a little so the ball touches it
		var top := float(s[2] * TILE)
		var pts := rect_points(Rect2(s[0] * TILE, top - 6, (s[1] - s[0] + 1) * TILE, 12))
		add_shape_body(level, "Surface_%s_%d_%d" % [s[3], s[0], s[2]], pts, SURFACE_COLORS[s[3]], s[3], SURFACE_FRICTION[s[3]])

	# 5. Spawn, goal, coins, sign.
	var cup_center := (Vector2(data.cup[0]) + Vector2(data.cup[1])) / 2.0 + Vector2(0.5, 0.0)
	add_common(level, data.spawn * TILE, Vector2(cup_center.x, data.cup[0].y) * TILE + Vector2(0, 24), data.coins, data.sign)
	save_level(level, data.path, "%d tiles" % cells.size())


# =============================================================================
# Building the mountain (shapes, no tiles)
# =============================================================================

func build_mountain() -> void:
	var level := new_level()

	# Walk up the terraces, writing down the outline of the mountain's top edge.
	var outline: Array[Vector2] = [Vector2(-30, 0), Vector2(0, 0)]
	var shelves := []  # [start point, end point, surface] for each shelf
	var p := Vector2(0, 0)
	for t in TERRACES:
		p += Vector2(t[0], -t[1])         # up the steep face
		outline.append(p)
		var tilt := 0.0 if t[3] == "ice" else 1.0  # +1 = inner end is 1 tile lower
		var shelf_end := p + Vector2(t[2], tilt)
		outline.append(shelf_end)
		shelves.append([p, shelf_end, t[3]])
		p = shelf_end
	# Final face up to the summit, then the summit shelf with the cup in it.
	p += Vector2(3, -12)
	outline.append(p)
	var summit := p
	outline.append_array([summit + Vector2(2, 0), summit + Vector2(2, 1), summit + Vector2(4, 1),
		summit + Vector2(4, 0), summit + Vector2(7, 0)])
	# The spire: a rock wall behind the summit, so you can't fly over the back.
	outline.append_array([summit + Vector2(7, -18), summit + Vector2(12, -20), summit + Vector2(16, -14)])
	# Down the back to the floor (row 12 = bottom of the map), then back left.
	outline.append(Vector2(summit.x + 16, 12))
	outline.append(Vector2(-30, 12))

	var points := PackedVector2Array()
	for v in outline:
		points.append(v * TILE)
	add_shape_body(level, "Mountain", points, MOUNTAIN_COLOR, "", 1.0)

	# Snow on the top third: a thin white line along the outline.
	var snow := Line2D.new()
	snow.name = "Snow"
	snow.width = 10.0
	snow.default_color = SNOW_COLOR
	for v in outline.slice(int(outline.size() * 0.6), outline.size() - 2):
		snow.add_point(v * TILE + Vector2(0, 3))
	_add(level, snow)

	# A tall wall on the far left so shots can't fly off the map.
	add_shape_body(level, "LeftWall", rect_points(Rect2(-40 * TILE, -200 * TILE, 10 * TILE, 212 * TILE)), ROCK_COLOR, "", 1.0)

	# Special surfaces on their shelves, and a coin above every other shelf.
	var coins: Array = []
	for i in shelves.size():
		var s = shelves[i]
		var a: Vector2 = s[0] * TILE
		var b: Vector2 = s[1] * TILE
		if s[2] != "rock":
			var strip := PackedVector2Array([a + Vector2(0, -6), b + Vector2(0, -6), b + Vector2(0, 8), a + Vector2(0, 8)])
			add_shape_body(level, "Surface_%s_%d" % [s[2], i], strip, SURFACE_COLORS[s[2]], s[2], SURFACE_FRICTION[s[2]])
		if i % 2 == 1:
			coins.append(Vector2i(((s[0] + s[1]) / 2.0 + Vector2(0, -1.5)).floor()))

	var cup_center := summit + Vector2(3, 1)
	add_common(level, Vector2(-20.5, -0.75) * TILE, cup_center * TILE + Vector2(0, -8), coins,
		"Just a mountain.\nIce slides, jelly flings, mud sticks.\n→")
	save_level(level, MOUNTAIN_PATH, "%d terraces" % TERRACES.size())


# =============================================================================
# Shared helpers
# =============================================================================

func new_level() -> Node2D:
	var level := Node2D.new()
	level.name = "Level"  # every level's root is called "Level" (Main looks for it)
	return level


## A solid shape: StaticBody2D + collision polygon + a drawn polygon.
## `group` ("ice", "jelly", "mud" or "") tells the ball what surface it is.
func add_shape_body(level: Node, name: String, points: PackedVector2Array, color: Color, group: String, friction: float) -> void:
	var body := StaticBody2D.new()
	body.name = name
	body.physics_material_override = PhysicsMaterial.new()
	body.physics_material_override.friction = friction
	if group != "":
		body.add_to_group(group, true)  # true = saved in the scene file
	_add(level, body)
	var shape := CollisionPolygon2D.new()
	shape.name = "Shape"
	shape.polygon = points
	_add(body, shape, level)
	var look := Polygon2D.new()
	look.name = "Look"
	look.polygon = points
	look.color = color
	_add(body, look, level)


func add_lava(level: Node, rect: Rect2) -> void:
	var lava: Node2D = load("res://scenes/level/Lava.tscn").instantiate()
	lava.name = "Lava_%d_%d" % [rect.position.x / TILE, rect.position.y / TILE]
	lava.position = rect.position
	lava.size = rect.size
	_add(level, lava)


## SpawnPoint, Goal, coins and the start sign (every level has these).
func add_common(level: Node, spawn_pos: Vector2, goal_pos: Vector2, coin_cells: Array, sign_text: String) -> void:
	var spawn := Marker2D.new()
	spawn.name = "SpawnPoint"  # Main looks for this exact name
	spawn.position = spawn_pos
	_add(level, spawn)

	var goal: Node2D = load("res://scenes/level/Goal.tscn").instantiate()
	goal.name = "Goal"
	goal.position = goal_pos
	_add(level, goal)

	var coins := Node2D.new()
	coins.name = "Coins"
	_add(level, coins)
	var coin_scene: PackedScene = load("res://scenes/level/Coin.tscn")
	for i in coin_cells.size():
		var coin: Node2D = coin_scene.instantiate()
		coin.name = "Coin%d" % i
		coin.position = (Vector2(coin_cells[i]) + Vector2(0.5, 0.5)) * TILE  # center of the tile
		_add(coins, coin, level)

	var sign := Label.new()
	sign.name = "StartSign"
	sign.text = sign_text
	sign.position = spawn_pos + Vector2(-96, -150)
	sign.add_theme_font_size_override("font_size", 20)
	sign.add_theme_color_override("font_color", Color(1, 1, 1, 0.8))
	sign.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.6))
	sign.add_theme_constant_override("outline_size", 4)
	_add(level, sign)


func save_level(level: Node, path: String, info: String) -> void:
	var packed := PackedScene.new()
	packed.pack(level)
	var err := ResourceSaver.save(packed, path)
	print("%s saved: %s (%s)" % [path.get_file(), err == OK, info])
	level.free()


func rect_points(r: Rect2) -> PackedVector2Array:
	return PackedVector2Array([r.position, Vector2(r.end.x, r.position.y), r.end, Vector2(r.position.x, r.end.y)])


## Adds `child` under `parent` and marks it as part of the saved scene.
func _add(parent: Node, child: Node, scene_root: Node = null) -> void:
	parent.add_child(child)
	child.owner = scene_root if scene_root else parent


# =============================================================================
# Tiles: shrink Person B's art to 32x32 and make the TileSet
# =============================================================================

## Skips images that already exist, so Godot doesn't re-import every run.
func make_tile_images() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://art/tiles"))
	for pair in [["grass_block", "grass"], ["dirt", "dirt"], ["stone", "stone"]]:
		var out := ProjectSettings.globalize_path("res://art/tiles/%s.png" % pair[1])
		if FileAccess.file_exists(out):
			continue
		var img := Image.load_from_file(ProjectSettings.globalize_path("res://art/%s.png" % pair[0]))
		img.resize(TILE, TILE, Image.INTERPOLATE_LANCZOS)
		img.save_png(out)


func make_tileset() -> TileSet:
	var ts := TileSet.new()
	ts.tile_size = Vector2i(TILE, TILE)
	ts.add_physics_layer()
	var square := PackedVector2Array([Vector2(-16, -16), Vector2(16, -16), Vector2(16, 16), Vector2(-16, 16)])
	for name in ["grass", "dirt", "stone"]:
		var src := TileSetAtlasSource.new()
		src.texture = load("res://art/tiles/%s.png" % name)
		src.texture_region_size = Vector2i(TILE, TILE)
		src.create_tile(Vector2i.ZERO)
		ts.add_source(src)  # add first, so the tile knows about physics layer 0
		var data := src.get_tile_data(Vector2i.ZERO, 0)
		data.add_collision_polygon(0)
		data.set_collision_polygon_points(0, 0, square)
	return ts
