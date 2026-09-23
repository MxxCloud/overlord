# Quietville: prototipo della fase notturna

Prototipo giocabile di **una notte d'assedio**, per capire se il cuore del gioco è divertente. Il design completo è in [`docs/GDD.md`](docs/GDD.md).

La grafica è fatta di rettangoli: la pixel art arriverà dopo. Qui conta solo *come si gioca*.

---

## Come aprirlo e giocarlo (passo passo)

1. **Scarica Godot 4.3**, versione *Standard* e non *.NET*: https://godotengine.org/download
   Godot non va installato. È un unico programma: si scompatta e si avvia.
2. **Scarica questo progetto** sul tuo computer:
   - da GitHub: pulsante verde **Code → Download ZIP** (assicurati di essere sul branch giusto), poi scompatta;
   - oppure, se usi git: `git clone` del repository.
3. **Avvia Godot.** Nella schermata *Project Manager* clicca **Importa** (Import), scegli il file `project.godot` in questa cartella e poi **Importa e modifica**.
4. Si apre l'editor. Premi **F5** (o il pulsante ▶ in alto a destra) per giocare.

> La prima volta Godot impiega qualche secondo a "importare" il progetto e crea una cartella `.godot/`. È normale: è una cache e non va salvata nel repository.

## Comandi

| Tasto | Azione |
|---|---|
| **A / D** (o frecce) | Muoversi |
| **W / Spazio** | Saltare (anche sopra i robot) |
| **Clic sinistro** | Sparare con la doppietta verso il mouse (2 colpi, poi ricarica) |
| **R** | Ricaricare |
| **F** | Colpo di forcone (corpo a corpo, respinge il robot) |
| **Clic destro su un robot** | Il cane corre a mordergli i cavi e lo stordisce |
| **Clic destro su un punto vuoto** | Il cane corre lì e raccoglie i rottami |
| **Q** (vicino a una difesa) | Ripararla spendendo 5 rottami |
| **Invio** | Ricominciare a fine partita |

## Regole della notte

- I robot arrivano da destra in **3 onde** e cercano di raggiungere il **cancello** del villaggio, accanto alla cascina.
- Ogni robot che passa il cancello fa calare il **Morale del villaggio**. Se arriva a zero, hai perso. Hai perso anche se il protagonista muore.
- **Difese:**
  - **Spaventapasseri:** i robot, anche i droni, lo scambiano per un umano e si fermano ad attaccarlo.
  - **Fossa:** i robot leggeri ci cadono e restano intrappolati. Ne contiene 3.
  - **Recinto:** blocca i robot di terra finché non lo abbattono.
- **Nemici:**
  - **Servitore Domestico:** lento, arriva in gruppo.
  - **Drone Sondaggio:** vola e ignora recinti e fosse.
  - **Segugio:** veloce, salta le fosse. Il morso del cane gli fa danno doppio.
- **Il cane** (Bullone) ha un'attesa di qualche secondo tra un ordine e l'altro. Con il **Fiuto** abbaia e fa comparire un **▶ !** rosso sul bordo destro quando sente robot in arrivo. Se lo ferisci troppo, per questa notte si ritira (non muore mai).

## Come modificare il gioco (anche senza saper programmare)

Tutti i numeri importanti sono all'inizio dei file, con commenti in italiano:

- **Difficoltà delle onde:** `scripts/wave_manager.gd`, array `waves`. Cambia `"quanti"` e `"intervallo"`.
- **Protagonista** (velocità, danni, ricarica): variabili `@export` in `scripts/player.gd`.
- **Cane** (velocità, stordimento, attesa tra ordini): `scripts/dog.gd`.
- **Robot** (vita, velocità, battute): `scripts/enemies/servitore.gd`, `drone.gd`, `segugio.gd`.
- **Difese** (resistenza) e loro posizione: `scripts/defenses/*.gd` e `_ready()` in `scripts/main.gd`.

Dopo ogni modifica salva il file (Ctrl+S) e premi F5 per riprovare.

## Struttura del progetto

```
project.godot            configurazione del progetto (scena iniziale, finestra, autoload)
scenes/Main.tscn         scena principale (costruisce tutto il livello da codice)
scripts/
  game_state.gd          stato globale: morale, rottami, comandi, fine partita
  main.gd                crea il livello e disegna lo sfondo
  player.gd              protagonista
  dog.gd                 cane
  wave_manager.gd        onde di robot
  hud.gd                 interfaccia e report finale
  scrap.gd               rottami a terra
  enemies/               robot (enemy.gd è la base comune)
  defenses/              difese (defense.gd è la base comune)
tests/smoke_test.gd      test automatico: gioca una partita accelerata
docs/GDD.md              Game Design Document
```

## Test automatico (facoltativo)

Da terminale, nella cartella del progetto:

```
godot --headless -s res://tests/smoke_test.gd
```

Gioca da solo una partita accelerata e stampa il risultato. Serve a scoprire eventuali errori dopo una modifica.
