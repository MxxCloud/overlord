# Test automatico: gioca una partita accelerata con input simulati e
# controlla che non ci siano errori. Si lancia da terminale con:
#   godot --headless -s res://tests/smoke_test.gd
extends SceneTree

var _frames := 0


func _initialize() -> void:
	Engine.time_scale = 4.0
	change_scene_to_file("res://scenes/Main.tscn")


func _physics_process(_delta: float) -> bool:
	_frames += 1
	var main = current_scene
	if main == null or main.player == null:
		return false
	# Ogni tanto spara verso il robot più vicino e manda il cane a mordere.
	var enemies := get_nodes_in_group("enemies")
	if enemies.size() > 0 and _frames % 20 == 0:
		var target = enemies[0]
		main.player._aim = (target.center() - main.player.center()).normalized()
		main.player._shoot()
		main.dog.command(target.center())
	# Ogni tanto manda il cane a prendere cartucce alla cascina.
	if _frames % 300 == 0:
		main.dog.command(Vector2(60, 580))
	if _frames % 50 == 0:
		main.player._fork()
		main.player._repair()
	var gs = root.get_node("GameState")
	if gs.finished or _frames > 20000:
		print("vita=%s FINE: finita=%s morale=%d uccisi=%d rottami=%d frame=%d" % [
			main.player.hp, gs.finished, gs.morale, gs.kills, gs.scrap, _frames])
		quit()
	return false
