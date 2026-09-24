# Fossa con pali: i robot leggeri di terra ci cadono dentro e restano
# intrappolati (bersagli facili). Ha una capienza: quando è piena i robot
# camminano sopra i compagni. Riparare = svuotarla.
# Il Segugio la salta, i droni la sorvolano.
extends "res://scripts/defenses/defense.gd"


func _init() -> void:
	label_text = "Fossa"
	max_hp = 3.0   # qui la "vita" è la capienza: quanti robot può contenere
	width = 50.0


func try_trap(enemy) -> bool:
	if not is_alive() or enemy.flying or enemy.jumps_pits or enemy.trapped:
		return false
	if not path_progress.has(enemy.path_id) or absf(path_progress[enemy.path_id] - enemy.progress) > 8:
		return false
	take_damage(1.0)
	enemy.position = position + Vector2(randf_range(-10, 10), 6)
	GameState.fx.dust(position, 10)
	GameState.fx.sparks(position + Vector2(0, -10), 6)
	GameState.shake(3.0)
	GameState.spawn_text(position + Vector2(0, -60), "Nella fossa!", Color("ffdd66"))
	return true


func _hit_fx(pos: Vector2) -> void:
	GameState.fx.dust(Vector2(pos.x, position.y), 3)


func _on_destroyed() -> void:
	# Fossa piena: niente esplosione, solo un avviso.
	GameState.spawn_text(position + Vector2(0, -80), "Fossa piena!", Color("ff9966"))


func _draw_defense() -> void:
	# Buca scavata nel sentiero, con i pali appuntiti sul fondo.
	Sprites.draw_image(self, "decor/pit", Vector2(0, 21))
	for px in [-12, 0, 12]:
		draw_rect(Rect2(px - 1.5, -9, 3, 12), Color("6b4a2a"))
		draw_rect(Rect2(px - 1.5, -12, 3, 3), Color("d8c090"))
