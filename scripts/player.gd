# Il protagonista: si muove, salta, spara con la doppietta e usa il forcone.
#
# Per semplicità non usiamo il motore fisico di Godot: gravità e terreno sono
# calcolati a mano (il terreno è la linea GameState.GROUND_Y).
# L'origine del nodo (position) corrisponde ai PIEDI del personaggio.
extends Node2D

# @export rende la variabile modificabile dall'editor (pannello Ispettore).
# Sono i numeri su cui giocare per bilanciare il gioco.
@export var speed := 230.0
@export var jump_velocity := -430.0
@export var gravity := 1100.0
@export var max_hp := 10.0
@export var shotgun_range := 360.0      # portata della doppietta in pixel
@export var shotgun_spread_deg := 12.0  # apertura del cono di pallini
@export var shotgun_damage := 2.5       # danno a bruciapelo; da lontano cala molto
@export var reload_time := 1.8
@export var max_reserve := 12           # cartucce di scorta che puoi portare
@export var fork_damage := 0.5          # il forcone serve a RESPINGERE, non a uccidere
@export var fork_knockback := 80.0
@export var fork_range := 60.0
@export var fork_cooldown := 0.9
@export var refill_interval := 0.6      # alla cascina: 1 cartuccia ogni tot secondi
@export var repair_cost := 5            # rottami per riparare una difesa
@export var pickup_radius := 30.0

var hp := 10.0
var shells := 2           # colpi in canna (la doppietta ne ha 2)
var reserve := 12         # cartucce di scorta: quando finiscono, niente ricarica!
var _refill_cd := 0.0
var facing := 1           # 1 = guarda a destra, -1 = a sinistra
var _vel_y := 0.0
var _on_ground := true
var _reload_left := 0.0
var _fork_cd := 0.0
var _flash_time := 0.0    # quanto resta da mostrare la fiammata dello sparo
var _fork_time := 0.0
var _hurt_time := 0.0
var _aim := Vector2.RIGHT


func _ready() -> void:
	# I GRUPPI sono etichette: permettono ad altri script di trovare il
	# giocatore con get_tree().get_first_node_in_group("player").
	add_to_group("player")
	hp = max_hp
	reserve = max_reserve


func is_dead() -> bool:
	return hp <= 0


# Aggiunge cartucce di scorta (dalla cascina o portate dal cane).
func add_ammo(amount: int) -> void:
	reserve = min(max_reserve, reserve + amount)


func is_reloading() -> bool:
	return _reload_left > 0


# Punto "centrale" del corpo, usato per mirare e per i fumetti.
func center() -> Vector2:
	return position + Vector2(0, -30)


func take_damage(amount: float) -> void:
	if is_dead():
		return
	hp -= amount
	_hurt_time = 0.1
	if hp <= 0:
		GameState.end_game(false)


# _physics_process viene chiamata 60 volte al secondo.
# `delta` è il tempo passato dall'ultima chiamata (circa 0.016 secondi):
# moltiplicare le velocità per delta rende il movimento indipendente dagli FPS.
func _physics_process(delta: float) -> void:
	if GameState.finished:
		return

	# Movimento orizzontale: get_axis restituisce -1, 0 o 1.
	var dir := Input.get_axis("sinistra", "destra")
	position.x = clamp(position.x + dir * speed * delta, GameState.GATE_X + 10, GameState.SCREEN_W - 20)

	# Salto e gravità.
	if _on_ground and Input.is_action_just_pressed("salta"):
		_vel_y = jump_velocity
		_on_ground = false
	_vel_y += gravity * delta
	position.y += _vel_y * delta
	if position.y >= GameState.GROUND_Y:
		position.y = GameState.GROUND_Y
		_vel_y = 0.0
		_on_ground = true

	# Mira: il personaggio guarda verso il mouse.
	var mouse := get_global_mouse_position()
	_aim = (mouse - center()).normalized()
	facing = 1 if mouse.x >= position.x else -1

	# Ricarica (automatica quando la canna è vuota, oppure con R).
	if _reload_left > 0:
		_reload_left -= delta
		if _reload_left <= 0:
			# Ricarica solo quello che c'è nella scorta.
			var loaded: int = min(2 - shells, reserve)
			shells += loaded
			reserve -= loaded
	elif Input.is_action_just_pressed("ricarica") and shells < 2 and reserve > 0:
		_reload_left = reload_time

	# Vicino alla cascina si recuperano cartucce, una alla volta.
	_refill_cd -= delta
	if position.x < GameState.GATE_X + 70 and reserve < max_reserve and _refill_cd <= 0:
		_refill_cd = refill_interval
		add_ammo(1)
		GameState.spawn_text(center() + Vector2(0, -40), "+1 cartuccia", Color("ffdd66"))

	if Input.is_action_just_pressed("spara"):
		_shoot()
	_fork_cd -= delta
	if Input.is_action_just_pressed("forcone") and _fork_cd <= 0:
		_fork()
	if Input.is_action_just_pressed("ripara"):
		_repair()

	_pick_up_scrap()

	_flash_time -= delta
	_fork_time -= delta
	_hurt_time -= delta
	queue_redraw()  # chiede a Godot di richiamare _draw()


