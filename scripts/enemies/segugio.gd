# Segugio: quadrupede veloce che salta le fosse. Il cane lo considera "suo"
# (il morso ai cavi gli fa danno doppio). Non sa classificare il cane.
extends "res://scripts/enemies/enemy.gd"


func _init() -> void:
	kind = "segugio"
	max_hp = 8.0
	speed = 60.0
	jumps_pits = true
	dps = 3.0
	morale_damage = 15
	scrap_drop = 3
	sheet = "characters/segugio"
	frame_time = 0.1    # zampe veloci
	eye_height = 22.0
	color = Color("707a88")
	spawn_lines = [
		"TARGET: CANE. CLASSIFICAZIONE: ERRORE.",
		"ENTITÀ_NON_CLASSIFICATA rilevata. Riprovo.",
	]
	death_lines = ["RIPROVO... ERRORE... RIPROVO...", "Cane: ancora non classificato."]

