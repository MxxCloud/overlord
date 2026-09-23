# Segugio: quadrupede veloce che salta le fosse. Il cane lo considera "suo"
# (il morso ai cavi gli fa danno doppio). Non sa classificare il cane.
extends "res://scripts/enemies/enemy.gd"


func _init() -> void:
	kind = "segugio"
	max_hp = 4.0
	speed = 110.0
	jumps_pits = true
	dps = 3.0
	morale_damage = 15
	scrap_drop = 2
	size = Vector2(44, 24)
	color = Color("3a3440")
	spawn_lines = [
		"TARGET: CANE. CLASSIFICAZIONE: ERRORE.",
		"ENTITÀ_NON_CLASSIFICATA rilevata. Riprovo.",
	]
	death_lines = ["RIPROVO... ERRORE... RIPROVO...", "Cane: ancora non classificato."]


func _draw() -> void:
	super._draw()
	# Zampe meccaniche.
	for lx in [-18, -8, 8, 18]:
		draw_line(Vector2(lx, -4), Vector2(lx - 3, 0), Color("888899"), 3)
