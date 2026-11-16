# psychTestR treats elements outside a timeline as English-only, so the
# battery's own (German) pages are wrapped in a timeline with a minimal dict.
jms_dict <- psychTestR::i18n_dict$new(
  data.frame(key = "JMS_BATTERY", de = "JMS Testbatterie", stringsAsFactors = FALSE)
)

de_timeline <- function(...) {
  psychTestR::new_timeline(psychTestR::join(...), dict = jms_dict)
}

welcome_page <- function() {
  psychTestR::one_button_page(
    body = shiny::div(
      shiny::h4("Herzlich willkommen!"),
      shiny::p("Vielen Dank, dass du an unserer Studie teilnimmst. ",
               "Zuerst bearbeitest du ein paar Hör-, Rhythmus- und Denkaufgaben, ",
               "danach beantwortest du einige Fragen zu dir und deinem Musizieren."),
      shiny::p("Bitte nutze Kopfhörer und sorge für eine ruhige Umgebung.")
    ),
    button_text = "Weiter"
  )
}

# ---- Participation code ----

#' Check JMS participation codes
#'
#' A valid code has 8 digits: 2 digits teacher code, 4 digits running number
#' and 2 check digits, which are the digit sum of the first six digits
#' (two-digit, e.g. `01000102`). The same rule is used by the battery monitor.
#' @param id Character vector of codes.
#' @return Logical vector.
#' @export
is_valid_jms_id <- function(id) {
  id <- trimws(as.character(id))
  ok <- !is.na(id) & grepl("^[0-9]{8}$", id)
  ok[ok] <- vapply(id[ok], function(x) {
    d <- as.integer(strsplit(x, "")[[1]])
    sum(d[1:6]) == d[7] * 10 + d[8]
  }, logical(1), USE.NAMES = FALSE)
  ok
}

# Like psychTestR::get_p_id(), but with the check-digit validation and a
# resume rule: an unfinished session that was used in the last `resume_days`
# days is resumed without asking (psychTestR's own confirmation dialog is in
# English and its "Cancel" would restart the tests). Otherwise a new session
# starts under this code.
id_page <- function(resume_days) {
  psychTestR::page(
    ui = shiny::div(
      shiny::p("Bitte gib hier deinen persönlichen Teilnahmecode ein (8 Ziffern)."),
      shiny::p("Wenn du schon angefangen hast, machst du mit demselben Code dort weiter, ",
               "wo du aufgehört hast.", style = "font-size:90%;color:#666"),
      shiny::textInput("p_id", label = NULL, placeholder = "Teilnahmecode", width = "300px"),
      psychTestR::trigger_button("next", "Weiter")
    ),
    get_answer = function(input, ...) trimws(input$p_id),
    save_answer = FALSE,
    validate = function(answer, ...) {
      if (is_valid_jms_id(answer)) TRUE
      else paste("Dieser Teilnahmecode ist nicht gültig. Bitte prüfe ihn noch einmal",
                 "(8 Ziffern, ohne Leerzeichen).")
    },
    on_complete = function(state, session, opt, ...) {
      p_id <- psychTestR::answer(state)
      if (session_resumable(p_id, opt, resume_days) &&
          psychTestR:::try_resume_session(p_id, state, session, opt,
                                          ask_to_confirm_resume = FALSE,
                                          reset_if_resume_fails = FALSE)) {
        return(invisible(NULL))
      }
      state$passive$p_id <- p_id
      psychTestR::set_url_param(key = "p_id", value = p_id, session = session, state = state)
      psychTestR:::increment_elt_index(state)
    },
    next_elt = FALSE
  )
}

session_resumable <- function(p_id, opt, resume_days) {
  data <- psychTestR:::safe_load_session(p_id, opt)
  if (is.null(data) || isTRUE(data$passive$globals$jms_finished)) return(FALSE)
  last_used <- psychTestR:::read_timestamp(opt, p_id)
  is.na(last_used) ||
    difftime(Sys.time(), last_used, units = "days") <= resume_days
}

# ---- Instrument and lessons ----

month_names <- c("Januar", "Februar", "März", "April", "Mai", "Juni", "Juli",
                 "August", "September", "Oktober", "November", "Dezember")

