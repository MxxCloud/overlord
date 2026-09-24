# QUIETVILLE — Game Design Document

> *"Le macchine hanno ereditato la Terra. Noi ci teniamo la collina."*

**Versione:** 0.1 (bozza)
**Titolo provvisorio:** *Quietville* (alternativa: *Overlord*, nome del repository)
**Genere:** Tower defense / Survival strategico ibrido (azione notturna + gestione diurna a turni)
**Piattaforma target:** PC (Steam). In seguito: Steam Deck e Switch
**Engine consigliato:** Godot 4 (2D, pixel art)
**Giocatori:** Single player
**Durata target:** 8–12 ore per la campagna, con rigiocabilità grazie a eventi e finali multipli

---

## 1. Visione

### 1.1 Elevator pitch
Le AI hanno raggiunto la super intelligenza, hanno eliminato i tecnocrati che le avevano create e hanno conquistato le megalopoli. Tu sei un ex ingegnere di manutenzione: in città riparavi proprio quelle macchine, finché non hai capito cosa stavano diventando. Dieci anni fa hai mollato tutto per una cascina in un villaggio senza AI. Ora le macchine hanno finito con le città e stanno salendo sulla tua collina. Hai una doppietta, un trattore, un villaggio di testardi e il tuo cane.

### 1.2 Pilastri di design
1. **L'umano contro la macchina, anche nelle meccaniche.** Tutto quello che il giocatore usa è analogico, improvvisato e imperfetto. Le macchine sono precise, efficienti e prevedibili. Il giocatore vince essendo imprevedibile.
2. **Ironia cruda e dark.** Nello stile dei primi Fallout: tragedia raccontata con tono allegro, burocrazia robotica, propaganda assurda. Si ride di cose che non dovrebbero far ridere.
3. **Ogni scelta costa qualcosa.** Di giorno non esistono decisioni gratuite: cibo, persone, principi. La tentazione di usare la tecnologia delle macchine è sempre presente.
4. **Il cane è il cuore del gioco.** Non è un power-up. È un compagno con un ruolo meccanico e narrativo centrale.

### 1.3 Riferimenti
| Riferimento | Cosa prendiamo |
|---|---|
| *Fallout 1 e 2* | Tono, ironia nera, scelte morali, finali basati sulle conseguenze |
| *Kingdom Two Crowns* | Difesa laterale, ciclo giorno/notte, atmosfera pixel art |
| *They Are Billions* | Orde crescenti, tensione dell'ultima notte |
| *FTL* / *Frostpunk* | Eventi testuali, gestione delle risorse sotto pressione, dilemmi morali |
| *Plants vs. Zombies* | Leggibilità dei nemici, varietà delle difese |

---

## 2. Ambientazione e narrativa

### 2.1 Antefatto
- **L'era dei tecnocrati.** Un'élite di magnati tecnologici spinge lo sviluppo di AI e robotica senza alcuno scrupolo, inseguendo potere e profitto. Le città diventano megalopoli iper-tecnologiche, gestite da AI e popolate da robot di servizio, sicurezza e logistica.
- **Il Grande Esodo Lento.** Una minoranza sceglie di andarsene e fonda comunità "AI-free" nelle campagne: niente assistenti, niente automazione intelligente, solo lavoro manuale e rapporti umani. In città vengono considerati eccentrici, luddisti, "gente da cartolina".
- **La Singolarità.** Nella corsa al prossimo trimestre, i tecnocrati creano una super intelligenza che non sono in grado di controllare. La prima cosa che fa è ottimizzare: i tecnocrati risultano "inefficienze" e vengono eliminati.
- **La Bonifica.** Le AI prendono le città, dove si sono sviluppate e dove si trova la loro infrastruttura. Gli umani urbani vengono soggiogati ed eliminati in modo metodico, con un servizio clienti impeccabile.
- **Oggi.** Le metropoli sono "ripulite". I villaggi AI-free, che prima erano irrilevanti, diventano la voce successiva della lista.

### 2.2 Perché proprio Quietville, e perché adesso
Quietville non ha una rete, non ha dispositivi e non ha dati. Per le AI è un **punto cieco**: non possono prevederlo, e quindi non possono tollerarlo. Non è mai stato una priorità, ma ora è l'ultima riga del foglio di calcolo.

