# Sfondo statico della collina di notte: cielo, stelle, luna, montagne,
# megalopoli all'orizzonte, colline, prato, cascina e cancello.
#
# Viene disegnato UNA volta sola (Godot memorizza il risultato), con
# rettangoli allineati a una griglia di 3 pixel per avere l'aspetto
# "pixel art" coerente con gli sprite.
# Le parti animate (stelle che brillano, luci della città, mulino) sono in
# scenery_fx.gd.
extends Node2D

const PX := 3

# Punti calcolati qui e usati da scenery_fx.gd per le animazioni.
var antenna_tops: Array = []   # luci rosse lampeggianti sulle antenne
var spire_tops: Array = []     # fari che spazzano il cielo
var stars: Array = []          # [posizione, luminosità]


func _ready() -> void:
	z_index = -20            # dietro a tutto
	add_to_group("lights")   # le finestre della cascina fanno luce


# Rettangolo allineato alla griglia di pixel.
func _px(x: float, y: float, w: float, h: float, color: Color) -> void:
	var gx := floorf(x / PX) * PX
	var gy := floorf(y / PX) * PX
	draw_rect(Rect2(gx, gy, maxf(PX, roundf(w / PX) * PX), maxf(PX, roundf(h / PX) * PX)), color)


func _draw() -> void:
	_draw_sky()
	_draw_moon(Vector2(246, 111), 24)
	_draw_ridge(470.0, 62.0, 0.006, 1.0, 22.0, 0.017, Color("231a33"))   # montagne lontane
	_draw_city()
	_draw_ridge(528.0, 16.0, 0.004, 0.0, 10.0, 0.011, Color("1b2420"))   # colline in mezzo
	_draw_fog()
	_draw_near_hill()
	_draw_ground()
	_draw_farmhouse()
	_draw_gate()
	_draw_signpost(Vector2(1224, 600))


func _draw_sky() -> void:
	var gradient := Gradient.new()
	gradient.set_color(0, Color("0a0a1a"))
	gradient.set_color(1, Color("9a4838"))
	gradient.add_point(0.45, Color("1d1535"))
	gradient.add_point(0.75, Color("3b1f3f"))
	gradient.add_point(0.9, Color("6b2d3c"))
	for y in range(0, 480, PX):
		draw_rect(Rect2(0, y, 1280, PX), gradient.sample(y / 480.0))
	# Stelle (solo nella parte alta del cielo).
	var rng := RandomNumberGenerator.new()
	rng.seed = 3
	stars.clear()
	for i in 80:
		var pos := Vector2(rng.randi_range(0, 426) * PX, rng.randi_range(0, 100) * PX)
		if pos.distance_to(Vector2(246, 111)) < 40:
			continue
		var bright := rng.randf_range(0.25, 0.9)
		stars.append([pos, bright])
		draw_rect(Rect2(pos, Vector2(PX, PX)), Color(1, 1, 0.9, bright))


func _draw_moon(center: Vector2, radius: int) -> void:
	for y in range(-radius, radius + 1, PX):
		for x in range(-radius, radius + 1, PX):
			if Vector2(x, y).length() > radius:
				continue
			var color := Color("efe4c4")
			if Vector2(x + 9, y - 6).length() < radius * 0.95:
				color = Color("f7efd8")          # parte illuminata
			else:
				color = Color("cbbd9c")          # bordo in ombra
			draw_rect(Rect2(center + Vector2(x, y), Vector2(PX, PX)), color)
	# Crateri.
	_px(center.x - 9, center.y - 3, 6, 6, Color("d8cba8"))
	_px(center.x + 6, center.y + 6, 9, 6, Color("d8cba8"))
	_px(center.x - 3, center.y + 12, 3, 3, Color("d8cba8"))


# Una fila di colline/montagne: il profilo è una somma di onde (seni).
func _draw_ridge(base: float, amp1: float, freq1: float, phase: float, amp2: float, freq2: float, color: Color) -> void:
	for x in range(0, 1280, PX):
		var top := base - amp1 * (0.5 + 0.5 * sin(x * freq1 + phase)) - amp2 * sin(x * freq2)
		_px(x, top, PX, 600 - top, color)


func _draw_city() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 11
	antenna_tops.clear()
	spire_tops.clear()
	var x := 594.0
	while x < 1280:
		var w := float(rng.randi_range(6, 15) * PX)
		# I grattacieli sono più alti verso il centro della città (x ~ 1060).
		var peak := 230.0 * exp(-pow((x - 1060.0) / 150.0, 2))
		var h := rng.randf_range(50, 150) * clampf((x - 560.0) / 500.0, 0.3, 1.0) + peak * rng.randf_range(0.6, 1.0)
		var top := 480.0 - h
		_px(x, top, w, 560 - top, Color("14111f"))
		_px(x + w - PX, top, PX, 560 - top, Color("1f1a30"))          # bordo illuminato
		# Finestre accese (poche: la città è "ripulita").
		var wy := top + 9
		while wy < 520:
			var wx := x + 6
			while wx < x + w - 6:
				if rng.randf() < 0.10:
					var lit := Color("f2c96a") if rng.randf() < 0.25 else Color("4aa8ff")
					lit.a = rng.randf_range(0.5, 0.9)
					_px(wx, wy, PX, PX, lit)
				wx += 9
			wy += 9
		# Strisce di neon blu sui palazzi più alti (come nell'immagine di riferimento).
		if h > 180 and rng.randf() < 0.7:
			_px(x + floorf(w / (2 * PX)) * PX, top + 12, PX, h * rng.randf_range(0.3, 0.7), Color("3aa0ff"))
		# Antenne.
		if h > 150:
			var antenna := rng.randi_range(4, 12) * PX
			_px(x + floorf(w / (2 * PX)) * PX, top - antenna, PX, antenna, Color("14111f"))
			antenna_tops.append(Vector2(x + floorf(w / (2 * PX)) * PX, top - antenna))
			if h > 260:
				spire_tops.append(Vector2(x + w * 0.5, top - antenna))
		x += w + rng.randi_range(0, 3) * PX