func _shoot() -> void:
	if _reload_left > 0 or shells <= 0:
		return
	shells -= 1
	_flash_time = 0.08
	var origin := center()
	# I pallini si fermano sul PRIMO robot che incontrano: cerchiamo il più
	# vicino dentro il "cono" davanti alla canna.
	var best = null
	var best_dist := INF
	for enemy in get_tree().get_nodes_in_group("enemies"):
		var to_enemy: Vector2 = enemy.center() - origin
		var dist := to_enemy.length()
		if dist > shotgun_range:
			continue
		# Tolleranza extra per i bersagli grandi o molto vicini.
		var extra := rad_to_deg(atan2(enemy.size.y * 0.5, max(dist, 1.0)))
		if abs(rad_to_deg(_aim.angle_to(to_enemy))) > shotgun_spread_deg + extra:
			continue
		if dist < best_dist:
			best = enemy
			best_dist = dist
	if best != null:
		# Da lontano la doppietta fa molti meno danni: bisogna avvicinarsi.
		var falloff := 1.0 - (best_dist / shotgun_range) * 0.8
		best.take_damage(shotgun_damage * falloff)
	if shells == 0 and reserve > 0:
		_reload_left = reload_time


func _fork() -> void:
	_fork_cd = fork_cooldown
	_fork_time = 0.15
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if enemy.flying:
			continue
		var dx: float = (enemy.position.x - position.x) * facing
		if dx > -10 and dx < fork_range + enemy.size.x * 0.5:
			enemy.take_damage(fork_damage)
			enemy.knockback(fork_knockback)


# Ripara la difesa più vicina spendendo rottami.
func _repair() -> void:
	for defense in get_tree().get_nodes_in_group("defenses"):
		if abs(defense.position.x - position.x) > 70 or not defense.needs_repair():
			continue
		if GameState.spend_scrap(repair_cost):
			defense.repair()
			GameState.spawn_text(center() + Vector2(0, -40), "Riparato!", Color("aaffaa"))
		else:
			GameState.spawn_text(center() + Vector2(0, -40), "Servono %d rottami" % repair_cost, Color("ffaaaa"))
		return


func _pick_up_scrap() -> void:
	for scrap in get_tree().get_nodes_in_group("scrap"):
		if scrap.position.distance_to(position) < pickup_radius:
			scrap.collect()


func _draw() -> void:
	# Disegno placeholder: jeans, camicia a quadri, testa.
	var hurt := _hurt_time > 0
	draw_rect(Rect2(-9, -24, 18, 24), Color("2f4a7a"))                              # jeans
	draw_rect(Rect2(-11, -46, 22, 22), Color.WHITE if hurt else Color("8a2a24"))   # camicia
	draw_line(Vector2(-11, -38), Vector2(11, -38), Color("3a1512"), 2)              # quadri
	draw_line(Vector2(0, -46), Vector2(0, -24), Color("3a1512"), 2)
	draw_rect(Rect2(-7, -60, 14, 14), Color("e0b48a"))                              # testa
	draw_rect(Rect2(-8, -63, 16, 5), Color("5a3a1f"))                               # capelli

	# Doppietta puntata verso il mouse.
	var gun_start := Vector2(0, -30)
	draw_line(gun_start, gun_start + _aim * 28, Color("3b2a1a"), 4)
	if _flash_time > 0:
		draw_line(gun_start + _aim * 28, gun_start + _aim * 60, Color("ffdd66"), 6)

	# Forcone.
	if _fork_time > 0:
		var tip := Vector2(facing * fork_range, -26)
		draw_line(Vector2(0, -26), tip, Color("b0a080"), 3)
		for i in 3:
			draw_line(tip, tip + Vector2(facing * 10, -6 + i * 6), Color("c0c0c0"), 2)

	if is_reloading():
		draw_string(ThemeDB.fallback_font, Vector2(-30, -72), "ricarica...", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color("ffdd66"))
