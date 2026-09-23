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

## L'idea di questa versione

Sei il **comandante della collina**, non un eroe d'azione (come in *Kingdom*). La notte si vince **preparandosi**:
- decidi dove costruire le difese e spendi i rottami;
- assegni gli abitanti alle postazioni;
- ripari quello che i robot rompono;
- usi il cane e le poche cartucce nei momenti critici.

## Comandi

| Tasto | Azione |
|---|---|
| **A / D** (o frecce) | Muoversi lungo la collina |
| **1 / 2 / 3 / 4** (davanti a un cantiere vuoto, con la bandierina) | Costruire: Recinto (8 rottami), Fossa (6), Spaventapasseri (5), Postazione (10) |
| **E** (davanti a una difesa) | Ripararla (3 rottami), oppure assegnare un abitante a una postazione vuota |
| **Clic sinistro** | Sparare con la doppietta. **Solo 6 cartucce per tutta la notte**: colpisce il primo robot e da vicino fa molto male |
| **Clic destro su un robot** | Il cane gli morde i cavi e lo stordisce: un robot stordito subisce **danni doppi** |
| **Clic destro su un punto vuoto** | Il cane corre lì e raccoglie i rottami |
| **Invio** | Ricominciare a fine partita |

## Regole della notte

- Parti con **30 rottami** e **4 cantieri vuoti**. Hai 35 secondi prima della prima onda: scegli cosa costruire.
- **Costruire richiede tempo.** Un abitante libero arriva dal villaggio e lavora al cantiere. Se un robot lo raggiunge mentre lavora, resta ferito per il resto della notte.
- **Abitanti** (Nonna Edda, Gus, Padre Tobia): costruiscono e riparano, oppure presidiano una **postazione** e da lì lanciano molotov sui robot di terra. Se la postazione crolla, l'abitante resta ferito.
- **Rottami:** i robot distrutti li lasciano a terra. Li raccogli passandoci sopra, oppure mandando il cane.
- Tra un'onda e l'altra hai 25 secondi. Il cane **fiuta** in anticipo cosa sta arrivando (es. "7 servitori, 3 droni").
- Ogni robot che passa il **cancello** fa calare il **Morale del villaggio**. Hai perso se arriva a zero, oppure se il protagonista muore.
- **Difese:**
  - **Postazione:** senza un abitante non fa nulla. Presidiata, lancia molotov. I robot di terra la attaccano.
  - **Recinto:** blocca i robot di terra finché non lo abbattono.
  - **Fossa:** i robot leggeri ci cadono e restano intrappolati. Ne contiene 3; ripararla la svuota.
  - **Spaventapasseri:** tutti i robot, anche i droni, si fermano ad attaccarlo.
- **Nemici:**
  - **Servitore Domestico:** lento, arriva in gruppo.
  - **Drone Sondaggio:** vola, e le molotov non lo raggiungono. Spara colpi lenti che si schivano camminando. Serve la doppietta.
  - **Segugio:** più veloce, salta le fosse. Il morso del cane gli fa danno doppio.
- **Il cane** (Bullone) ha un'attesa di qualche secondo tra un ordine e l'altro. Se lo ferisci troppo, per questa notte si ritira (non muore mai).

## Come modificare il gioco (anche senza saper programmare)

Tutti i numeri importanti sono all'inizio dei file, con commenti in italiano:

- **Difficoltà delle onde:** `scripts/wave_manager.gd`, array `waves`. Cambia `"quanti"` e `"intervallo"`.
- **Protagonista** (velocità, cartucce, danni): variabili `@export` in `scripts/player.gd`.
- **Rottami iniziali:** `start_scrap` in `scripts/game_state.gd`.
- **Costi e tempi di costruzione:** `TYPES` in `scripts/build_slot.gd`.
- **Abitanti** (nomi, molotov): `VILLAGERS` in `scripts/main.gd` e `scripts/villager.gd`.
- **Cane** (velocità, stordimento, attesa tra ordini): `scripts/dog.gd`.
- **Robot** (vita, velocità, battute): `scripts/enemies/servitore.gd`, `drone.gd`, `segugio.gd`.
- **Difese** (resistenza): `scripts/defenses/*.gd`. Posizione dei cantieri: `SLOT_POSITIONS` in `scripts/main.gd`.

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
  build_slot.gd          cantieri: costruzione e riparazione
  villager.gd            abitanti (costruiscono, presidiano le postazioni)
  molotov.gd             molotov lanciate dalle postazioni
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