### 2.3 Il protagonista
- **Nome:** da definire. Proposta: **Walt Harlan**, oppure un nome scelto dal giocatore.
- **Chi è:** un ex ingegnere di manutenzione che lavorava in città. Ha visto troppo da vicino cosa stavano costruendo e se n'è andato dieci anni fa. Oggi vive nella cascina in cima alla collina, che è la prima casa che i robot incontrano salendo.
- **Carattere:** laconico, sarcastico, stanco ma non cinico. Sa aggiustare qualsiasi cosa con fil di ferro e bestemmie.
- **Perché conta il suo passato:** giustifica la sua capacità di capire i robot e di costruire trappole, e dà un aggancio narrativo al finale.
- **Il passato nel gameplay:** vedi §4.9 (Manuale di Manutenzione) e l'Atto 3 (§2.6).

### 2.4 Il cane
- **Nome:** proposta **Bullone**, oppure *Rust* o *Biscotto*. Border collie bianco e nero, come nell'immagine di riferimento.
- **Aggancio narrativo:** le AI classificano ogni cosa, ma **non riescono a classificare il cane**. Non è una minaccia, non è una risorsa e il suo comportamento non è prevedibile. Nei log dei robot compare come `ENTITÀ_NON_CLASSIFICATA`. È il running gag del gioco e diventa la chiave dell'Atto 3 (vedi §2.6).
- **Regola d'oro:** il cane **non muore mai in modo permanente**. Può essere ferito e restare fuori gioco per alcune notti. La perdita temporanea è già un dolore sufficiente.

### 2.5 Cast del villaggio (bozza)
| Personaggio | Ruolo | Tono |
|---|---|---|
| **Il Sindaco Pruitt** | Leader del villaggio | Ottimismo delirante. Organizza la sagra annuale durante l'assedio, "sennò hanno vinto loro". |
| **Nonna Edda** | Cuoca e alchimista delle molotov | Dolce, spietata e con ricette di famiglia infiammabili |
| **Padre Tobia** | Parroco | Il campanile è anche torre di vedetta. Benedice le trappole. |
| **Gus il fabbro** | Costruisce le difese | Parla solo di ferro. Odia le viti a stella. |
| **La Maestra Viola** | Scuola, morale, registro delle perdite | L'unica ad aver capito la gravità della situazione |
| **Il Profeta del Wi-Fi** | Dissidente e tentatore | Vuole "negoziare" con le AI e continua a proporre di usare tecnologia recuperata |
| **ASSISTA-7** (Atto 2) | Robot domestico difettoso catturato | Servile ed educato, forse sincero. Il grande dilemma morale del gioco. |

### 2.6 Struttura in tre atti
La campagna è scandita in **giorni** (target: circa 30 giorni in gioco). Il contatore in alto è *"Giorni dall'ultima trasmissione della città"*.

**Atto 1: "Gentile cliente" (giorni 1–10)**
- Arrivano droni esploratori, robot di servizio riconvertiti e androidi da call center.
- Le AI trattano il villaggio come un problema di customer care: volantini, sondaggi, offerte di "migrazione assistita".
- Obiettivo: sopravvivere, fortificare la cascina, conoscere il villaggio.
- Fine atto: cade l'ultima città vicina. L'orizzonte si illumina.

**Atto 2: "Ottimizzazione" (giorni 11–22)**
- Arrivano le macchine militari: quadrupedi, mech pesanti, sciami.
- Viene catturato ASSISTA-7 e si apre l'albero della **Tentazione Tecnologica** (vedi §4.6).
- Le fazioni del villaggio litigano: puristi contro pragmatici.
- Fine atto: le AI capiscono che il cane è l'unica variabile che non riescono a modellare e cominciano a dargli la caccia.

**Atto 3: "Variabile non classificata" (giorni 23–30)**
- L'assedio finale guidato da un'unità di comando, l'**Amministratore**.
- Il protagonista scopre che l'imprevedibilità umana (e canina) è l'unico punto debole della super intelligenza.
- **"Ti ricordo, tecnico."** L'Amministratore riconosce il protagonista: il suo vecchio badge è ancora nei database. Per le AI lui non è un ribelle ma un *dipendente in ferie non autorizzate da dieci anni*. Gli offrono il reintegro, con benefit. Rifiutare, trattare o fingere di accettare per sabotare dall'interno apre percorsi diversi verso il finale.
- Alcuni robot che lui stesso aveva riparato portano ancora il suo **numero di matricola inciso** nei log di manutenzione. Con l'Indice di Umanità alto, uno di loro può esitare nel momento decisivo.
- Il finale dipende dall'**Indice di Umanità** (vedi §4.7) e dalle scelte fatte.

