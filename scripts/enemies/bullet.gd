# Proiettile sparato dai droni. È lento apposta: si può schivare muovendosi
# o saltando.
extends Node2D

var velocity := Vector2.ZERO
var damage := 1.0
var _life := 3.0


func _physics_process(delta: float) -> void:
	if GameState.finished:
		queue_free()
		return
	position += velocity * delta
	_life -= delta
	var player = get_tree().get_first_node_in_group("player")
	if player != null and player.center().distance_to(position) < 18:
		player.take_damage(damage)
		queue_free()
	elif _life <= 0 or position.y > GameState.GROUND_Y:
		queue_free()
	queue_redraw()


func _draw() -> void:
	draw_circle(Vector2.ZERO, 4, Color("ff3355"))
	draw_circle(Vector2.ZERO, 2, Color("ffccdd"))
