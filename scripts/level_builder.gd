extends SceneTree
## Level builder: writes scenes/level/Level.tscn from the layout below.
## It is a tool for us, not part of the game. Run it from a terminal:
##   Godot_console.exe --headless --path . --script res://scripts/level_builder.gd
## Change the lists below, run it again, and Level.tscn is rebuilt.
## (Don't hand-paint tiles in the editor: re-running this overwrites them.)
##
## THE CLIMB (one screen wide, about 15 screens tall):
##   1. Foothills    - grassy ledges, small steps. Warm-up.
##   2. Canyon       - dirt ledges on the left side, bigger steps.
##   3. Cliffs       - tiny stone ledges, an overhang, a tilted fake ledge.
##   4. The Big Fall - tiny ledges over an open shaft. Miss, and you drop
##                     straight back down to the Foothills.
##   5. Summit       - no catch ledges at all. The hole is at the very top,
##                     and you can't see it until you're almost there.

const TILE := 32
const TOP := -300  # top row of the playable area (negative Y = up)
const WIDTH := 36  # inside width in tiles: x goes 0..35 (one screen)

# Materials. "earth" becomes grass on top and dirt underneath.
const EARTH := "earth"
const STONE := "stone"

# Tile sources in the TileSet.
const SRC_GRASS := 0
const SRC_DIRT := 1
const SRC_STONE := 2

# Every block is [x1, top_row, x2, bottom_row, material] in tiles.
# Rows are negative going up (row -10 is 10 tiles above the floor).
const BLOCKS := [
	# Frame: floor, walls, ceiling (extra thick so the camera never shows the void)
	[-18, 0, WIDTH + 17, 12, EARTH],
	[-18, TOP, -1, 0, STONE],
	[WIDTH, TOP, WIDTH + 17, 0, STONE],
	[-18, TOP - 12, WIDTH + 17, TOP - 1, STONE],
	# The divider: splits the middle of the tower into the climb (left)
	# and the Big Fall shaft (right). Its top is a ledge in section 4.
	[25, -190, 26, -58, STONE],
]

# The climb, bottom to top, same format. Order matters: it's the path the
# test simulation checks, one jump at a time.
const ROUTE := [
	# --- 1. Foothills (rise 5 per step)
	[12, -5, 21, -3, EARTH],
	[24, -10, 35, -8, EARTH],
	[10, -15, 19, -13, EARTH],
	[0, -20, 7, -18, EARTH],
	[11, -25, 19, -23, EARTH],
	[24, -30, 31, -28, EARTH],
	[13, -35, 20, -33, EARTH],
	[0, -40, 6, -38, EARTH],
	[9, -46, 16, -44, EARTH],
	# --- 2. Canyon (rise 6-7, left side only)
	[14, -52, 20, -50, EARTH],
	[3, -59, 8, -57, EARTH],
	[13, -66, 18, -64, EARTH],
	[0, -73, 4, -71, EARTH],
	[10, -80, 15, -78, EARTH],
	[19, -87, 24, -85, EARTH],
	[7, -94, 12, -92, EARTH],
	[0, -101, 3, -99, EARTH],
	[9, -108, 14, -106, EARTH],
	# --- 3. Cliffs (tiny stone ledges)
	[19, -115, 22, -113, STONE],
	[10, -122, 13, -120, STONE],
	[0, -128, 3, -126, STONE],
	[8, -135, 11, -133, STONE],
	[17, -142, 20, -140, STONE],
	[6, -149, 9, -147, STONE],
	[16, -156, 19, -154, STONE],
	[5, -163, 8, -161, STONE],
	[14, -170, 17, -168, STONE],
	[21, -177, 24, -175, STONE],
	[10, -184, 14, -182, STONE],
	# --- 4. The Big Fall (ledges hanging over the open shaft)
	[21, -192, 26, -190, STONE],  # top of the divider
	[32, -199, 35, -197, STONE],
	[27, -207, 29, -205, STONE],  # floating, 3 tiles wide
	[32, -215, 35, -213, STONE],
	[26, -223, 28, -221, STONE],  # floating, 3 tiles wide
	[33, -231, 35, -229, STONE],
	# --- 5. Summit (nothing catches you)
	[22, -239, 25, -237, STONE],
	[11, -246, 14, -244, STONE],
	[2, -253, 5, -251, STONE],
	[12, -261, 14, -259, STONE],
	[22, -268, 24, -266, STONE],
	[30, -275, 35, -273, STONE],
	[14, -284, 24, -282, STONE],  # summit (the hole is cut into it)
]

# Extra blocks that are in the way rather than stood on.
const OBSTACLES := [
	[9, -130, 17, -129, STONE],  # overhang: forces a flat shot to the left
]

