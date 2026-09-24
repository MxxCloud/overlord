# Recinto rinforzato: blocca i robot di terra finché non lo distruggono.
# I droni ci volano sopra.
extends "res://scripts/defenses/defense.gd"


func _init() -> void:
	label_text = "Recinto"
	max_hp = 30.0
	width = 30.0


func blocks(enemy) -> bool:
	return is_alive() and not enemy.flying


func _draw_defense() -> void:
	# Palizzata di tronchi (sprite del pacchetto medievale).
	if not is_alive():
		# Distrutta: restano solo i monconi (la parte bassa, più scura).
		Sprites.draw_image(self, "decor/palisade", Vector2.ZERO, Color(0.6, 0.55, 0.5), Rect2(0, 11, 32, 5))
		return
	var tint := Color(1, 0.85, 0.8) if hp < max_hp * 0.5 else Color.WHITE   # rovinata: più scura
	Sprites.draw_image(self, "decor/palisade", Vector2.ZERO, tint)
