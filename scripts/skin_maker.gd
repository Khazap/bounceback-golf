extends SceneTree
## Skin maker: creates the ball skin images in art/skins/.
## A tool like level_builder.gd, not part of the game. Run it from a terminal:
##   Godot_console.exe --headless --path . --script res://scripts/skin_maker.gd
##
## - smiley.png: your smiley image (smiley_original.jpg), cut into a clean
##   circle with see-through corners (a JPG can't be see-through).
## - golf.png, beach.png, basketball.png: drawn pixel by pixel in code.
## To add your own skin: put a square PNG in art/skins/ and add it to
## SKINS in game_manager.gd.

const SIZE := 256
const C := Vector2(SIZE / 2.0, SIZE / 2.0)  # center
const R := SIZE / 2.0 - 4.0                 # radius (a little margin)


func _initialize() -> void:
	make_smiley()
	paint("golf", golf_color)
	paint("beach", beach_color)
	paint("basketball", basketball_color)
	print("Skins saved in art/skins/")
	quit()


func make_smiley() -> void:
	var img := Image.load_from_file(ProjectSettings.globalize_path("res://art/skins/smiley_original.jpg"))
	img.convert(Image.FORMAT_RGBA8)
	img.resize(SIZE, SIZE, Image.INTERPOLATE_LANCZOS)
	for x in SIZE:
		for y in SIZE:
			var col := img.get_pixel(x, y)
			col.a = edge_alpha(Vector2(x, y))  # see-through outside the circle
			img.set_pixel(x, y, col)
	img.save_png("res://art/skins/smiley.png")


## Draws a ball: for every pixel inside the circle, ask `color_at` what color it is.
func paint(name: String, color_at: Callable) -> void:
	var img := Image.create(SIZE, SIZE, false, Image.FORMAT_RGBA8)
	for x in SIZE:
		for y in SIZE:
			var p := Vector2(x, y)
			var a := edge_alpha(p)
			if a <= 0.0:
				continue
			# u, v go from -1 to 1 across the ball, (0, 0) is the center.
			var col: Color = color_at.call((p - C) / R)
			col = col.darkened(shade(p))
			if (p - C).length() > R - 5.0:  # dark outline
				col = Color(0.12, 0.1, 0.1)
			col.a = a
			img.set_pixel(x, y, col)
	img.save_png("res://art/skins/%s.png" % name)


## 1 inside the circle, 0 outside, smooth over 1.5 pixels at the edge.
func edge_alpha(p: Vector2) -> float:
	return clampf((R - (p - C).length()) / 1.5 + 0.5, 0.0, 1.0)


## A bit darker toward the bottom-right, so the ball looks round.
func shade(p: Vector2) -> float:
	var light_dir := Vector2(-0.6, -0.6)
	return clampf(((p - C) / R).dot(-light_dir) * 0.18, 0.0, 0.3)


# --- The designs. Each gets uv (-1..1) and returns a color. ------------------

func golf_color(uv: Vector2) -> Color:
	# white with little grey dimples in a staggered grid
	var cell := Vector2(0.22, 0.19)
	var row := floorf(uv.y / cell.y)
	var shifted := uv + Vector2(cell.x / 2.0 if int(row) % 2 == 0 else 0.0, 0.0)
	var inside := shifted.posmodv(cell) - cell / 2.0
	if inside.length() < 0.055:
		return Color(0.8, 0.82, 0.85)
	return Color(0.97, 0.97, 0.97)


func beach_color(uv: Vector2) -> Color:
	if uv.length() < 0.16:  # white cap in the middle
		return Color.WHITE
	var colors := [Color("#e63946"), Color.WHITE, Color("#457bff"), Color("#ffd23f"), Color.WHITE, Color("#2ec27e")]
	var slice := int(floorf((uv.angle() + PI) / TAU * 6.0)) % 6  # 6 wedges around the center
	return colors[slice]


func basketball_color(uv: Vector2) -> Color:
	var line := Color(0.15, 0.08, 0.04)
	var w := 0.035
	if absf(uv.x) < w or absf(uv.y) < w:  # the cross
		return line
	# the two curved seams: circles off to the left and right
	for side in [-1.0, 1.0]:
		if absf((uv - Vector2(side * 1.25, 0)).length() - 0.95) < w:
			return line
	return Color("#e8772e")
