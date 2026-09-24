# Cielo notturno e megalopoli all'orizzonte (sopra il villaggio): stelle che
# brillano, grattacieli con finestre e neon, luci rosse sulle antenne e fari
# che spazzano il cielo. Non viene tinto dalla "notte" del mondo.
extends Node2D

const PX := 3
const HORIZON := 130.0

var antenna_tops: Array = []
var spire_tops: Array = []
var stars: Array = []
var _buildings: Array = []   # [x, larghezza, altezza, finestre]
var _time := 0.0


func _ready() -> void:
	z_index = -19
	add_to_group("lights")
	_generate()


func _generate() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 3
	for i in 45:
		stars.append([Vector2(rng.randi_range(0, 426) * PX, rng.randi_range(0, 24) * PX), rng.randf_range(0.25, 0.9)])
	rng.seed = 11
	var x := 0.0
	while x < 1280:
		var w := float(rng.randi_range(5, 12) * PX)
		var peak := 70.0 * exp(-pow((x - 900.0) / 180.0, 2)) + 40.0 * exp(-pow((x - 300.0) / 120.0, 2))
		var h := rng.randf_range(12, 40) + peak * rng.randf_range(0.6, 1.0)
		var windows := []
		for wy in range(int(HORIZON - h) + 6, int(HORIZON) - 2, 9):
			if rng.randf() < 0.18:
				windows.append([Vector2(x + 3 + rng.randi_range(0, int(w / 9)) * 6, wy), rng.randf() < 0.7])
		_buildings.append([x, w, h, windows])
		if h > 70:
			var ax := x + floorf(w / 6.0) * PX
			antenna_tops.append(Vector2(ax, HORIZON - h - 9))
			if h > 95:
				spire_tops.append(Vector2(x + w * 0.5, HORIZON - h - 9))
		x += w + rng.randi_range(0, 2) * PX


func _process(delta: float) -> void:
	_time += delta
	queue_redraw()


func _draw() -> void:
	# Cielo a fasce: dal blu notte al viola, con un bagliore rosso della città.
	var gradient := Gradient.new()
	gradient.set_color(0, Color("080818"))
	gradient.set_color(1, Color("5a2a44"))
	gradient.add_point(0.55, Color("1c1636"))
	for y in range(0, int(HORIZON) + 6, PX):
		draw_rect(Rect2(0, y, 1280, PX), gradient.sample(y / HORIZON))
	for i in stars.size():
		var star: Array = stars[i]
		var twinkle := 0.6 + 0.4 * sin(_time * 2.0 + i) if i % 3 == 0 else 1.0
		draw_rect(Rect2(star[0], Vector2(PX, PX)), Color(1, 1, 0.9, star[1] * twinkle))

	# Fari della città: coni di luce che oscillano lentamente.
	for i in spire_tops.size():
		var top: Vector2 = spire_tops[i]
		var angle := -PI / 2 + sin(_time * 0.4 + i * 2.1) * 0.6
		var dir := Vector2(cos(angle), sin(angle))
		var side := Vector2(-dir.y, dir.x) * 60.0
		var far := top + dir * 400.0
		draw_colored_polygon(PackedVector2Array([top, far + side, far - side]), Color(0.5, 0.75, 1.0, 0.06))

	# Grattacieli con finestre accese e strisce di neon.
	for b in _buildings:
		var bx: float = b[0]
		var bw: float = b[1]
		var bh: float = b[2]
		draw_rect(Rect2(bx, HORIZON - bh, bw, bh + 6), Color("120f1d"))
		draw_rect(Rect2(bx + bw - PX, HORIZON - bh, PX, bh + 6), Color("1d1830"))
		if bh > 70:
			draw_rect(Rect2(bx + floorf(bw / 6.0) * PX, HORIZON - bh - 9, PX, 9), Color("120f1d"))
			draw_rect(Rect2(bx + floorf(bw / 6.0) * PX, HORIZON - bh + 6, PX, bh * 0.5), Color("3aa0ff"))
		for w in b[3]:
			draw_rect(Rect2(w[0], Vector2(PX, PX)), Color("4aa8ff") if w[1] else Color("f2c96a"))

	# Luci rosse lampeggianti sulle antenne.
	for i in antenna_tops.size():
		if _antenna_on(i):
			draw_rect(Rect2(antenna_tops[i] + Vector2(0, -3), Vector2(PX, PX)), Color("ff3030"))

	# Nebbiolina sul ciglio della collina.
	for i in 5:
		draw_rect(Rect2(0, HORIZON - 12 + i * 3, 1280, 3), Color(0.5, 0.4, 0.6, 0.06 + i * 0.03))


func _antenna_on(i: int) -> bool:
	return fmod(_time + i * 0.37, 1.6) < 0.5


func get_lights() -> Array:
	var lights := []
	for i in antenna_tops.size():
		if _antenna_on(i):
			lights.append([antenna_tops[i], 14.0, Color(1.0, 0.1, 0.1, 0.5)])
	return lights
