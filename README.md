# jms_battery

psychTestR-Testbatterie für die JMS-Studie DELTA-M (R-Paket `jmsbattery`, Sprache: Deutsch, du-Form;
die Elternfragen in Sie-Form).

## Ablauf (Stand 2026-11-18)

CSA (Cup Song Assessment) und die BOT-2-Feinmotorik laufen vorher vor Ort ohne Computer und
gehören nicht zur App.

**Start und Tests**

| # | Modul | Inhalt | Paket |
|---|-------|--------|-------|
| 1 | Begrüßung, Teilnahmecode | 8 Ziffern mit Prüfziffer (siehe unten) | |
| 2 | DEG | Alter (Monat/Jahr), Geschlecht, Land der prägenden Jahre, Erst- und Zweitsprache | psyquest |
| 3 | INS | Hauptinstrument (freie Angabe); weitere Instrumente ja/nein, wenn ja bis zu drei (das erste Pflicht); Unterrichtsbeginn auf dem Hauptinstrument (Monat/Jahr) | eigene Seiten |
| 4 | Lautstärkeeinstellung | | |
| 5 | DMT | Drum Machine Test (für die Kinder „Schlagzeug-Test“ mit „digitalem Schlagzeug“, ab DMT 0.2.4), 2 Übungs- und 5 Haupttrials, je bis zu 4 Versuche mit Feedback | DMT |
| 6 | JAJ | Jack & Jill (Arbeitsgedächtnis), 8 Items | JAJ |
| 7 | MIQ | Matrizen (Reasoning), 8 Items | MIQ |
| 8 | BAT | CA-BAT (Beat-Wahrnehmung), 20 Items | cabat |
| 9 | RAT | Rhythm Ability Test (Rhythmusgedächtnis), 14 Items | RAT |
| 10 | MPT | Mistuning Perception Test (Intonationswahrnehmung), 20 Items | mpt |

Danach steht `JMS$tests_complete = TRUE` in der Ergebnisdatei.

**Fragebögen.** Eine Zwischenseite kündigt sie an und sagt, dass man sie auch zu Hause
ausfüllen kann.

| # | Modul | Inhalt | Paket |
|---|-------|--------|-------|
| 11 | UEB | Unterricht auf dem Hauptinstrument in Minuten pro Woche, getrennt nach Einzel- und Ensembleunterricht | eigene Seite |
| 12 | CCM | Concurrent Musical Activities (inkl. Musizierzeit pro Woche) | psyquest |
| 13 | GMS | Gold-MSI, 23 Items der Kurzversion: ohne Item 32 („Das Instrument, welches ich am besten spiele“), Item 22 („Ich kann ___ verschiedene Instrumente spielen“) und die Singing-Abilities-Items 8, 11, 23, 33. Die Subskalen „Instrument“ und „Singing Abilities“ entfallen; „General“ (10 statt 18 Items) und „Musical Training“ (4 statt 7) sind dadurch **nicht normvergleichbar** | psyquest |
| 14 | TOM | Theory of Musicality | psyquest |
| 15 | GRT | Grit (Selbstauskunft) | psyquest |
| 16 | MHE | Musical Home Environment | psyquest |
| 17 | SES | Bildungsabschluss der Eltern und Beruf (ESeC), füllen die Eltern aus | psyquest |

Vor SES bittet eine Seite das Kind, das Gerät an die Eltern weiterzugeben. Die SES-Texte
stammen aus psyquests formeller Fassung (`de_f`). Die beiden Bildungsfragen sind auf
„die Mutter / der Vater Ihres Kindes“ umformuliert. Erst nach SES ist die Sitzung
`complete=true`.

Gespeichert wird nach jedem Modul.

### Fortsetzen zu Hause

Wer denselben Teilnahmecode noch einmal eingibt, macht in seiner Sitzung genau dort weiter,
wo er aufgehört hat, auch auf einem anderen Gerät. Alles landet in derselben Ergebnisdatei.
Ein neuer Durchgang startet stattdessen, wenn

- die Sitzung schon bis zum Ende durchlaufen ist, oder
- sie zuletzt vor mehr als `resume_days` Tagen (Standard 14) benutzt wurde, etwa in der
  nächsten Welle.

psychTestR zeigt beim Fortsetzen kurz die englische Meldung „Resuming previous session.“.
Die Sitzungsdaten liegen in `output/sessions/` und werden nach 31 Tagen gelöscht
(`session_timeout_min`).

Für die Testleitung heißt das: Jedes Kind muss mit der **sauberen Adresse ohne `?p_id=…`**
starten. Steht noch die Adresse des vorherigen Kindes im Browser, setzt psychTestR dessen
Sitzung fort.

### Teilnahmecode

