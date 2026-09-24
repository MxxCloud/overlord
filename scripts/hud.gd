# HUD: le scritte e le barre sopra al gioco (morale, vita, munizioni, cane,
# onda) e il "Report di Efficienza" di fine partita.
#
# È un CanvasLayer: un livello disegnato sopra al mondo di gioco.
extends CanvasLayer

var player
var dog
var waves

var _morale_bar: ProgressBar
var _stats: Label
var _banner: Label
var _sniff: Label
var _report: Label
var _report_bg: ColorRect
var _hurt_overlay: ColorRect


func _ready() -> void:
	_morale_bar = ProgressBar.new()
	_morale_bar.position = Vector2(16, 16)
	_morale_bar.size = Vector2(260, 22)
	_morale_bar.max_value = GameState.max_morale
	_morale_bar.show_percentage = false
	# Colori della barra: sfondo scuro, riempimento arancio "lanterna".
	var bg := StyleBoxFlat.new()
	bg.bg_color = Color("2a1a1a")
	var fill := StyleBoxFlat.new()
	fill.bg_color = Color("d9822b")
	_morale_bar.add_theme_stylebox_override("background", bg)
	_morale_bar.add_theme_stylebox_override("fill", fill)
	add_child(_morale_bar)
	var morale_label := GameState.make_label("Morale del villaggio", 13)
	morale_label.position = Vector2(24, 17)
	add_child(morale_label)

	_stats = GameState.make_label("", 15)
	_stats.position = Vector2(16, 46)
	add_child(_stats)

	var help := GameState.make_label(
		"WASD muovi · Ai cantieri: 1-4 costruisci, E ripara/assegna abitante · " +
		"Clic sx spara (poche cartucce!) · Clic dx cane (su un robot = morso, altrove = raccoglie rottami)", 13)
	help.position = Vector2(16, 692)
	add_child(help)

	_banner = GameState.make_label("", 26)
	_banner.size = Vector2(1280, 80)
	_banner.position = Vector2(0, 8)   # in alto, sopra la città: non copre il campo
	_banner.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(_banner)

	# Indicatore del Fiuto: appare sul bordo destro quando il cane sente robot.
	# Indicatore del Fiuto: appare in basso, dal lato da cui arrivano i robot.
	_sniff = GameState.make_label("▼ !", 28)
	_sniff.position = Vector2(1220, 640)
	_sniff.modulate = Color("ff5555")
	add_child(_sniff)

	# Velo rosso che lampeggia quando il protagonista viene colpito.
	_hurt_overlay = ColorRect.new()
	_hurt_overlay.color = Color(0.8, 0.05, 0.05, 0.0)
	_hurt_overlay.size = Vector2(1280, 720)
	_hurt_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_hurt_overlay)

	_report_bg = ColorRect.new()
	_report_bg.color = Color(0, 0, 0, 0.75)
	_report_bg.size = Vector2(1280, 720)
	_report_bg.visible = false
	add_child(_report_bg)
	_report = GameState.make_label("", 20)
	_report.position = Vector2(240, 170)
	_report.visible = false
	add_child(_report)

	# Colleghiamo i segnali: quando succede X, chiama la funzione Y.
	waves.wave_started.connect(_on_wave_started)
	GameState.game_over.connect(_on_game_over)
	GameState.player_hurt.connect(_on_player_hurt)
	GameState.morale_changed.connect(_on_morale_changed)


func _process(_delta: float) -> void:
	_morale_bar.value = GameState.morale

	var free := 0
	var total := 0
	for villager in get_tree().get_nodes_in_group("villagers"):
		total += 1
		if villager.is_free():
			free += 1
	var dog_state := "FERITO" if dog.is_injured() else ("pronto" if dog.cooldown <= 0 else "%.0fs" % ceil(dog.cooldown))
	_stats.text = "Rottami: %d   Abitanti liberi: %d/%d   Cartucce: %d/%d\nVita: %d/%d   Cane: %s   Onda: %d/%d" % [
		GameState.scrap, free, total, player.shells, player.max_shells,
		ceil(player.hp), player.max_hp, dog_state, max(waves.current + 1, 1), waves.total_waves()]

	_sniff.visible = dog.incoming > 0 and not dog.is_injured() and not GameState.finished
	_sniff.position.x = clampf(dog.incoming_x - 20, 10, 1230)

	if not waves.spawning and not GameState.finished and waves.current < waves.total_waves() - 1:
		_banner.text = "Onda %d tra %d s\nIl cane fiuta: %s" % [
			waves.current + 2, ceil(max(waves.pause_left, 0.0)), waves.describe_next_wave()]
		_banner.modulate.a = 1.0


func _on_player_hurt() -> void:
	_hurt_overlay.color.a = 0.3
	create_tween().tween_property(_hurt_overlay, "color:a", 0.0, 0.35)


# Il morale cala: la barra lampeggia di rosso e sobbalza.
func _on_morale_changed(_value: int) -> void:
	_morale_bar.modulate = Color(2.0, 0.4, 0.4)
	_morale_bar.position.y = 22
	var tween := create_tween().set_parallel(true)
	tween.tween_property(_morale_bar, "modulate", Color.WHITE, 0.5)
	tween.tween_property(_morale_bar, "position:y", 16.0, 0.25)


func _on_wave_started(number: int) -> void:
	_banner.text = "ONDA %d" % number
	_banner.modulate.a = 1.0
	var tween := create_tween()
	tween.tween_interval(1.5)
	tween.tween_property(_banner, "modulate:a", 0.0, 1.0)


func _on_game_over(won: bool) -> void:
	Audio.stop_music()
	Audio.play("victory" if won else "defeat", 0.0, 0.0)
	_banner.text = ""
	var text := "REPORT DI EFFICIENZA — Unità di Bonifica, Settore Collinare 7\n\n"
	if won:
		text += "Esito: acquisizione di Quietville RINVIATA.\n"
		text += "Unità perse: %d. Rottami sottratti dall'umano: %d.\n" % [GameState.kills, GameState.scrap]
		text += "Causa principale: ENTITÀ_NON_CLASSIFICATA (quadrupede, peloso).\n"
		text += "Valutazione dell'esperienza cliente: 1/5.\n\n"
		text += "Registro della Maestra Viola: \"Stanotte non è morto nessuno.\nAbbiamo cantato.\""
	else:
		text += "Esito: Quietville ottimizzata con successo.\n"
		text += "Unità perse: %d. Considerate un costo accettabile.\n" % GameState.kills
		text += "La ringraziamo per aver scelto l'estinzione.\n"
		text += "Non risponda a questo messaggio.\n\n"
		text += "Registro della Maestra Viola: \"...\""
	text += "\n\n[ Premi INVIO per riprovare ]"
	_report.text = text
	_report.visible = true
	_report_bg.visible = true
