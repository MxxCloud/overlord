# Spaventapasseri di latta: i sensori dei robot lo scambiano per un umano.
# Tutti i robot, anche i droni, si fermano ad attaccarlo finché non cade.
# Poca vita: serve a guadagnare tempo e a raggruppare i nemici per la doppietta.
extends "res://scripts/defenses/defense.gd"


func _init() -> void:
	label_text = "Spaventapasseri"
	max_hp = 20.0
	width = 24.0


func blocks(_enemy) -> bool:
	return is_alive()


func _hit_fx(pos: Vector2) -> void:
	GameState.fx.straw(pos, 4)
	GameState.fx.sparks(pos, 3)   # la latta sfrigola


func _draw_defense() -> void:
	if not is_alive():
		# A terra: latta e paglia sparse.
		block(Rect2(-15, -6, 30, 6), Color("5a5f68"))
		block(Rect2(9, -9, 12, 3), Color("c9a86a"))
		return
	block(Rect2(-3, -72, 6, 72), Color("7a5530"))            # palo
	block(Rect2(-24, -57, 48, 6), Color("7a5530"))           # braccia
	block(Rect2(-12, -60, 24, 30), Color("8a8f98"))          # corpo di latta
	draw_rect(Rect2(-12, -48, 24, 3), Color("6a6f78"))
	block(Rect2(-9, -81, 18, 18), Color("c9a86a"))           # testa di paglia
	draw_rect(Rect2(-6, -75, 3, 3), K)                       # occhi cuciti
	draw_rect(Rect2(3, -75, 3, 3), K)
	block(Rect2(-15, -87, 30, 6), Color("5a4020"))           # cappello
	block(Rect2(-9, -96, 18, 9), Color("5a4020"))
	# Paglia che esce dalle maniche.
	draw_rect(Rect2(-30, -57, 6, 6), Color("d8b860"))
	draw_rect(Rect2(24, -57, 6, 6), Color("d8b860"))