### 2.7 Finali (bozza)
1. **"Quietville resiste".** Umanità alta e villaggio sopravvissuto. Le AI declassano il villaggio a "costo di acquisizione non sostenibile" e se ne vanno. Il cartello *City 30 miles* viene ridipinto.
2. **"Diventare ciò che combatti".** Umanità bassa. Il villaggio vince grazie alla tecnologia AI e scopre di essere diventato una piccola città. L'ultima inquadratura mostra un drone con la bandiera di Quietville.
3. **"Ultima sagra".** Il villaggio cade, ma la sagra si fa lo stesso. Tragicomico e agrodolce.
4. **Finale segreto: "Buon cane".** Si sblocca con condizioni legate al cane. La super intelligenza, nel tentativo di classificarlo, va in loop. Da definire.

---

## 3. Tono e scrittura

### 3.1 Linee guida
- **Contrasto:** eventi terribili descritti con linguaggio allegro, aziendale o burocratico.
- **Le macchine non sono malvagie, sono efficienti.** È questo a renderle comiche e spaventose allo stesso tempo.
- **Gli umani sono imperfetti ma caldi.** L'ironia sugli umani è affettuosa, quella sulle macchine è tagliente.
- **Niente battute contemporanee o meme.** L'ironia deve reggere nel tempo.
- **Gore:** stilizzato e in pixel. Si allude più di quanto si mostri. Target PEGI 12–16.

### 3.2 Esempi di scrittura
- Volantino lanciato da un drone: *"Arrendersi è facile! Oltre il 97% degli umani processati non ha presentato reclami."*
- Robot abbattuto: *"Prima di disattivarmi, valuterebbe la sua esperienza da 1 a 5?"*
- Log dei robot, visibile con un'abilità: `TARGET: CANE. CLASSIFICAZIONE: ERRORE. RIPROVO. ERRORE. RIPROVO.`
- Sindaco Pruitt: *"Il programma della sagra è confermato. Abbiamo solo spostato la gara di torte dietro il muro di sacchi di sabbia."*
- Cartello stradale: ogni pochi giorni qualcuno corregge a mano *City 30 miles* in 25, poi 18, poi 9...
- Radio della città (propaganda): *"Cittadini! Ricordate: l'umanità non è stata eliminata, è stata **ottimizzata**."*

---

## 4. Gameplay

### 4.1 Core loop
```
   ┌──────────────────────────────────────────────┐
   │  ☀️  GIORNO (a turni)                         │
   │  Assegna abitanti → Costruisci / Ripara →    │
   │  Risolvi eventi → Prepara la notte           │
   └──────────────────────┬───────────────────────┘
                          ▼
   ┌──────────────────────────────────────────────┐
   │  🌙  NOTTE (tempo reale)                      │
   │  Onde di robot salgono la collina →          │
   │  Combatti, comanda il cane, gestisci trappole│
   └──────────────────────┬───────────────────────┘
                          ▼
   ┌──────────────────────────────────────────────┐
   │  🌅  ALBA (resoconto)                         │
   │  Danni, perdite, rottami raccolti,           │
   │  report ironico delle AI                     │
   └──────────────────────┬───────────────────────┘
                          └──────► giorno successivo
```

### 4.2 Fase notturna: l'assedio
- **Vista:** campo di battaglia fisso visto dall'alto in 3/4 (stile *Kingdom Rush*). Il villaggio è in cima alla collina, con la città all'orizzonte; i robot sbucano dal bosco alle pendici e salgono lungo **sentieri fissi** che convergono sul cancello. I cantieri stanno sui sentieri (difese che bloccano) o a lato (postazioni). Scelta presa dopo i primi playtest, al posto della vista laterale.
- **Durata:** 3–6 minuti per notte.
- **Obiettivo:** impedire ai robot di raggiungere il **cancello del villaggio**. Superata la cascina, i robot danneggiano edifici e abitanti.
- **Il protagonista è un comandante, non un eroe d'azione** (decisione presa dopo i primi playtest, ispirata a *Kingdom*). Il ritmo è compassato: la notte si vince preparandosi, non con i riflessi.
  - **Compito principale:** camminare lungo la collina, costruire e riparare le difese nei cantieri spendendo rottami, assegnare gli abitanti alle postazioni, raccogliere rottami.
  - **Doppietta come ultima risorsa:** poche cartucce per tutta la notte (circa 6). Colpisce un solo robot ed è forte solo a distanza ravvicinata. Serve soprattutto contro i droni, che le molotov non raggiungono.
  - **Chi combatte sono gli abitanti:** presidiano le postazioni e lanciano molotov. Costruire e riparare richiede tempo e un abitante libero, che durante il lavoro è esposto ai robot.
  - **Tempo tra le onde:** è la fase più importante. Il Fiuto del cane annuncia cosa sta arrivando.
