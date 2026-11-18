#' Read JMS battery results into a tibble
#'
#' Reads every psychTestR results file (`.rds`) in `results_dir` and returns
#' one row per file (= per session; a session resumed at home with the same
#' participation code stays in the same file) with
#' * session info (`p_id`, `valid_id`, `complete`, `tests_complete`, start
#'   and end time, number of resumptions),
#' * DEG variables, main instrument, up to three further instruments and
#'   start of lessons on the main instrument (INS),
#' * lesson minutes per week, individual and ensemble (UEB),
#' * the ability score of each adaptive test (`JAJ`, `MIQ`, `BAT`, `RAT`,
#'   `MPT`),
#' * all subscales of the questionnaires in `scales`.
#'
#' Modules a participant did not reach are `NA`. DMT trials are best read
#' with `DMT::DMT_results_to_long()`.
#'
#' @param results_dir Folder with the results files, usually
#'   `"output/results"` of the running battery.
#' @param scales Questionnaires whose subscale scores are added; any of
#'   `"CCM"`, `"GMS"`, `"TOM"`, `"GRT"`, `"MHE"`, `"SES"`.
#' @param complete_only If `TRUE`, only sessions that reached the end
#'   (including the questionnaires) are kept.
#' @return A tibble.
#' @export
read_jms_results <- function(results_dir = "output/results",
                             scales = c("CCM", "GMS", "TOM", "GRT", "MHE", "SES"),
                             complete_only = FALSE) {
  files <- list.files(results_dir, pattern = "\\.rds$", full.names = TRUE)
  if (length(files) == 0) stop("No results files found in ", results_dir)
  res <- purrr::map_dfr(files, read_jms_file, scales = scales)
  if (complete_only) res <- res[res$complete, ]
  res[order(res$time_started), ]
}

read_jms_file <- function(file, scales) {
  r <- readRDS(file)
  s <- r$session
  row <- list(
    p_id = s$p_id,
    valid_id = is_valid_jms_id(s$p_id),
    complete = isTRUE(s$complete),
    tests_complete = isTRUE(r$JMS$tests_complete),
    time_started = s$time_started,
    time_last_saved = s$current_time,
    num_restarts = na_if_null(s$num_restarts),
    file = basename(file)
  )
  c(row,
    deg_vars(r$DEG),
    ins_vars(r$INS),
    ueb_vars(r$UEB),
    ability_vars(r),
    unlist(lapply(scales, function(id) subscale_vars(r[[id]], id)), recursive = FALSE)) |>
    tibble::as_tibble()
}

gender_labels <- c("weiblich", "männlich", "divers", "keine Angabe")

# psyquest stores the birth date only as raw item q9 (month, year).
deg_vars <- function(deg) {
  birth <- if (is.null(deg$q9)) c(NA, NA) else as.integer(deg$q9)
  gender <- na_if_null(deg$Gender)
  list(
    DEG.gender = gender,
    # as.integer(): indexing with a logical NA would return four NAs
    # (one row per label) for sessions without DEG.
    DEG.gender_label = gender_labels[as.integer(gender)],
    DEG.birth_month = birth[1],
    DEG.birth_year = birth[2],
    DEG.age_months = na_if_null(deg$Age),
    DEG.age_years = na_if_null(deg$Age) / 12,
    DEG.country_formative_years = na_if_null(deg$`Country Formative Years`),
    DEG.first_language = na_if_null(deg$`First Language`),
    DEG.second_language = na_if_null(deg$`Second Language`)
  )
}

ins_vars <- function(ins) {
  month <- na_if_null(ins$lesson_start_month)
  year <- na_if_null(ins$lesson_start_year)
  start <- if (is.na(month) || is.na(year)) as.Date(NA)
           else as.Date(sprintf("%d-%02d-01", year, month))
  further <- unlist(ins[c("instrument_2", "instrument_3", "instrument_4")])
  list(
    INS.instrument = na_if_null(ins$instrument),
    INS.has_further_instruments = if (is.null(ins$has_further_instruments)) NA
                                  else ins$has_further_instruments == "yes",
    INS.instrument_2 = na_if_null(ins$instrument_2),
    INS.instrument_3 = na_if_null(ins$instrument_3),
    INS.instrument_4 = na_if_null(ins$instrument_4),
    INS.num_instruments = if (is.null(ins$instrument)) NA_integer_ else 1L + length(further),
    INS.lesson_start_month = month,
    INS.lesson_start_year = year,
    INS.lesson_start = start
  )
}

ueb_vars <- function(ueb) {
  list(
    UEB.individual_min_week = na_if_null(ueb$individual_min_week),
    UEB.ensemble_min_week = na_if_null(ueb$ensemble_min_week)
  )
}

ability_vars <- function(r) {
  tests <- c("JAJ", "MIQ", "BAT", "RAT", "MPT")
  vals <- lapply(tests, function(t) {
    a <- r[[t]]$ability
    if (is.null(a)) NA_real_ else as.numeric(a)
  })
  stats::setNames(vals, paste0(tests, ".ability"))
}

# Subscale scores are the non-item entries of a psyquest module (items are q1, q2, ...).
subscale_vars <- function(module, id) {
  if (is.null(module)) return(list())
  module <- unclass(module)
  sub <- module[!grepl("^q[0-9]+$", names(module))]
  sub <- lapply(sub, function(x) if (length(x) == 1) as.numeric(x) else NA_real_)
  stats::setNames(sub, paste0(id, ".", gsub(" ", "_", names(sub))))
}

na_if_null <- function(x) if (is.null(x) || length(x) == 0) NA else x[[1]]
