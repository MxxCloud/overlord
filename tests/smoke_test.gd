# Test automatico: gioca una partita accelerata con input simulati e
# controlla che non ci siano errori. Si lancia da terminale con:
#   godot --headless -s res://tests/smoke_test.gd
extends SceneTree

var _frames := 0
var _plan := ["spaventapasseri", "recinto", "fossa", "recinto"]


func _initialize() -> void:
	Engine.time_scale = 4.0
	change_scene_to_file("res://scenes/Main.tscn")


func _physics_process(_delta: float) -> bool:
	_frames += 1
	var main = current_scene
	if main == null or main.player == null:
		return false
	var gs = root.get_node("GameState")
	var slots := get_nodes_in_group("slots")
	if _frames % 30 == 0:
		# Costruisce: postazioni ai lati, difese sui sentieri; poi assegna e ripara.
		for i in slots.size():
			var slot = slots[i]
			if slot.defense == null and slot.job == "":
				slot.start_build("postazione" if not slot.on_path else _plan[i % _plan.size()])
			elif slot.defense != null and slot.job == "" and slot.defense.needs_repair():
				if gs.spend_scrap(slot.repair_cost):
					slot._start_job("ripara", slot.repair_time)
			elif slot.defense != null and slot.defense.has_method("needs_villager") and slot.defense.needs_villager():
				var v = main.find_free_villager(slot.position)
				if v != null:
					v.go_to_post(slot.defense)
		# Spara al robot più vicino e manda il cane a mordere o a raccogliere.
		var enemies := get_nodes_in_group("enemies")
		var target = null
		for e in enemies:
			if target == null or e.position.distance_to(main.player.position) < target.position.distance_to(main.player.position):
				target = e
		if target != null:
			main.player._aim = (target.center() - main.player.center()).normalized()
			main.player._shoot()
			main.dog.command(target.center())
		else:
			var scraps := get_nodes_in_group("scrap")
			if scraps.size() > 0:
				main.dog.command(scraps[0].position)
	# Senza cartucce si ritira vicino al cancello, come farebbe un giocatore.
	if main.player.shells == 0:
		main.player.position = Vector2(700, 215)
	if gs.finished or _frames > 20000:
		print("FINE: finita=%s vinta=%s morale=%d uccisi=%d rottami=%d frame=%d" % [
			gs.finished, main.player.hp > 0 and gs.morale > 0, gs.morale, gs.kills, gs.scrap, _frames])
		quit()
	return false
