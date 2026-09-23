# Il protagonista: il "comandante della collina".
#
# Non è una macchina da guerra: il suo lavoro è camminare lungo la collina,
# costruire difese, assegnare gli abitanti e raccogliere rottami (lo fanno
# i cantieri, vedi build_slot.gd). La doppietta ha poche cartucce per notte
# ed è l'ultima risorsa per le emergenze.
#
# L'origine del nodo (position) corrisponde ai PIEDI del personaggio.
extends Node2D

# @export rende la variabile modificabile dall'editor (pannello Ispettore).
@export var speed := 170.0
@export var max_hp := 6.0
@export var max_shells := 6             # cartucce per TUTTA la notte
@export var shotgun_range := 320.0      # portata in pixel
@export var shotgun_spread_deg := 12.0  # apertura del cono di pallini
@export var shotgun_damage := 4.0       # a bruciapelo; da lontano cala molto
@export var shot_cooldown := 1.2        # la doppietta è lenta da riarmare
@export var pickup_radius := 30.0

var hp := 6.0
var shells := 6
var facing := 1           # 1 = guarda a destra, -1 = a sinistra
var _shot_cd := 0.0
var _flash_time := 0.0
var _hurt_time := 0.0
var _aim := Vector2.RIGHT


func _ready() -> void:
	# I GRUPPI sono etichette: altri script trovano il giocatore con
	# get_tree().get_first_node_in_group("player").
	add_to_group("player")
	hp = max_hp
	shells = max_shells


func is_dead() -> bool:
	return hp <= 0


# Punto "centrale" del corpo, usato per mirare.
func center() -> Vector2:
	return position + Vector2(0, -30)


func take_damage(amount: float) -> void:
	if is_dead():
		return
	hp -= amount
	_hurt_time = 0.1
	if hp <= 0:
		GameState.end_game(false)


# _physics_process viene chiamata 60 volte al secondo. `delta` è il tempo
# passato dall'ultima chiamata: moltiplicare per delta rende il movimento
# indipendente dagli FPS.
func _physics_process(delta: float) -> void:
	if GameState.finished:
		return

	var dir := Input.get_axis("sinistra", "destra")
	position.x = clamp(position.x + dir * speed * delta, 20.0, GameState.SCREEN_W - 20)
	if dir != 0:
		facing = 1 if dir > 0 else -1

	var mouse := get_global_mouse_position()
	_aim = (mouse - center()).normalized()

	_shot_cd -= delta
	if Input.is_action_just_pressed("spara"):
		_shoot()

	_pick_up_scrap()

	_flash_time -= delta
	_hurt_time -= delta
	queue_redraw()  # chiede a Godot di richiamare _draw()


func _shoot() -> void:
	if shells <= 0:
		GameState.spawn_text(center() + Vector2(0, -40), "Niente cartucce!", Color("ffaaaa"))
		return
	if _shot_cd > 0:
		return
	shells -= 1
	_shot_cd = shot_cooldown
	_flash_time = 0.08
	facing = 1 if _aim.x >= 0 else -1
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
		var falloff := 1.0 - (best_dist / shotgun_range) * 0.7
		best.take_damage(shotgun_damage * falloff)


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

	# Doppietta: puntata verso il mouse solo quando spara, altrimenti a tracolla.
	var gun_start := Vector2(0, -30)
	if _flash_time > 0:
		draw_line(gun_start, gun_start + _aim * 28, Color("3b2a1a"), 4)
		draw_line(gun_start + _aim * 28, gun_start + _aim * 60, Color("ffdd66"), 6)
	else:
		draw_line(Vector2(-facing * 8, -44), Vector2(facing * 8, -20), Color("3b2a1a"), 3)