# Slippery rock slopes, as polygons in tile-corner coordinates
# (point (x, y) is the top-left corner of tile x, y). No friction, so the
# ball slides off them. They look like places to rest, but they aren't.
const SLOPES := [
	# Foothills: ramp on the right wall, throws overshoots back left
	[Vector2(31, -20), Vector2(36, -26), Vector2(36, -20)],
	# Cliffs: tilted "fake ledge" against the divider
	[Vector2(19, -124), Vector2(25, -128), Vector2(25, -127), Vector2(19, -123)],
	# Big Fall: wedge on the right wall, slides you into the shaft
	[Vector2(31, -203), Vector2(36, -206), Vector2(36, -203)],
	# Summit: wedge on the left wall
	[Vector2(0, -268), Vector2(6, -262), Vector2(0, -262)],
]

# The hole: these cells are left empty in the summit so the ball can drop in.
const CUP_CELLS := [Vector2i(18, -284), Vector2i(19, -284)]

const SPAWN_POS := Vector2(4 * TILE + 16, -24)
# Goal sits at the bottom of the cup (center of the two cup cells).
const GOAL_POS := Vector2(19 * TILE, -284 * TILE + 24)
const SIGN_POS := Vector2(48, -160)
const ROCK_COLOR := Color(0.25, 0.24, 0.28)


func _initialize() -> void:
	make_tile_images()
	if not ResourceLoader.exists("res://art/tiles/stone.png"):
		print("New tile images made. Open the project once (or run the editor import), then run this again.")
		quit()
		return
	var tileset := make_tileset()
	var err := ResourceSaver.save(tileset, "res://scenes/level/level_tileset.tres")
	assert(err == OK)
	build_level(load("res://scenes/level/level_tileset.tres"))
	quit()


## Shrinks Person B's big textures into 32x32 tile images in art/tiles/.
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


func build_level(tileset: TileSet) -> void:
	var level := Node2D.new()
	level.name = "Level"

	var tiles := TileMapLayer.new()
	tiles.name = "Tiles"
	tiles.tile_set = tileset
	_add(level, tiles)

	# 1. Fill every block, remembering which material each cell is.
	var cells := {}  # Vector2i -> material
	for list in [BLOCKS, ROUTE, OBSTACLES]:
		for b in list:
			for x in range(b[0], b[2] + 1):
				for y in range(b[1], b[3] + 1):
					cells[Vector2i(x, y)] = b[4]
	for c in CUP_CELLS:
		cells.erase(c)

	# 2. Earth cells with open air above get grass, the rest dirt.
	for cell in cells:
		var src := SRC_STONE
		if cells[cell] == EARTH:
			src = SRC_DIRT if cells.has(cell + Vector2i.UP) else SRC_GRASS
		tiles.set_cell(cell, src, Vector2i.ZERO)

	# 3. Slippery slopes: one StaticBody2D, each slope is a shape + a drawing.
	var slopes := StaticBody2D.new()
	slopes.name = "Slopes"
	slopes.physics_material_override = PhysicsMaterial.new()
	slopes.physics_material_override.friction = 0.0
	_add(level, slopes)
	for i in SLOPES.size():
		var points := PackedVector2Array()
		for p in SLOPES[i]:
			points.append(p * TILE)
		var shape := CollisionPolygon2D.new()
		shape.name = "Shape%d" % i
		shape.polygon = points
		_add(slopes, shape, level)
		var look := Polygon2D.new()
		look.name = "Rock%d" % i
		look.polygon = points
		look.color = ROCK_COLOR
		_add(slopes, look, level)

	# 4. SpawnPoint (contract: direct child Marker2D named "SpawnPoint").
	var spawn := Marker2D.new()
	spawn.name = "SpawnPoint"
	spawn.position = SPAWN_POS
	_add(level, spawn)

	# 5. The Goal at the bottom of the cup.
	var goal: Node2D = load("res://scenes/level/Goal.tscn").instantiate()
	goal.name = "Goal"
	goal.position = GOAL_POS
	_add(level, goal)

	# 6. A sign at the start. You never see the hole until you're close.
	var sign := Label.new()
	sign.name = "StartSign"
	sign.text = "The hole is up there somewhere.\n↑"
	sign.position = SIGN_POS
	sign.add_theme_font_size_override("font_size", 20)
	sign.add_theme_color_override("font_color", Color(1, 1, 1, 0.75))
	_add(level, sign)

	var packed := PackedScene.new()
	packed.pack(level)
	var err := ResourceSaver.save(packed, "res://scenes/level/Level.tscn")
	print("Level.tscn saved: ", err == OK, " (", cells.size(), " tiles, ", SLOPES.size(), " slopes)")
	level.free()


## Adds `child` under `parent` and marks it as part of the saved scene.
func _add(parent: Node, child: Node, scene_root: Node = null) -> void:
	parent.add_child(child)
	child.owner = scene_root if scene_root else parent
