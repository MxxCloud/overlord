# Proiettile sparato dai droni. È lento apposta: si può schivare muovendosi
# lungo la collina.
extends Node2D

var velocity := Vector2.ZERO
var damage := 1.0
var _life := 3.0
var _trail: Array = []   # ultime posizioni, per disegnare la scia


func _ready() -> void:
	add_to_group("lights")


func _physics_process(delta: float) -> void:
	if GameState.finished:
		queue_free()
		return
	_trail.push_front(position)
	if _trail.size() > 6:
		_trail.pop_back()
	position += velocity * delta
	_life -= delta
	var player = get_tree().get_first_node_in_group("player")
	if player != null and player.center().distance_to(position) < 18:
		player.take_damage(damage)
		GameState.fx.sparks(position, 8, Color("ff6680"))
		queue_free()
	elif position.y > GameState.GROUND_Y:
		GameState.fx.dust(Vector2(position.x, GameState.GROUND_Y), 4)
		queue_free()
	elif _life <= 0:
		queue_free()
	queue_redraw()


func get_lights() -> Array:
	return [[position, 26.0, Color(1.0, 0.15, 0.3, 0.6)]]


func _draw() -> void:
	# Scia che sfuma (le posizioni sono salvate in coordinate del mondo).
	for i in _trail.size():
		var p: Vector2 = _trail[i] - position
		var alpha := 0.5 * (1.0 - i / 6.0)
		draw_rect(Rect2(p - Vector2(1.5, 1.5), Vector2(3, 3)), Color(1.0, 0.3, 0.4, alpha))
	draw_rect(Rect2(-4.5, -4.5, 9, 9), Color("ff3355"))
	draw_rect(Rect2(-1.5, -1.5, 3, 3), Color("ffd0dd"))
