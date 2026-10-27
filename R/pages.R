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
               "Im Folgenden beantwortest du einige Fragen zu dir und deinem ",
               "Musizieren und bearbeitest ein paar kurze Hör- und Gedächtnisaufgaben."),
      shiny::p("Bitte nutze Kopfhörer und sorge für eine ruhige Umgebung.")
    ),
    button_text = "Weiter"
  )
}

id_page <- function() {
  psychTestR::get_p_id(
    prompt = shiny::p("Bitte gib hier deinen persönlichen Teilnahmecode ein."),
    placeholder = "Teilnahmecode",
    button_text = "Weiter",
    validate = function(answer, ...) {
      if (nchar(trimws(answer)) > 0) TRUE else "Bitte gib einen Teilnahmecode ein."
    }
  )
}

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

# Asks whether the participant has time left for the optional block.
extras_choice_page <- function() {
  psychTestR::NAFC_page(
    label = "extras_choice",
    prompt = shiny::div(
      shiny::h4("Geschafft!"),
      shiny::p("Du hast den Hauptteil abgeschlossen, deine Angaben sind gespeichert."),
      shiny::p("Hast du noch etwa 10 bis 15 Minuten Zeit für ein paar weitere Fragen und Aufgaben?")
    ),
    choices = c("yes", "no"),
    labels = c("Ja, weiter", "Nein, beenden"),
    save_answer = TRUE
  )
}

final_page <- function() {
  psychTestR::final_page(
    shiny::div(
      shiny::h4("Danke für deine Teilnahme!"),
      shiny::p("Deine Angaben wurden gespeichert. Du kannst das Fenster jetzt schließen.")
    )
  )
}
