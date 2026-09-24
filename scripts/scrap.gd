# Rottame lasciato da un robot distrutto: schizza fuori, rimbalza e resta
# a terra. Lo raccolgono il protagonista (passandoci sopra) o il cane.
# I rottami servono a costruire e riparare le difese.
extends Node2D

@export var value := 1

var velocity := Vector2.ZERO   # impostata da chi lo crea (l'esplosione)
var floor_y := 0.0             # la "quota" del terreno dove atterra
var _landed := false
var _time := 0.0


func _ready() -> void:
	add_to_group("scrap")
	_time = randf() * 3.0


func is_landed() -> bool:
	return _landed


func collect() -> void:
	# Si raccoglie solo quando è fermo a terra, e una volta sola.
	if not _landed or is_queued_for_deletion():
		return
	GameState.add_scrap(value)
	GameState.fx.sparks(position + Vector2(0, -6), 5, Color("e8e8f0"))
	GameState.spawn_text(position + Vector2(0, -20), "+%d rottame" % value, Color("dddddd"))
	queue_free()


func _physics_process(delta: float) -> void:
	_time += delta
	if not _landed:
		velocity.y += 900.0 * delta
		position += velocity * delta
		if position.y >= floor_y and velocity.y > 0:
			position.y = floor_y
			if velocity.y > 120.0:
				velocity = Vector2(velocity.x * 0.5, -velocity.y * 0.35)  # rimbalzo
			else:
				_landed = true
	queue_redraw()


func _draw() -> void:
	# Un piccolo ingranaggio in pixel, con un luccichio ogni tanto.
	var k := Color("1b1418")
	draw_rect(Rect2(-6, -12, 12, 12), k)
	draw_rect(Rect2(-3, -15, 6, 18), k)
	draw_rect(Rect2(-9, -9, 18, 6), k)
	draw_rect(Rect2(-3, -12, 6, 12), Color("9a9aa5"))
	draw_rect(Rect2(-6, -9, 12, 6), Color("9a9aa5"))
	draw_rect(Rect2(-1.5, -7.5, 3, 3), k)
	if fmod(_time, 2.5) < 0.12:
		draw_rect(Rect2(3, -15, 3, 3), Color.WHITE)
