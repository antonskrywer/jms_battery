#' Item numbers of the tests
#'
#' For DMT this is the number of main trials.
#' @export
jms_num_items <- c(RAT = 14L, BAT = 20L, JAJ = 8L, DMT = 5L, MPT = 20L)

#' JMS test battery
#'
#' Core part: DEG (age, gender, nationality, languages), RAT, BAT (CA-BAT),
#' JAJ, DMT (Drum Machine Test), GMS (Gold-MSI short version) and TOM.
#' Afterwards participants are asked
#' whether they have time left for the optional block (GRT, CCM, MPT).
#' Results are saved after every module, so stopping during the optional block
#' loses nothing; the session is marked complete once the core part is done.
#'
#' @param title Title shown in the browser tab.
#' @param admin_password Password for the psychTestR admin panel.
#' @param researcher_email Contact address shown on problem pages.
#' @param extras Character vector of optional modules to offer, any of
#'   `"GRT"`, `"CCM"`, `"MPT"`. Use `character()` to drop the optional block.
#' @param num_items Named integer vector with item numbers for RAT, BAT, JAJ,
#'   DMT, MPT.
#' @param take_training Whether the tests show their practice items.
#' @param dmt_feedback Whether DMT trials allow up to four attempts with
#'   feedback (`TRUE`) or a single attempt (`FALSE`).
#' @param debug If `TRUE`, every adaptive test runs with a single item and
#'   without training, for quickly clicking through the battery.
#' @param language Test language; all modules support `"de"` (informal du).
#' @param ... Further arguments passed to [psychTestR::test_options()].
#' @export
jms_battery <- function(title = "JMS Testbatterie",
                        admin_password = "jms_admin",
                        researcher_email = "anton.schreiber@uni-hamburg.de",
                        extras = c("GRT", "CCM", "MPT"),
                        num_items = jms_num_items,
                        take_training = TRUE,
                        dmt_feedback = TRUE,
                        debug = FALSE,
                        language = "de",
                        ...) {
  stopifnot(all(extras %in% c("GRT", "CCM", "MPT")),
            all(c("RAT", "BAT", "JAJ", "DMT", "MPT") %in% names(num_items)))
  if (debug) {
    num_items[] <- 1L
    take_training <- FALSE
  }

  save_partial <- de_timeline(psychTestR::elt_save_results_to_disk(complete = FALSE))
  save_complete <- de_timeline(psychTestR::elt_save_results_to_disk(complete = TRUE))

  core <- psychTestR::join(
    de_timeline(welcome_page(), id_page()),
    psyquest::DEG(subscales = c("Age", "Gender", "Nationality",
                                "First Language", "Second Language"),
                  language = language,
                  year_range = c(1940, 2020)),
    save_partial,
    de_timeline(volume_page()),
    RAT::RAT(num_items = num_items[["RAT"]],
             take_training = take_training,
             feedback = NULL),
    save_partial,
    cabat::cabat(num_items = num_items[["BAT"]],
                 take_training = take_training,
                 feedback = NULL),
    save_partial,
    JAJ::JAJ(num_items = num_items[["JAJ"]],
             take_training = take_training,
             feedback = NULL),
    save_partial,
    dmt_module(num_trials = num_items[["DMT"]],
               num_examples = if (take_training) 2 else 0,
               with_feedback = dmt_feedback,
               language = language),
    save_partial,
    psyquest::GMS(short_version = TRUE),
    save_partial,
    psyquest::TOM(),
    save_complete
  )

  extra_modules <- list(
    GRT = function() psyquest::GRT(),
    CCM = function() psyquest::CCM(),
    MPT = function() mpt::mpt(num_items = num_items[["MPT"]],
                              take_training = take_training,
                              feedback = NULL)
  )

  optional <- if (length(extras) > 0) {
    block <- do.call(psychTestR::join, lapply(extras, function(id) {
      psychTestR::join(extra_modules[[id]](), save_complete)
    }))
    psychTestR::join(
      de_timeline(extras_choice_page()),
      save_complete,
      psychTestR::conditional(
        test = function(state, ...) identical(psychTestR::answer(state), "yes"),
        logic = block
      )
    )
  }

  psychTestR::make_test(
    psychTestR::join(core, optional, de_timeline(final_page())),
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
# answers would be filed under the preceding test (JAJ).
dmt_module <- function(language, ...) {
  psychTestR::join(
    de_timeline(psychTestR::begin_module("DMT")),
    DMT::DMT(language = language, with_id = FALSE, with_final_page = FALSE, ...),
    de_timeline(psychTestR::end_module())
  )
}