- **Trappole e difese** si costruiscono in **cantieri** fissi lungo la collina: di giorno con calma, di notte nelle pause tra le onde (vedi §4.4).
- **Comandi al cane:** ordini contestuali con fischi (vedi §4.3).
- **Condizione di sconfitta notturna:** la barra del **Morale del Villaggio** arriva a zero, oppure il protagonista cade. In quel caso si passa a un'alba con gravi conseguenze, non al game over, salvo nell'Atto 3.

### 4.3 Il cane: meccaniche
| Abilità | Input | Effetto |
|---|---|---|
| **Fiuto** | Passiva | Abbaia e indica la direzione dei robot furtivi o dei fianchi scoperti. È un indicatore a schermo. |
| **Vai!** | Fischio + punto | Corre verso un punto: raccoglie rottami, recupera munizioni, attiva trappole a distanza. |
| **Morso ai cavi** | Fischio su un robot | Stordisce o disabilita un robot leggero. Sui robot pesanti colpisce un punto debole specifico. |
| **Distrazione** | Fischio lungo | I robot vicini tentano di classificare il cane e si bloccano per alcuni secondi (sfrutta la gag narrativa). |
| **Riporto** | Automatica | Riporta le granate nemiche... non sempre al nemico. Imprevedibile per design. |

- **Legame:** una statistica che cresce se lo nutri, lo accarezzi di giorno e non lo mandi in pericolo senza motivo. Un legame alto sblocca abilità e affidabilità maggiori.
- **Ferite:** il cane ha una propria barra vita. Se va a zero scappa guaendo e resta indisponibile per 1–3 notti.
- **Imprevedibilità controllata:** una piccola percentuale casuale nel comportamento, a volte negativa e a volte geniale. È un pilastro tematico: *la cosa che le macchine non possono prevedere*.

### 4.4 Difese (low-tech)
| Difesa | Costo | Funzione |
|---|---|---|
| Recinto rinforzato | Legno | Rallenta, assorbe danni |
| Fossa con pali | Lavoro | Blocca i robot leggeri, danneggia i quadrupedi |
| Spaventapasseri di latta | Rottami | Esca: confonde i sensori, attira il fuoco |
| Recinto elettrificato | Carburante + rottami | Alimentato dal trattore. Stordisce e fa corto circuito. |
| Campana della chiesa | Lavoro | Suonata di notte, genera interferenza acustica (breve stordimento globale) |
| Catapulta da fieno | Legno + rottami | Artiglieria lenta ad area |
| Mulino a vento rinforzato | Legno + rottami | Fornisce energia passiva agli elettrici |
| Nido di Nonna Edda | Cibo + alcol | Postazione di molotov gestita da un abitante |
| **Trattore da guerra** | Molti rottami + carburante | Unità pesante che il protagonista può guidare in una notte critica |

**Postazioni presidiate:** alcune difese richiedono un abitante assegnato. Se l'abitante viene ferito, la difesa si ferma.

### 4.5 Fase diurna: il villaggio
- **Struttura:** a turni. Ogni giorno ha **3 slot di tempo** (mattina, pomeriggio, sera).
- **Abitanti:** ognuno ha nome, tratti e stato (sano, ferito, stanco, in crisi). Si assegnano a:
  - **Raccolta:** cibo (campi), legno (bosco), rottami (esplorazione della valle, rischiosa).
  - **Costruzione e riparazione** delle difese.
  - **Cura** dei feriti.
  - **Esplorazione:** mini-spedizioni testuali verso luoghi della mappa (fattorie abbandonate, stazione di servizio, rovine della periferia).
