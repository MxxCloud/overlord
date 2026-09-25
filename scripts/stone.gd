# Sasso tirato dalla Fionda: insegue il drone bersaglio e lo colpisce.
extends Node2D

@export var speed := 520.0
@export var damage := 1.5

var target = null
static var hits := 0   # sassi andati a segno (lo usa il test automatico)


func _physics_process(delta: float) -> void:
	if GameState.finished or not is_instance_valid(target) or target.is_dying():
		queue_free()
		return
	var aim: Vector2 = target.center()
	var diff := aim - position
	if diff.length() < 12.0:
		hits += 1
		target.take_damage(damage)
		GameState.fx.sparks(position, 6, Color("dddddd"))
		queue_free()
		return
	position += diff.limit_length(speed * delta)
	rotation += delta * 20.0


func _draw() -> void:
	draw_rect(Rect2(-4.5, -4.5, 9, 9), Color("1b1418"))
	draw_rect(Rect2(-3, -3, 6, 6), Color("9aa0a8"))
	draw_rect(Rect2(-3, -3, 3, 3), Color("c8cdd4"))
