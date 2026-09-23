# Script BASE delle difese. Le difese concrete (recinto, fossa, spaventapasseri)
# lo estendono e cambiano i valori o i metodi `blocks` e `try_trap`.
extends Node2D

var label_text := "Difesa"
var max_hp := 20.0
var width := 40.0            # ingombro orizzontale in pixel
var hp := 20.0


func _ready() -> void:
	add_to_group("defenses")
	hp = max_hp


func is_alive() -> bool:
	return hp > 0


func needs_repair() -> bool:
	return hp < max_hp


func repair() -> void:
	hp = max_hp
	queue_redraw()


func take_damage(amount: float) -> void:
	if not is_alive():
		return
	hp = max(0.0, hp - amount)
	queue_redraw()


# Restituisce true se questa difesa ferma il robot `enemy`.
func blocks(_enemy) -> bool:
	return false


# Restituisce true se questa difesa intrappola il robot (solo la fossa).
func try_trap(_enemy) -> bool:
	return false


func _draw() -> void:
	# Nome e barra dello stato sotto la difesa.
	var ratio := hp / max_hp
	draw_rect(Rect2(-20, 8, 40, 4), Color("331a00"))
	draw_rect(Rect2(-20, 8, 40 * ratio, 4), Color("ffaa33"))
	draw_string(ThemeDB.fallback_font, Vector2(-60, 30), label_text, HORIZONTAL_ALIGNMENT_CENTER, 120, 12, Color("f0e0c0"))
