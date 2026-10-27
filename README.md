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
| 7 | GMS | Gold-MSI, Kurzversion (`short_version = TRUE`, 29 Items) | psyquest |
| 8 | TOM | Musical Growth Mindset, 12 Items | psyquest |

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
                          "pmcharrison/cabat", "pmcharrison/mpt"))
devtools::install()   # im Repo-Verzeichnis
```

## Start

```r
library(jmsbattery)
jms_battery(admin_password = "...")          # lokal: shiny::runApp(jms_battery())
jms_battery(debug = TRUE)                     # je 1 Item, ohne Training, zum Durchklicken
jms_battery(extras = c("MPT"))                # nur MPT als Zusatz
jms_battery(extras = character())             # ohne Zusatzteil
jms_battery(num_items = c(RAT = 14, BAT = 20, JAJ = 8, MPT = 20))
```

Für Shiny Server liegt `app.R` im Repo-Root. Ergebnisse landen in `output/results/`
(nicht versioniert).

## Hinweise

- MIQ ist nicht enthalten (kein verfügbares Paket).
- Das Standard-Admin-Passwort `jms_admin` vor dem Einsatz ändern.
