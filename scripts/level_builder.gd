extends SceneTree
## Level builder: writes scenes/level/Level.tscn from the layout below.
## It is a tool for us, not part of the game. Run it from a terminal:
##   Godot_console.exe --headless --path . --script res://scripts/level_builder.gd
## Change the BLOCKS list, run it again, and Level.tscn is rebuilt.
## (Painting tiles by hand in the editor also works, but re-running this
## script overwrites hand-painted changes.)

const TILE := 32
const TOP := -185  # top row of the playable area (negative Y = up)

# Materials. "earth" becomes grass on top and dirt underneath.
const EARTH := "earth"
const STONE := "stone"

# Tile sources in the TileSet.
const SRC_GRASS := 0
const SRC_DIRT := 1
const SRC_STONE := 2

# Every block is [x1, top_row, x2, bottom_row, material] in tiles.
# x goes 0..53 inside the walls. Rows are negative going up.
# "route" blocks are the intended path, in climbing order (used by tests).
const BLOCKS := [
	# --- Frame: floor, walls, ceiling (extra thick so the camera never shows the void)
	[-18, 0, 71, 12, EARTH],
	[-18, TOP, -1, 0, STONE],
	[54, TOP, 71, 0, STONE],
	[-18, TOP - 12, 71, TOP - 1, STONE],
	# Low mound in the bottom right, just scenery
	[44, -3, 53, -1, EARTH],
	[48, -6, 53, -4, EARTH],
]

# The climb, bottom to top. Same format. Order matters (it's the route).
const ROUTE := [
	# --- 1. Meadow: wide grassy ledges, small steps (5 tiles up)
	[14, -5, 25, -3, EARTH],
	[31, -10, 42, -8, EARTH],
	[45, -15, 53, -13, EARTH],
	[30, -20, 40, -18, EARTH],
	[16, -25, 26, -23, EARTH],
	[2, -30, 12, -28, EARTH],
	[18, -35, 28, -33, EARTH],
	[34, -40, 44, -38, EARTH],
	# --- 2. Dirt canyon: narrower ledges, bigger steps (6-7 up), a pillar
	[47, -46, 53, -44, EARTH],
	[36, -53, 41, -51, EARTH],
	[24, -60, 29, -50, EARTH],  # tall pillar, you land on its top
	[12, -66, 17, -64, EARTH],
	[0, -72, 5, -70, EARTH],
	[11, -79, 16, -77, EARTH],
	[23, -86, 28, -84, EARTH],
	# --- 3. Stone cliffs: tiny ledges, an overhang, long falls if you miss
	[36, -93, 39, -91, STONE],
	[47, -100, 50, -98, STONE],
	[36, -108, 39, -106, STONE],
	[21, -114, 25, -112, STONE],
	[9, -121, 12, -119, STONE],
	[0, -128, 3, -126, STONE],
	[9, -135, 13, -133, STONE],
	# --- 4. The chimney: squeeze in under its wall, zigzag up to the hole
	[22, -141, 28, -139, STONE],
	[32, -149, 37, -147, STONE],
	[21, -157, 26, -155, STONE],
	[32, -165, 37, -163, STONE],
	[18, -173, 28, -171, STONE],  # summit (the hole is cut into it)
]

# Extra obstacles that are not ledges you need to stand on.
const OBSTACLES := [
	[37, -117, 46, -116, STONE],  # overhang: no straight-up shot from below
	[18, -170, 20, -145, STONE],  # chimney left wall (holds up the summit)
	[38, -170, 40, -145, STONE],  # chimney right wall
]

# The hole: these cells are left empty in the summit so the ball can drop in.
const CUP_CELLS := [Vector2i(22, -173), Vector2i(23, -173)]

const SPAWN_POS := Vector2(4 * TILE + 16, -24)
# Goal sits at the bottom of the cup (center of the two cup cells).
const GOAL_POS := Vector2(23 * TILE, -173 * TILE + 24)
const SIGN_POS := Vector2(48, -160)


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
	level.add_child(tiles)
	tiles.owner = level

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

	# 3. SpawnPoint (contract: direct child Marker2D named "SpawnPoint").
	var spawn := Marker2D.new()
	spawn.name = "SpawnPoint"
	spawn.position = SPAWN_POS
	level.add_child(spawn)
	spawn.owner = level

	# 4. The Goal at the bottom of the cup.
	var goal: Node2D = load("res://scenes/level/Goal.tscn").instantiate()
	goal.name = "Goal"
	goal.position = GOAL_POS
	level.add_child(goal)
	goal.owner = level

	# 5. A sign at the start. You never see the hole until you're close.
	var sign := Label.new()
	sign.name = "StartSign"
	sign.text = "The hole is up there somewhere.\n↑"
	sign.position = SIGN_POS
	sign.add_theme_font_size_override("font_size", 20)
	sign.add_theme_color_override("font_color", Color(1, 1, 1, 0.75))
	level.add_child(sign)
	sign.owner = level

	var packed := PackedScene.new()
	packed.pack(level)
	var err := ResourceSaver.save(packed, "res://scenes/level/Level.tscn")
	print("Level.tscn saved: ", err == OK, " (", cells.size(), " tiles)")
	level.free()
