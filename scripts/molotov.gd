# Molotov lanciata da un abitante in postazione (ricetta di Nonna Edda).
# Vola ad arco fino al punto `target` e lì brucia i robot di terra vicini.
extends Node2D

@export var flight_time := 0.9
@export var radius := 60.0
@export var damage := 3.0

var target := Vector2.ZERO
var _start := Vector2.ZERO
var _t := 0.0
var _burning := 0.0

const BURN_TIME := 1.4   # quanto restano visibili le fiamme (il danno è istantaneo)


func _ready() -> void:
	_start = position
	add_to_group("lights")


func _physics_process(delta: float) -> void:
	if _burning > 0:
		_burning -= delta
		# Le fiamme continuano a sprigionare braci per un po'.
		if randf() < 0.6:
			GameState.fx.fire(position, 1)
		if _burning <= 0:
			queue_free()
		queue_redraw()
		return
	_t += delta / flight_time
	if _t >= 1.0:
		_explode()
		return
	# Traiettoria ad arco: interpolazione lineare più una "gobba" verso l'alto.
	position = _start.lerp(target, _t) + Vector2(0, -120 * sin(_t * PI))
	# Piccola scia di fuoco dallo straccio acceso.
	if randf() < 0.5:
		GameState.fx.fire(position, 1)
	queue_redraw()


func _explode() -> void:
	position = target
	_burning = BURN_TIME
	# Vetro che si rompe, vampata, fumo e bruciatura a terra.
	GameState.fx.flash(position + Vector2(0, -20), 80.0, Color(1.0, 0.55, 0.15, 1.0), 0.2)
	GameState.fx.fire(position, 14)
	GameState.fx.debris(position + Vector2(0, -6), [Color("5a8a3a"), Color("8ac06a")], 5)
	GameState.fx.smoke(position + Vector2(0, -20), 5)
	GameState.fx.scorch(position)
	GameState.shake(3.0)
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if not enemy.flying and enemy.position.distance_to(target) < radius:
			enemy.take_damage(damage)


func get_lights() -> Array:
	if _burning > 0:
		var flicker := randf_range(0.8, 1.0)
		return [[position + Vector2(0, -20), 150.0 * flicker, Color(1.0, 0.5, 0.15, 0.4 * _burning / BURN_TIME)]]
	return [[position, 30.0, Color(1.0, 0.6, 0.2, 0.5)]]


func _draw() -> void:
	if _burning > 0:
		# Lingue di fuoco in pixel che tremolano.
		var strength := _burning / BURN_TIME
		for i in 9:
			var x := (i - 4) * 6.0
			var h := randf_range(6.0, 30.0) * strength * (1.0 - absi(i - 4) / 6.0)
			draw_rect(Rect2(x - 3, -h, 6, h), Color(1.0, 0.45, 0.1, 0.9))
			draw_rect(Rect2(x - 1.5, -h * 0.6, 3, h * 0.6), Color(1.0, 0.85, 0.3, 0.9))
	else:
		# Bottiglia che ruota in volo.
		draw_set_transform(Vector2.ZERO, _t * TAU * 1.5, Vector2.ONE)
		draw_rect(Rect2(-4.5, -7.5, 9, 15), Color("1b1418"))
		draw_rect(Rect2(-3, -6, 6, 12), Color("5a8a3a"))
		draw_rect(Rect2(-1.5, -10.5, 3, 4.5), Color("ffaa33"))
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
