# Il cane (nome provvisorio: Bullone).
#
# Funziona come una piccola "macchina a stati": in ogni momento è in uno stato
# (segui, vai, morde, ferito) e si comporta di conseguenza.
#
# Abilità del prototipo (GDD §4.3):
# - Fiuto: sente i robot prima che entrino nello schermo e abbaia.
# - Vai!: clic destro su un punto vuoto. Corre lì e raccoglie i rottami.
# - Morso ai cavi: clic destro su un robot a terra. Lo raggiunge e lo stordisce
#   (un robot stordito subisce danni doppi).
# - Riporto: clic destro sulla cascina. Corre a prendere cartucce e te le porta.
extends Node2D

@export var speed := 320.0
@export var max_hp := 4.0
@export var bite_stun := 2.5           # secondi di stordimento del morso
@export var bite_damage := 1.0
@export var command_cooldown := 4.0    # attesa tra un ordine e l'altro
@export var collect_radius := 70.0
@export var ammo_fetched := 4          # cartucce portate con il Riporto

var player                             # riferimento al protagonista (lo imposta main.gd)
var hp := 4.0
var state := "segui"
var cooldown := 0.0
var incoming := 0                      # robot fiutati fuori dallo schermo
var facing := 1
var _target_x := 0.0
var _target_enemy = null
var _bark_label: Label
var _bark_time := 0.0
var _carrying := false                 # sta portando le cartucce?


func _ready() -> void:
	add_to_group("dog")
	hp = max_hp
	_bark_label = GameState.make_label("", 14)
	_bark_label.position = Vector2(-30, -60)
	_bark_label.visible = false
	add_child(_bark_label)


func is_injured() -> bool:
	return state == "ferito"


func bark(text: String) -> void:
	_bark_label.text = text
	_bark_label.visible = true
	_bark_time = 1.2


func take_damage(amount: float) -> void:
	if is_injured():
		return
	hp -= amount
	if hp <= 0:
		# Regola d'oro del GDD: il cane non muore mai. Scappa ferito e per
		# questa notte non può più aiutare.
		state = "ferito"
		bark("Kaiii!")


# Chiamata col clic destro: decide se mordere un robot o andare in un punto.
func command(pos: Vector2) -> void:
	if is_injured() or cooldown > 0:
		return
	_target_enemy = null
	# Clic sulla cascina: va a prendere le cartucce.
	if pos.x < GameState.GATE_X + 20:
		state = "riporta"
		_carrying = false
		cooldown = command_cooldown
		bark("WOOF!")
		return
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if not enemy.flying and enemy.center().distance_to(pos) < 50:
			_target_enemy = enemy
			break
	if _target_enemy != null:
		state = "morde"
	else:
		state = "vai"
		_target_x = clamp(pos.x, GameState.GATE_X, GameState.SCREEN_W - 10)
	cooldown = command_cooldown
	bark("WOOF!")


func _physics_process(delta: float) -> void:
	if GameState.finished:
		return
	cooldown = max(0.0, cooldown - delta)
	_bark_time -= delta
	if _bark_time <= 0:
		_bark_label.visible = false

	if Input.is_action_just_pressed("cane"):
		command(get_global_mouse_position())

	_sniff()

	# `match` è come una serie di if: esegue il blocco dello stato attuale.
	match state:
		"segui":
			# Resta un po' dietro al protagonista.
			_move_to(player.position.x - 50 * player.facing, delta, speed * 0.8)
		"vai":
			if _move_to(_target_x, delta, speed):
				_collect_scrap()
				state = "segui"
		"morde":
			# is_instance_valid controlla che il robot non sia già stato distrutto.
			if not is_instance_valid(_target_enemy) or _target_enemy.is_dying():
				state = "segui"
			elif _move_to(_target_enemy.position.x, delta, speed) or \
					abs(_target_enemy.position.x - position.x) < _target_enemy.size.x * 0.5 + 12:
				_bite(_target_enemy)
				state = "segui"
		"riporta":
			if not _carrying:
				if _move_to(GameState.GATE_X - 50, delta, speed):
					_carrying = true
			elif _move_to(player.position.x, delta, speed):
				player.add_ammo(ammo_fetched)
				GameState.spawn_text(position + Vector2(0, -40), "+%d cartucce" % ammo_fetched, Color("ffdd66"))
				_carrying = false
				state = "segui"
		"ferito":
			_move_to(GameState.GATE_X - 30, delta, speed * 0.4)

	# Mentre corre raccoglie i rottami su cui passa.
	if not is_injured():
		for scrap in get_tree().get_nodes_in_group("scrap"):
			if abs(scrap.position.x - position.x) < 16:
				scrap.collect()
	queue_redraw()


func _bite(enemy) -> void:
	# Il Segugio è l'unico robot che il cane considera "suo": morso doppio.
	var dmg := bite_damage * (2.0 if enemy.kind == "segugio" else 1.0)
	enemy.stun(bite_stun)
	enemy.take_damage(dmg)
	bark("GRRR!")


func _collect_scrap() -> void:
	for scrap in get_tree().get_nodes_in_group("scrap"):
		if abs(scrap.position.x - position.x) < collect_radius:
			scrap.collect()


# Fiuto: conta i robot ancora fuori dallo schermo e abbaia se ne arrivano.
func _sniff() -> void:
	var count := 0
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if enemy.position.x > GameState.SCREEN_W:
			count += 1
	if count > 0 and incoming == 0 and not is_injured():
		bark("Woof! Woof!")
	incoming = count


# Muove il cane verso x. Restituisce true quando è arrivato.
func _move_to(x: float, delta: float, spd: float) -> bool:
	var dx := x - position.x
	if abs(dx) < 6:
		return true
	facing = 1 if dx > 0 else -1
	position.x += facing * min(abs(dx), spd * delta)
	return false


func _draw() -> void:
	# Border collie placeholder: corpo nero, muso e zampe bianche.
	var f := facing
	var body := Color("555555") if is_injured() else Color("151515")
	draw_rect(Rect2(-14, -20, 28, 12), body)                        # corpo
	draw_rect(Rect2(-4, -20, 8, 12), Color("eeeeee"))               # macchia bianca
	draw_rect(Rect2(f * 12 - 6, -28, 12, 11), body)                 # testa
	draw_rect(Rect2(f * 16 - 3, -22, 7, 5), Color("eeeeee"))        # muso
	draw_rect(Rect2(f * 12 - 6, -32, 4, 5), body)                   # orecchio
	draw_line(Vector2(-f * 14, -18), Vector2(-f * 22, -26), body, 3) # coda
	if _carrying:
		draw_rect(Rect2(f * 18 - 4, -20, 8, 5), Color("c0392b"))   # scatola di cartucce in bocca
	for lx in [-11, -5, 5, 11]:
		draw_rect(Rect2(lx - 1.5, -8, 3, 8), Color("eeeeee"))       # zampe
