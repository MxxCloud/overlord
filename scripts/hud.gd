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
		"A/D muovi · W/Spazio salta · Clic sx spara · R ricarica · F forcone · " +
		"Clic dx: cane (robot = morso, cascina = cartucce) · Q ripara (5 rottami)", 13)
	help.position = Vector2(16, 692)
	add_child(help)

	_banner = GameState.make_label("", 32)
	_banner.size = Vector2(1280, 50)
	_banner.position = Vector2(0, 200)
	_banner.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(_banner)

	# Indicatore del Fiuto: appare sul bordo destro quando il cane sente robot.
	_sniff = GameState.make_label("▶ ! ", 28)
	_sniff.position = Vector2(1220, 520)
	_sniff.modulate = Color("ff5555")
	add_child(_sniff)

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


func _process(_delta: float) -> void:
	_morale_bar.value = GameState.morale

	var ammo := ("ricarica..." if player.is_reloading() else "%d/2" % player.shells) + " (+%d)" % player.reserve
	var dog_state := "FERITO" if dog.is_injured() else ("pronto" if dog.cooldown <= 0 else "%.0fs" % ceil(dog.cooldown))
	_stats.text = "Vita: %d/%d   Cartucce: %s   Rottami: %d\nCane: %s   Onda: %d/%d" % [
		ceil(player.hp), player.max_hp, ammo, GameState.scrap,
		dog_state, max(waves.current + 1, 1), waves.total_waves()]

	_sniff.visible = dog.incoming > 0 and not dog.is_injured() and not GameState.finished

	if not waves.spawning and not GameState.finished and waves.current < waves.total_waves() - 1:
		_banner.text = "Onda %d tra %d..." % [waves.current + 2, ceil(max(waves.pause_left, 0.0))]
		_banner.modulate.a = 1.0


func _on_wave_started(number: int) -> void:
	_banner.text = "ONDA %d" % number
	_banner.modulate.a = 1.0
	var tween := create_tween()
	tween.tween_interval(1.5)
	tween.tween_property(_banner, "modulate:a", 0.0, 1.0)


func _on_game_over(won: bool) -> void:
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