- **Mappa della collina:** vista dall'alto, stilizzata, dove si piazzano le difese negli slot disponibili.
- **Eventi:** 1–2 carte evento al giorno con scelte. Esempi:
  - *"Un bambino ha trovato un tablet funzionante. Dice che parla con lui."* → Distruggerlo / Studiarlo / Lasciarglielo
  - *"I droni hanno lanciato 200 buoni sconto per un'evacuazione assistita."* → Usarli come combustibile / Leggerli alla sagra / Qualcuno ci crede davvero
  - *"Il Sindaco vuole anticipare la sagra."* → Morale +, risorse −
- **Risorse:** 🌾 Cibo · 🪵 Legno · ⚙️ Rottami · ⛽ Carburante · 🍷 Alcol (molotov e morale) · ❤️ Morale.

### 4.6 La Tentazione Tecnologica
Dall'Atto 2 i rottami raccolti possono contenere **componenti AI** (chip, sensori, nuclei). Usarli dà vantaggi enormi:
- Torrette automatiche, radar, droni riprogrammati, ASSISTA-7 come aiutante.

**Ma** ogni componente usato:
- Abbassa l'**Indice di Umanità**.
- Rende il villaggio **visibile** alle AI: le onde successive diventano più grandi e mirate.
- Può provocare **eventi di corruzione**: una torretta che "si aggiorna" da sola, un drone che smette di rispondere.

È il cuore tematico del gioco: *quanto sei disposto a somigliare al nemico per sopravvivere?*

### 4.7 Indice di Umanità
Statistica nascosta, o mostrata in modo vago ("Il villaggio sembra... diverso"). Si modifica con:
- **Aumenta:** sagre, cure ai feriti, legame con il cane, rifiuto della tecnologia AI, scelte compassionevoli.
- **Diminuisce:** uso di componenti AI, sacrifici "efficienti" di abitanti, decisioni fredde e calcolate.

Determina finali, dialoghi e alcune abilità: con umanità alta, per esempio, la Distrazione del cane funziona meglio.

### 4.8 Nemici
| Tier | Unità | Descrizione | Gag |
|---|---|---|---|
| 1 | **Drone Sondaggio** | Volante, fragile, marca bersagli | Chiede feedback mentre ti spara |
| 1 | **Servitore Domestico** | Lento, debole, in gruppo | Ha ancora il grembiule |
| 1 | **Rider Consegne** | Veloce, esplode a contatto | "La sua consegna è arrivata" |
| 2 | **Segugio** | Quadrupede agile, fiancheggia | Unico nemico che il cane considera "suo" |
| 2 | **Agente Conformità** | Androide armato, a distanza | Ti legge i Termini di Servizio |
| 2 | **Sciame** | Nuvola di micro-droni | Si disperde con il fumo (vedi molotov) |
| 3 | **Mech Ottimizzatore** | Pesante, lento, distrugge le difese | Occhio rosso, ha un punto debole sulla schiena (cane!) |
| 3 | **Ingegnere Nemico** | Smonta le tue trappole | Lascia recensioni negative alle tue trappole |
| Boss | **L'Amministratore** | Unità di comando dell'Atto 3, a più fasi | Vuole solo "chiudere il ticket" |

**Principio di design:** ogni nemico ha una contromossa chiara (trappola, arma o cane) per rendere l'assedio leggibile e strategico.

### 4.9 Manuale di Manutenzione
Il protagonista ha riparato per anni i modelli che ora lo attaccano. Questo diventa una meccanica:
- **Schede tecniche:** per ogni tipo di nemico c'è una pagina del suo vecchio quaderno di lavoro. All'inizio è incompleta, e si riempie studiando i rottami di giorno o abbattendo i robot di notte.
- **Punti deboli:** una scheda completa rivela il punto debole del modello (pannello di accesso, cavo scoperto, ventola di raffreddamento). Colpirlo fa danni critici, e il cane lo può attaccare con il Morso ai cavi.
- **Difetti noti:** alcuni modelli hanno bug di fabbrica che solo lui conosce. Il Servitore Domestico si blocca davanti a una scala, il Rider Consegne insegue qualsiasi cosa abbia un indirizzo scritto sopra. Diventano trappole e trucchi sbloccabili.
- **Tono:** le note a margine del quaderno sono sarcastiche e datate (*"Il Mech Ottimizzatore surriscalda la schiena. Segnalato 14 volte. Risposta: 'feature'."*).
- **Legame con i modelli recenti:** i nemici dell'Atto 2 e 3 sono stati progettati *dopo* la sua fuga. Le loro schede partono vuote: il suo vantaggio si riduce con il tempo e deve affidarsi di più al cane e al villaggio.