instrument_module <- function() {
  psychTestR::join(
    psychTestR::begin_module("INS"),
    psychTestR::text_input_page(
      label = "instrument",
      prompt = shiny::div(
        shiny::p("Was ist dein Hauptinstrument?"),
        shiny::p("Das ist das Instrument, das du an der Jugendmusikschule hauptsächlich lernst. ",
                 "Gesang zählt auch als Instrument.",
                 style = "font-size:90%;color:#666")
      ),
      placeholder = "z. B. Klavier",
      button_text = "Weiter",
      validate = function(answer, ...) {
        if (nchar(trimws(answer)) > 0) TRUE else "Bitte gib dein Hauptinstrument an."
      }
    ),
    psychTestR::NAFC_page(
      label = "has_further_instruments",
      prompt = shiny::div(
        shiny::p("Spielst du außer deinem Hauptinstrument noch weitere Instrumente?"),
        shiny::p("Auch außerhalb der Jugendmusikschule. Gesang zählt auch.",
                 style = "font-size:90%;color:#666")
      ),
      choices = c("yes", "no"),
      labels = c("Ja", "Nein")
    ),
    psychTestR::conditional(
      test = function(state, ...) identical(psychTestR::answer(state), "yes"),
      logic = further_instruments_page()
    ),
    lesson_start_page(),
    psychTestR::end_module()
  )
}

# Up to three further instruments; the first is required, the others optional.
further_instruments_page <- function() {
  fields <- c(instrument_2 = "Zweites Instrument",
              instrument_3 = "Drittes Instrument (falls vorhanden)",
              instrument_4 = "Viertes Instrument (falls vorhanden)")
  psychTestR::page(
    ui = shiny::div(
      shiny::p("Welche weiteren Instrumente spielst du?"),
      shiny::div(
        style = "max-width:300px;margin:auto;text-align:left",
        lapply(names(fields), function(id) {
          shiny::textInput(id, fields[[id]], width = "300px")
        })
      ),
      psychTestR::trigger_button("next", "Weiter")
    ),
    label = "further_instruments",
    get_answer = function(input, ...) {
      vapply(names(fields), function(id) trimws(input[[id]] %||% ""), character(1))
    },
    validate = function(answer, ...) {
      if (nzchar(answer[["instrument_2"]])) TRUE else "Bitte gib mindestens ein weiteres Instrument an."
    },
    on_complete = function(answer, state, ...) {
      for (id in names(answer)) {
        if (nzchar(answer[[id]])) psychTestR::save_result(state, id, answer[[id]])
      }
    }
  )
}

`%||%` <- function(x, y) if (is.null(x)) y else x

lesson_start_page <- function() {
  this_year <- as.integer(format(Sys.Date(), "%Y"))
  years <- as.character(this_year:(this_year - 15))
  psychTestR::page(
    ui = shiny::div(
      shiny::p("Seit wann hast du Unterricht auf deinem Hauptinstrument?"),
      shiny::p("Wenn du es nicht genau weißt, schätze bitte.",
               style = "font-size:90%;color:#666"),
      shiny::div(
        style = "display:flex;gap:12px;justify-content:center",
        shiny::selectInput("lesson_month", "Monat",
                           choices = c("Bitte wählen" = "", stats::setNames(1:12, month_names)),
                           width = "160px"),
        shiny::selectInput("lesson_year", "Jahr",
                           choices = c("Bitte wählen" = "", years), width = "130px")
      ),
      psychTestR::trigger_button("next", "Weiter")
    ),
    label = "lesson_start",
    get_answer = function(input, ...) {
      c(month = as.integer(input$lesson_month), year = as.integer(input$lesson_year))
    },
    validate = function(answer, ...) {
      if (length(answer) < 2 || anyNA(answer)) return("Bitte wähle Monat und Jahr aus.")
      start <- as.Date(sprintf("%d-%02d-01", answer[["year"]], answer[["month"]]))
      if (start > Sys.Date()) "Dieser Zeitpunkt liegt in der Zukunft." else TRUE
    },
    on_complete = function(answer, state, ...) {
      psychTestR::save_result(state, "lesson_start_month", answer[["month"]])
      psychTestR::save_result(state, "lesson_start_year", answer[["year"]])
    }
  )
}

lesson_time_module <- function() {
  psychTestR::join(
    psychTestR::begin_module("UEB"),
    lesson_time_page(),
    psychTestR::end_module()
  )
}

