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
	if abs(enemy.position.x - position.x) > 8:
		return false
	take_damage(1.0)
	enemy.position = position + Vector2(randf_range(-10, 10), 18)
	GameState.spawn_text(position + Vector2(0, -60), "Nella fossa!", Color("ffdd66"))
	return true


func _draw() -> void:
	draw_rect(Rect2(-width * 0.5, 0, width, 24), Color("1a120a"))
	for px in [-18, -6, 6, 18]:
		draw_line(Vector2(px, 24), Vector2(px, 8), Color("b08a50"), 3)
	super._draw()
