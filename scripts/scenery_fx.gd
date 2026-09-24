# Parti animate dello sfondo: stelle che brillano, luci rosse sulle antenne
# della città, fari che spazzano il cielo, pale del mulino, fumo dal comignolo.
extends Node2D

var background   # riferimento a background.gd (per le posizioni di antenne e stelle)
var _time := 0.0
var _smoke_cd := 0.0


func _ready() -> void:
	z_index = -19            # appena sopra lo sfondo
	add_to_group("lights")


func _process(delta: float) -> void:
	_time += delta
	# Fumo dal comignolo della cascina.
	_smoke_cd -= delta
	if _smoke_cd <= 0 and GameState.fx != null:
		_smoke_cd = 0.5
		GameState.fx.smoke(Vector2(76, 462), 1)
	queue_redraw()


func _draw() -> void:
	# Fari della città: coni di luce che oscillano lentamente.
	for i in background.spire_tops.size():
		var top: Vector2 = background.spire_tops[i]
		var angle := -PI / 2 + sin(_time * 0.4 + i * 2.1) * 0.6
		var dir := Vector2(cos(angle), sin(angle))
		var side := Vector2(-dir.y, dir.x) * 70.0
		var far := top + dir * 520.0
		draw_colored_polygon(PackedVector2Array([top, far + side, far - side]), Color(0.5, 0.75, 1.0, 0.07))

	# Stelle che brillano (alcune cambiano luminosità).
	for i in range(0, background.stars.size(), 4):
		var star: Array = background.stars[i]
		var twinkle := 0.5 + 0.5 * sin(_time * 2.0 + i)
		draw_rect(Rect2(star[0], Vector2(3, 3)), Color(1, 1, 0.9, star[1] * twinkle))

	# Luci rosse lampeggianti sulle antenne.
	for i in background.antenna_tops.size():
		if _antenna_on(i):
			draw_rect(Rect2(background.antenna_tops[i] + Vector2(0, -3), Vector2(3, 3)), Color("ff3030"))

	_draw_windmill(Vector2(174, 600))


func _antenna_on(i: int) -> bool:
	return fmod(_time + i * 0.37, 1.6) < 0.5


func _draw_windmill(base: Vector2) -> void:
	var k := Color("1b1418")
	var wood := Color("4a3a2a")
	var hub := base + Vector2(0, -120)
	# Traliccio.
	draw_line(base + Vector2(-15, 0), hub, k, 5)
	draw_line(base + Vector2(15, 0), hub, k, 5)
	draw_line(base + Vector2(-15, 0), hub, wood, 3)
	draw_line(base + Vector2(15, 0), hub, wood, 3)
	for y in [30, 60, 90]:
		var half: float = 15.0 * (1.0 - y / 120.0)
		draw_line(base + Vector2(-half, -y), base + Vector2(half, -y), wood, 2)
	# Pale che girano lentamente.
	for i in 8:
		var angle := _time * 0.8 + i * TAU / 8.0
		var tip := hub + Vector2(cos(angle), sin(angle)) * 30.0
		draw_line(hub, tip, k, 5)
		draw_line(hub, tip, Color("8a8070"), 3)
	draw_rect(Rect2(hub - Vector2(4, 4), Vector2(8, 8)), k)
	# Coda del mulino.
	draw_line(hub, hub + Vector2(-24, 3), k, 3)
	draw_rect(Rect2(hub + Vector2(-33, -6), Vector2(12, 15)), Color("5a4a3a"))


func get_lights() -> Array:
	var lights := []
	for i in background.antenna_tops.size():
		if _antenna_on(i):
			lights.append([background.antenna_tops[i], 14.0, Color(1.0, 0.1, 0.1, 0.5)])
	return lights