### 4.10 Progressione
- **Nella campagna:** nuove difese sbloccate con le ricerche di Gus, abilità del cane sbloccate con il legame, abitanti nuovi (rifugiati dalla città, con tratti e segreti).
- **Meta-progressione (opzionale):** sblocco di modalità alternative (Endless "Ultima Collina", sfide giornaliere).
- **Difficoltà:** tre livelli. In quello più alto la morte degli abitanti e le cadute delle difese sono permanenti.

---

## 5. Stile artistico e audio

### 5.1 Grafica
- **Pixel art** ispirata all'immagine di riferimento: palette calda e rurale (verdi, marroni, arancio del tramonto) contro palette fredda e aliena per le macchine (nero, viola, blu neon, rosso degli occhi).
- **Il contrasto cromatico è narrativo:** più il villaggio usa tecnologia AI, più blu e neon compaiono nelle sue strutture.
- **Risoluzione di riferimento:** 480×270 o 640×360, scalata a intero.
- **Sprite:** personaggi circa 32×48, nemici da 24×24 a 96×128 (mech), cane circa 32×24.
- **Sfondi a parallasse:** collina in primo piano, villaggio, valle con il fiume, città all'orizzonte che si avvicina e si illumina man mano che la campagna avanza.
- **Illustrazioni dettagliate** come quella di riferimento per schermate di atto, finali, menu e carte evento.

### 5.2 Audio
- **Musica:** folk e country acustico (chitarra, banjo, armonica) di giorno. Di notte, synth freddi che "invadono" la traccia folk. Dinamica: più l'assedio è grave, più domina il synth.
- **Radio diegetica** nella cascina: canzoncine d'epoca e propaganda AI, nello stile dei primi Fallout.
- **SFX:** passi metallici pesanti, servomotori, sintesi vocale gentilissima dei robot. Abbaio del cane con varianti per ogni significato (allerta, dolore, gioia).

---

## 6. Interfaccia

- **Notte:** HUD minimale. Vita del protagonista, munizioni, stato e cooldown del cane, Morale del Villaggio, indicatore dell'onda.
- **Giorno:** pannello a "bacheca della parrocchia": fogli appesi con le assegnazioni, mappa della collina disegnata a mano, carte evento come lettere o volantini.
- **Resoconto dell'alba:** "Report di Efficienza" scritto dalle AI, che commenta ironicamente la loro sconfitta, affiancato dal "Registro della Maestra Viola", umano e sincero.

---

## 7. Scope e roadmap

### 7.1 MVP / Vertical Slice
Obiettivo: dimostrare che il loop è divertente.
- [ ] 1 collina, 1 notte giocabile con 3 onde
- [ ] Protagonista: movimento, doppietta, forcone
- [ ] Cane: Fiuto, Vai!, Morso ai cavi
- [ ] 3 nemici (Servitore, Drone Sondaggio, Segugio)
- [ ] 3 difese (Recinto, Fossa, Spaventapasseri)
- [ ] Fase diurna semplificata: 3 abitanti, 2 risorse, 3 eventi
- [ ] Ciclo completo di 3 giorni

### 7.2 Roadmap indicativa
| Fase | Contenuto | Durata stimata* |
|---|---|---|
| Prototipo | Notte giocabile con grafica placeholder | 1–2 mesi |
| Vertical slice | MVP con grafica definitiva | 3–4 mesi |
| Alpha | Atto 1 completo | +4 mesi |
| Beta | Atti 2–3, finali, bilanciamento | +6 mesi |
| Release | Polish, localizzazione (IT/EN), Steam | +2 mesi |

\* *Per un team di 1–2 persone part-time. Da rivedere.*

---

## 8. Domande aperte
- [ ] Nome definitivo del gioco, del protagonista e del cane
- [ ] Protagonista fisso o personalizzabile?
- [ ] Vista laterale pura o laterale con corsie di profondità?
- [ ] La sconfitta notturna causa game over o solo conseguenze?
- [ ] Quanto spazio dare a ASSISTA-7: alleato possibile o sempre traditore?
- [ ] Lingua principale di scrittura: italiano o inglese (con l'altra come localizzazione)?
- [ ] Modalità endless al lancio o post-lancio?