# Lesson time on the instrument only, in minutes per week.
lesson_time_page <- function() {
  psychTestR::page(
    ui = shiny::div(
      shiny::p("Wie viele Minuten Unterricht auf deinem Hauptinstrument hast du ",
               "normalerweise pro Woche?"),
      shiny::p("Gib 0 ein, wenn du diese Art von Unterricht nicht hast.",
               style = "font-size:90%;color:#666"),
      shiny::div(
        style = "display:flex;gap:24px;justify-content:center;text-align:left",
        shiny::numericInput("individual_min", "Einzelunterricht (Minuten pro Woche)",
                            value = NA, min = 0, max = 600, step = 5, width = "220px"),
        shiny::numericInput("ensemble_min",
                            "Ensemble- oder Gruppenunterricht (Minuten pro Woche)",
                            value = NA, min = 0, max = 600, step = 5, width = "220px")
      ),
      psychTestR::trigger_button("next", "Weiter")
    ),
    label = "lesson_minutes",
    get_answer = function(input, ...) {
      c(individual = as.numeric(input$individual_min),
        ensemble = as.numeric(input$ensemble_min))
    },
    validate = function(answer, ...) {
      if (length(answer) < 2 || anyNA(answer)) return("Bitte fülle beide Felder aus (0, wenn nicht zutreffend).")
      if (any(answer < 0 | answer > 600)) return("Bitte gib Werte zwischen 0 und 600 Minuten ein.")
      TRUE
    },
    on_complete = function(answer, state, ...) {
      psychTestR::save_result(state, "individual_min_week", answer[["individual"]])
      psychTestR::save_result(state, "ensemble_min_week", answer[["ensemble"]])
    }
  )
}

# ---- Other pages ----

volume_page <- function() {
  psychTestR::volume_calibration_page(
    prompt = shiny::div(
      shiny::h4("Lautstärkeeinstellung"),
      shiny::p("Du solltest nun etwas hören. Bitte stelle eine angenehme Lautstärke ein, ",
               "bevor du fortfährst.",
               style = "margin-left:20%;margin-right:20%;text-align:center")
    ),
    url = "https://s3-eu-west-1.amazonaws.com/media.gold-msi.org/misc/audio/terminator.mp3",
    btn_play_prompt = "Abspielen",
    button_text = "Weiter"
  )
}

questionnaire_landing_page <- function(home_url = NULL) {
  psychTestR::one_button_page(
    body = shiny::div(
      shiny::h4("Super, die Aufgaben sind geschafft!"),
      shiny::p("Deine Ergebnisse sind gespeichert. Jetzt kommen noch ein paar Fragebögen ",
               "zu dir, deinem Musizieren und deiner Familie. Am Ende gibt es auch ",
               "ein paar Fragen für deine Eltern."),
      shiny::p(shiny::strong("Falls heute keine Zeit mehr ist,"),
               " kannst du die Fragebögen auch zu Hause ausfüllen. Schließe dann einfach ",
               "das Fenster. Zu Hause öffnest du ",
               if (is.null(home_url)) "dieselbe Internetseite"
               else shiny::tagList("die Seite ", shiny::tags$a(href = home_url, home_url)),
               " und gibst deinen Teilnahmecode noch einmal ein. Du machst dann genau hier weiter."),
      style = "max-width:600px;margin:auto;text-align:left"
    ),
    button_text = "Fragebögen starten"
  )
}

parents_page <- function() {
  psychTestR::one_button_page(
    body = shiny::div(
      shiny::p(shiny::strong("Bitte gib das Gerät jetzt an deine Eltern weiter.")),
      shiny::h4("Liebe Eltern,"),
      shiny::p("die folgenden Fragen richten sich an Sie. Sie betreffen den Bildungsabschluss ",
               "der Eltern und den Beruf der Hauptverdienerin oder des Hauptverdieners ",
               "im Haushalt. Ihre Angaben werden pseudonymisiert und nur für die Studie ",
               "ausgewertet."),
      style = "max-width:600px;margin:auto;text-align:left"
    ),
    button_text = "Weiter"
  )
}

final_page <- function() {
  psychTestR::final_page(
    shiny::div(
      shiny::h4("Vielen Dank für die Teilnahme!"),
      shiny::p("Alle Angaben wurden gespeichert. Das Fenster kann jetzt geschlossen werden.")
    )
  )
}
