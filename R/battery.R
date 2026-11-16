#' Item numbers of the tests
#'
#' For DMT the number of main trials comes from [jms_dmt_allocation], so it
#' is not listed here.
#' @export
jms_num_items <- c(JAJ = 8L, MIQ = 8L, BAT = 20L, MDT = 18L)

#' DMT trials per difficulty stratum
#'
#' Number of DMT main trials drawn from each of the four strata of the DMT
#' item bank (easy item bank: easier and harder half; normal item bank:
#' easier and harder half). Because the battery tests children, the default
#' draws mostly from the easy item bank and leaves out the hardest stratum.
#' The sum is the number of main trials.
#' @export
jms_dmt_allocation <- c(easy_easy = 3L, easy_hard = 1L,
                        normal_easy = 1L, normal_hard = 0L)

#' JMS test battery
#'
#' Order (Stand 2026-11-12):
#' 1. Welcome, participation code (8 digits with check digits)
#' 2. DEG (age, gender, country of formative years, first and second
#'    language) and INS (instrument, start of lessons)
#' 3. Tests: DMT, JAJ, MIQ, CA-BAT, MDT
#' 4. Landing page announcing the questionnaires
#' 5. Questionnaires: UEB (lesson minutes per week, individual and ensemble)
#'    and CCM, GMS (short version), TOM, TPI, MHE, SES (filled in by the
#'    parents, formal "Sie")
#'
#' CSA and BOT-2 are run on site without the computer and are not part of
#' the app.
#'
#' Results are saved after every module. The questionnaires can be filled in
#' later at home: entering the same participation code again resumes the
#' session where it was left, and everything ends up in the same results
#' file. A session is not resumed if it was finished or if it was last used
#' more than `resume_days` days ago; then the code starts a new session (for
#' example in the next wave).
#'
#' @param title Title shown in the browser tab.
#' @param admin_password Password for the psychTestR admin panel.
#' @param researcher_email Contact address shown on problem pages.
#' @param num_items Named integer vector with item numbers for JAJ, MIQ,
#'   BAT, MDT.
#' @param dmt_allocation Named integer vector with the number of DMT main
#'   trials per stratum, see [jms_dmt_allocation].
#' @param take_training Whether the tests show their practice items.
#' @param dmt_feedback Whether DMT trials allow up to four attempts with
#'   feedback (`TRUE`) or a single attempt (`FALSE`).
#' @param resume_days A session last used more than this many days ago is
#'   not resumed.
#' @param home_url Optional address of the battery, shown on the landing
#'   page before the questionnaires so that participants know where to
#'   continue at home.
#' @param debug If `TRUE`, every adaptive test runs with a single item, DMT
#'   with a single trial, all without training, for quickly clicking through
#'   the battery. Without the MIQ package installed, MIQ is then left out
#'   with a warning instead of an error.
#' @param ... Further arguments passed to [psychTestR::test_options()].
#' @export
jms_battery <- function(title = "JMS Testbatterie",
                        admin_password = "jms_admin",
                        researcher_email = "anton.schreiber@uni-hamburg.de",
                        num_items = jms_num_items,
                        dmt_allocation = jms_dmt_allocation,
                        take_training = TRUE,
                        dmt_feedback = TRUE,
                        resume_days = 14,
                        home_url = NULL,
                        debug = FALSE,
                        ...) {
  stopifnot(all(c("JAJ", "MIQ", "BAT", "MDT") %in% names(num_items)),
            setequal(names(dmt_allocation), names(jms_dmt_allocation)),
            sum(dmt_allocation) > 0)
  language <- "de"
  if (debug) {
    num_items[] <- 1L
    dmt_allocation[] <- 0L
    dmt_allocation[["easy_easy"]] <- 1L
    take_training <- FALSE
  }

  has_miq <- requireNamespace("MIQ", quietly = TRUE)
  if (!has_miq) {
    msg <- "Package 'MIQ' is not installed."
    if (debug) warning(msg, " MIQ is left out (debug mode).", call. = FALSE)
    else stop(msg, " It is needed for the battery (use debug = TRUE to leave it out).",
              call. = FALSE)
  }

  save_partial <- de_timeline(psychTestR::elt_save_results_to_disk(complete = FALSE))
  save_complete <- de_timeline(psychTestR::elt_save_results_to_disk(complete = TRUE))
  with_save <- function(...) psychTestR::join(..., save_partial)

  start <- psychTestR::join(
    de_timeline(welcome_page(), id_page(resume_days)),
    with_save(psyquest::DEG(subscales = c("Age", "Gender", "Country Formative Years",
                                          "First Language", "Second Language"),
                            language = language,
                            year_range = c(2005, as.integer(format(Sys.Date(), "%Y")) - 4L))),
    with_save(de_timeline(instrument_module()))
  )

  tests <- psychTestR::join(
    de_timeline(volume_page()),
    with_save(dmt_module(dmt_allocation = dmt_allocation,
                         num_examples = if (take_training) 2 else 0,
                         with_feedback = dmt_feedback,
                         language = language)),
    with_save(JAJ::JAJ(num_items = num_items[["JAJ"]],
                       take_training = take_training,
                       feedback = NULL)),
    if (has_miq) with_save(miq_module(num_items = num_items[["MIQ"]],
                                      take_training = take_training)),
    with_save(cabat::cabat(num_items = num_items[["BAT"]],
                           take_training = take_training,
                           feedback = NULL)),
    with_save(mdt::mdt(num_items = num_items[["MDT"]],
                       take_training = take_training,
                       feedback = NULL)),
    de_timeline(mark_tests_complete()),
    save_partial
  )

  questionnaires <- psychTestR::join(
    de_timeline(questionnaire_landing_page(home_url)),
    with_save(de_timeline(lesson_time_module())),
    with_save(psyquest::CCM()),
    with_save(psyquest::GMS(short_version = TRUE)),
    with_save(psyquest::TOM()),
    with_save(psyquest::TPI()),
    with_save(psyquest::MHE()),
    de_timeline(parents_page()),
    psyquest::SES(dict = ses_parent_dict()),
    de_timeline(mark_finished()),
    save_complete
  )

  psychTestR::make_test(
    psychTestR::join(start, tests, questionnaires, de_timeline(final_page())),
    opt = psychTestR::test_options(
      title = title,
      admin_password = admin_password,
      researcher_email = researcher_email,
      demo = FALSE,
      languages = language,
      theme = shinythemes::shinytheme("yeti"),
      ...
    )
  )
}

