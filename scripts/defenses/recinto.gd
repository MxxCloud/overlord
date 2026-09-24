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
	if not is_alive():
		# Distrutto: restano i monconi.
		for px in [-15, 0, 12]:
			block(Rect2(px - 3, -12 - absf(px) * 0.3, 6, 12 + absf(px) * 0.3), Color("4a3420"))
		return
	var wood := Color("7a5530")
	var damaged := hp < max_hp * 0.5
	for px in [-15, 0, 15]:
		block(Rect2(px - 3, -63, 6, 63), wood)
		block(Rect2(px - 3, -66, 6, 3), Color("9a7040"))   # punta
	block(Rect2(-18, -48, 36, 6), Color("8a6538"))
	# Mezzo rotto: l'asse bassa è storta.
	if damaged:
		draw_line(Vector2(-18, -18), Vector2(18, -30), K, 8)
		draw_line(Vector2(-18, -18), Vector2(18, -30), Color("8a6538"), 5)
	else:
		block(Rect2(-18, -24, 36, 6), Color("8a6538"))