8 Ziffern: 2 für die Lehrkraft, 4 für die Laufnummer, 2 Prüfziffern. Die Prüfziffern sind die
zweistellige Quersumme der ersten sechs Ziffern, z. B. `01000102`. Andere Codes lehnt die
Eingabeseite ab. `is_valid_jms_id()` prüft genauso wie der Battery Monitor.

### DMT mit leichten Items

Weil Kinder getestet werden, zieht der DMT seine Haupttrials vor allem aus der leichten
Itembank (`jms_dmt_allocation`):

| Stratum | Trials |
|---|---|
| easy_easy (leichte Itembank, leichtere Hälfte) | 3 |
| easy_hard (leichte Itembank, schwerere Hälfte) | 1 |
| normal_easy (normale Itembank, leichtere Hälfte) | 1 |
| normal_hard (normale Itembank, schwerere Hälfte) | 0 |

## Installation

```r
remotes::install_github(c("pmcharrison/psychTestR", "klausfrieler/psyquest",
                          "klausfrieler/JAJ", "pmcharrison/cabat",
                          "klausfrieler/RAT", "pmcharrison/mpt",
                          "antonskrywer/DMT"))
devtools::install()   # im Repo-Verzeichnis
```

MIQ ist auf dem Server vorinstalliert und steht nur unter `Suggests`. Fehlt es,
bricht `jms_battery()` mit einer Fehlermeldung ab. Nur mit `debug = TRUE` wird MIQ dann mit
einer Warnung weggelassen.

## Start

```r
library(jmsbattery)
jms_battery(admin_password = "...")           # lokal: shiny::runApp(jms_battery())
jms_battery(debug = TRUE)                      # je 1 Item, 1 DMT-Trial, ohne Training
jms_battery(num_items = c(JAJ = 8, MIQ = 8, BAT = 20, RAT = 14, MPT = 20))
jms_battery(dmt_allocation = c(easy_easy = 2, easy_hard = 2, normal_easy = 1, normal_hard = 0))
jms_battery(dmt_feedback = FALSE)              # DMT mit nur einem Versuch pro Trial
jms_battery(home_url = "https://…/jms_battery") # Adresse auf der Fragebogen-Zwischenseite
```

Für Shiny Server liegt `app.R` im Repo-Root. Sie liest das Admin-Passwort aus
der Umgebungsvariable `JMS_ADMIN_PASSWORD` (auf dem Server in
`/home/shiny/.Renviron`) und startet ohne sie nicht. Optional setzt `JMS_HOME_URL`
die Adresse für die Zwischenseite. Ergebnisse landen in `output/results/` (nicht versioniert).

## Ergebnisse einlesen

```r
library(jmsbattery)
d <- read_jms_results("output/results")
d <- read_jms_results("output/results", complete_only = TRUE, scales = c("GMS", "GRT"))
```

Eine Zeile pro Sitzung. Spalten: `p_id`, `valid_id`, `complete`, `tests_complete`,
`time_started`, `time_last_saved`, `num_restarts`, `file`, `DEG.*` (Geschlecht,
Geburtsmonat/-jahr, Alter in Monaten und Jahren, Land der prägenden Jahre,
Erst-/Zweitsprache), `INS.*` (Hauptinstrument, weitere Instrumente `INS.instrument_2` bis
`_4`, Anzahl `INS.num_instruments`, Unterrichtsbeginn), `UEB.*` (Minuten pro
Woche einzeln/Ensemble), `JAJ/MIQ/BAT/RAT/MPT.ability` und die Subskalen von CCM, GMS,
TOM, GRT, MHE und SES. Nicht erreichte Module sind `NA`.

Der DMT hat keinen Ability-Wert. Seine Trial-Daten stehen in `r$DMT` und
lassen sich pro Person mit dem DMT-Paket in Langformat bringen:

```r
r <- readRDS("output/results/....rds")
DMT::DMT_results_to_long(r$DMT, p_id = r$session$p_id)   # eine Zeile pro Versuch
```

## Hinweise

- Gegenüber Version 0.1 sind RAT, MPT und der optionale Zusatzteil weggefallen; GRT ist jetzt fester Fragebogen (statt TPI).
  CCM gehört jetzt fest zu den Fragebögen.
- Der Battery Monitor (`jms_battery_monitor`) kennt den neuen Aufbau noch nicht.
- Der DMT läuft mit `with_final_page = FALSE` (ab DMT 0.2.2), damit er die
  Batterie nicht beendet. `dmt_module()` legt ihn in einen eigenen
  Ergebnisabschnitt `DMT`.
- Die Eingabeseite für den Code nutzt interne psychTestR-Funktionen (`try_resume_session`,
  `safe_load_session`, `read_timestamp`, `increment_elt_index`), getestet mit psychTestR 2.27.3.
- Das Standard-Admin-Passwort `jms_admin` von `jms_battery()` gilt nur beim
  lokalen Testen; `app.R` nutzt immer `JMS_ADMIN_PASSWORD`.