# DMT() opens no results section of its own, so without the module its
# answers would be filed under the preceding test.
dmt_module <- function(dmt_allocation, language, ...) {
  psychTestR::join(
    de_timeline(psychTestR::begin_module("DMT")),
    DMT::DMT(num_trials = sum(dmt_allocation),
             stratified_sampling = TRUE,
             custom_stratified_sampling_allocation = as.list(dmt_allocation),
             language = language, with_id = FALSE, with_final_page = FALSE, ...),
    de_timeline(psychTestR::end_module())
  )
}

# MIQ is installed on the server but not available from a public repository,
# so it is only a suggested package and called without a hard dependency.
miq_module <- function(num_items, take_training) {
  miq <- getExportedValue("MIQ", "MIQ")
  miq(num_items = num_items, take_training = take_training, feedback = NULL)
}

# Marks that all tests are done, before the (possibly later) questionnaires.
# In its own results section, otherwise it would be filed under MDT.
mark_tests_complete <- function() {
  psychTestR::join(
    psychTestR::begin_module("JMS"),
    psychTestR::code_block(function(state, ...) {
      psychTestR::save_result(place = state, label = "tests_complete", value = TRUE)
    }),
    psychTestR::end_module()
  )
}

# A finished session is not resumed when the code is entered again.
mark_finished <- function() {
  psychTestR::code_block(function(state, ...) {
    psychTestR::set_global("jms_finished", TRUE, state)
  })
}

# psyquest's formal German ("de_f") texts of the SES, put into the "de"
# column, so that the parents are addressed with "Sie" although the battery
# runs in informal German. The two education items refer to the child's
# parents, not to the parents of the person answering.
ses_parent_dict <- function() {
  d <- psyquest::psyquest_dict$as.data.frame()
  ses <- grepl("^TSES_", d$key)
  d$de[ses] <- d$de_f[ses]
  d$de[d$key == "TSES_0001_PROMPT"] <- "Welchen höchsten Bildungsabschluss hat die Mutter Ihres Kindes?"
  d$de[d$key == "TSES_0002_PROMPT"] <- "Welchen höchsten Bildungsabschluss hat der Vater Ihres Kindes?"
  d$de[ses] <- gsub("  +", " ", d$de[ses])
  psychTestR::i18n_dict$new(d)
}
