# jms_battery

psychTestR-Testbatterie für die JMS-Studie (R-Paket `jmsbattery`, Sprache: Deutsch, du-Form).

## Ablauf

**Pflichtteil**

| # | Modul | Inhalt | Paket |
|---|-------|--------|-------|
| 1 | Begrüßung, Teilnahmecode | | |
| 2 | DEG | Alter (Monat/Jahr), Geschlecht, Nationalität, Erst- und Zweitsprache | psyquest |
| 3 | Lautstärkeeinstellung | | |
| 4 | RAT | Rhythm Ability Test, 14 Items | RAT |
| 5 | BAT | Computerised Beat Alignment Test, 20 Items | cabat |
| 6 | JAJ | Jack & Jill Working Memory, 8 Items | JAJ |
| 7 | DMT | Drum Machine Test, 2 Übungs- und 5 Haupttrials, je bis zu 4 Versuche mit Feedback | DMT |
| 8 | GMS | Gold-MSI, Kurzversion (`short_version = TRUE`, 29 Items) | psyquest |
| 9 | TOM | Musical Growth Mindset, 12 Items | psyquest |

Nach TOM ist die Sitzung als `complete=true` gespeichert.

**Zusatzteil (optional).** Eine Seite fragt, ob noch 10–15 Minuten Zeit sind.
„Nein“ beendet die Sitzung, „Ja“ führt zu:

| Modul | Inhalt | Paket |
|-------|--------|-------|
| GRT | Grit | psyquest |
| CCM | Concurrent Musical Activities | psyquest |
| MPT | Mistuning Perception Test, 20 Items (divergente Validität) | mpt |

Nach jedem Modul wird gespeichert, ein Abbruch im Zusatzteil verliert also nichts.
Die Entscheidung steht in den Ergebnissen unter `results$extras_choice`.

Die adaptiven Tests zeigen ihre Übungsitems, aber kein Score-Feedback.

## Installation

```r
remotes::install_github(c("pmcharrison/psychTestR", "klausfrieler/psyquest",
                          "klausfrieler/RAT", "klausfrieler/JAJ",
                          "pmcharrison/cabat", "pmcharrison/mpt",
                          "antonskrywer/DMT"))
devtools::install()   # im Repo-Verzeichnis
```

## Start

```r
library(jmsbattery)
jms_battery(admin_password = "...")          # lokal: shiny::runApp(jms_battery())
jms_battery(debug = TRUE)                     # je 1 Item, ohne Training, zum Durchklicken
jms_battery(extras = c("MPT"))                # nur MPT als Zusatz
jms_battery(extras = character())             # ohne Zusatzteil
jms_battery(num_items = c(RAT = 14, BAT = 20, JAJ = 8, DMT = 5, MPT = 20))
jms_battery(dmt_feedback = FALSE)             # DMT mit nur einem Versuch pro Trial
```

Für Shiny Server liegt `app.R` im Repo-Root. Sie liest das Admin-Passwort aus
der Umgebungsvariable `JMS_ADMIN_PASSWORD` (auf dem Server in
`/home/shiny/.Renviron`) und startet ohne sie nicht. Ergebnisse landen in
`output/results/` (nicht versioniert).

## Ergebnisse einlesen

```r
library(jmsbattery)
d <- read_jms_results("output/results")                    # DEG, Abilities, GMS
d <- read_jms_results("output/results", complete_only = TRUE,
                      scales = c("GMS", "TOM", "GRT", "CCM"))
```

Eine Zeile pro Sitzung. Spalten: `p_id`, `complete`, `time_started`,
`time_last_saved`, `file`, `DEG.*` (Geschlecht, Geburtsmonat/-jahr, Alter in
Monaten und Jahren zum Testzeitpunkt, Nationalität, Erst-/Zweitsprache),
`RAT/BAT/JAJ/MPT.ability`, `GMS.*` (alle Subskalen) und `extras_choice`.
Nicht erreichte Module sind `NA`.

Der DMT hat keinen Ability-Wert. Seine Trial-Daten stehen in `r$DMT` und
lassen sich pro Person mit dem DMT-Paket in Langformat bringen:

```r
r <- readRDS("output/results/....rds")
DMT::DMT_results_to_long(r$DMT, p_id = r$session$p_id)   # eine Zeile pro Versuch
```

## Hinweise

- MIQ ist nicht enthalten (kein verfügbares Paket).
- Der DMT läuft mit `with_final_page = FALSE` (ab DMT 0.2.2), damit er die
  Batterie nicht beendet. `dmt_module()` legt ihn in einen eigenen
  Ergebnisabschnitt `DMT`.
- Das Standard-Admin-Passwort `jms_admin` von `jms_battery()` gilt nur beim
  lokalen Testen; `app.R` nutzt immer `JMS_ADMIN_PASSWORD`.
