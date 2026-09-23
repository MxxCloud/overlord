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


func _ready() -> void:
	_start = position


func _physics_process(delta: float) -> void:
	if _burning > 0:
		_burning -= delta
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
	queue_redraw()


func _explode() -> void:
	position = target
	_burning = 0.6
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if not enemy.flying and abs(enemy.position.x - target.x) < radius:
			enemy.take_damage(damage)


func _draw() -> void:
	if _burning > 0:
		draw_circle(Vector2(0, -10), radius * 0.6, Color(1.0, 0.5, 0.1, 0.5))
		draw_circle(Vector2(0, -6), radius * 0.3, Color(1.0, 0.85, 0.3, 0.8))
	else:
		draw_rect(Rect2(-3, -6, 6, 10), Color("5a8a3a"))
		draw_circle(Vector2(0, -8), 3, Color("ffaa33"))