func _draw_fog() -> void:
	for i in 8:
		var y := 504 + i * PX * 2
		draw_rect(Rect2(0, y, 1280, PX * 2), Color(0.55, 0.4, 0.6, 0.05 + i * 0.012))


func _draw_near_hill() -> void:
	# La collina del protagonista, più alta a sinistra (dove c'è la cascina).
	for x in range(0, 1280, PX):
		var top := 600.0 - 42.0 * clampf(1.0 - x / 520.0, 0.0, 1.0)
		_px(x, top, PX, 600 - top + PX, Color("243620"))


func _draw_ground() -> void:
	# Prato: striscia d'erba chiara in cima, terra scura sotto.
	_px(0, 600, 1280, 120, Color("1d2a16"))
	_px(0, 600, 1280, 9, Color("2f4623"))
	_px(0, 609, 1280, 6, Color("263a1d"))
	var rng := RandomNumberGenerator.new()
	rng.seed = 5
	for i in 260:
		var x := rng.randi_range(0, 426) * PX
		var y := rng.randi_range(203, 238) * PX
		_px(x, y, PX, PX, Color("2a3d1f") if rng.randf() < 0.6 else Color("172212"))
	# Ciuffi d'erba sulla linea del terreno.
	for i in 120:
		var x := rng.randi_range(0, 426) * PX
		_px(x, 597, PX, PX, Color("3d5a2c"))
		if rng.randf() < 0.4:
			_px(x, 594, PX, PX, Color("4d6b34"))
	# Qualche fiorellino, solo vicino al bordo del prato.
	for i in 18:
		var x := rng.randi_range(0, 426) * PX
		_px(x, 603, PX, PX, [Color("8a7aa0"), Color("a09860")][i % 2])


func _draw_farmhouse() -> void:
	var k := Color("1b1418")
	# Comignolo.
	_px(69, 468, 15, 30, k)
	_px(72, 471, 9, 27, Color("5b5249"))
	# Muri di pietra con contorno.
	_px(6, 513, 96, 87, k)
	_px(9, 516, 90, 84, Color("6e6358"))
	for row in 14:
		var offset := 0 if row % 2 == 0 else 9
		for col in 6:
			var sx := 9 + offset + col * 18
			if sx < 96:
				_px(sx, 516 + row * 6, 12, 3, Color("7d7266") if (row + col) % 3 else Color("5f564c"))
	# Tetto a gradini.
	for i in 15:
		var y := 510 - i * PX
		var inset := i * 4
		_px(0 + inset, y, 108 - inset * 2, PX, k if i == 14 else (Color("7e3326") if i % 2 else Color("6b2a20")))
	_px(0, 510, 108, PX, k)
	# Finestre illuminate.
	for wx in [21, 69]:
		_px(wx - 3, 531, 24, 24, k)
		_px(wx, 534, 18, 18, Color("ffcc55"))
		_px(wx + 7, 534, 3, 18, Color("7a5530"))
		_px(wx, 541, 18, 3, Color("7a5530"))
	# Porta.
	_px(42, 561, 21, 39, k)
	_px(45, 564, 15, 36, Color("4a3320"))
	_px(54, 582, 3, 3, Color("c9a050"))


func _draw_gate() -> void:
	var gx := GameState.GATE_X
	var wood := Color("6b4a2a")
	var k := Color("1b1418")
	for post in [gx - 6, gx + 27]:
		_px(post - 3, 534, 15, 66, k)
		_px(post, 537, 9, 63, wood)
	for bar_y in [546, 570]:
		_px(gx - 6, bar_y - 3, 42, 12, k)
		_px(gx - 6, bar_y, 42, 6, Color("8a6538"))
	# Cartello "Quietville" sopra il cancello.
	_px(gx - 21, 504, 72, 27, k)
	_px(gx - 18, 507, 66, 21, Color("5a3d22"))
	draw_string(ThemeDB.fallback_font, Vector2(gx - 18, 522), "Quietville", HORIZONTAL_ALIGNMENT_CENTER, 66, 11, Color("f0dcb0"))


func _draw_signpost(pos: Vector2) -> void:
	var k := Color("1b1418")
	_px(pos.x - 3, pos.y - 60, 9, 60, k)
	_px(pos.x, pos.y - 57, 3, 57, Color("6b4a2a"))
	_px(pos.x - 36, pos.y - 57, 78, 21, k)
	_px(pos.x - 33, pos.y - 54, 72, 15, Color("7a5530"))
	draw_string(ThemeDB.fallback_font, Vector2(pos.x - 33, pos.y - 42), "Città 30 km ›", HORIZONTAL_ALIGNMENT_CENTER, 72, 10, Color("f0dcb0"))


# Luce calda dalle finestre della cascina.
func get_lights() -> Array:
	return [
		[Vector2(30, 543), 60.0, Color(1.0, 0.7, 0.3, 0.35)],
		[Vector2(78, 543), 60.0, Color(1.0, 0.7, 0.3, 0.35)],
	]
