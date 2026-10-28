#' Read JMS battery results into a tibble
#'
#' Reads every psychTestR results file (`.rds`) in `results_dir` and returns
#' one row per file (= per session) with
#' * session info (`p_id`, `complete`, start and end time),
#' * all DEG variables,
#' * the ability score of each adaptive test (`RAT`, `BAT`, `JAJ`, `MPT`),
#' * all subscales of the questionnaires in `scales` (default: GMS),
#' * whether the participant chose the optional block (`extras_choice`).
#'
#' Modules a participant did not reach are `NA`.
#'
#' @param results_dir Folder with the results files, usually
#'   `"output/results"` of the running battery.
#' @param scales Questionnaires whose subscale scores are added; any of
#'   `"GMS"`, `"TOM"`, `"GRT"`, `"CCM"`.
#' @param complete_only If `TRUE`, sessions that did not finish the core
#'   part are dropped.
#' @return A tibble.
#' @export
read_jms_results <- function(results_dir = "output/results",
                             scales = "GMS",
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
    complete = isTRUE(s$complete),
    time_started = s$time_started,
    time_last_saved = s$current_time,
    file = basename(file)
  )
  c(row,
    deg_vars(r$DEG),
    ability_vars(r),
    unlist(lapply(scales, function(id) subscale_vars(r[[id]], id)), recursive = FALSE),
    extras_choice = na_if_null(r$results$extras_choice)) |>
    tibble::as_tibble()
}

gender_labels <- c("weiblich", "männlich", "divers", "keine Angabe")

# psyquest stores Nationality only as raw item q5 and the birth date as q9
# (month, year), so these are read from the raw items.
deg_vars <- function(deg) {
  birth <- if (is.null(deg$q9)) c(NA, NA) else as.integer(deg$q9)
  gender <- na_if_null(deg$Gender)
  list(
    DEG.gender = gender,
    DEG.gender_label = gender_labels[gender],
    DEG.birth_month = birth[1],
    DEG.birth_year = birth[2],
    DEG.age_months = na_if_null(deg$Age),
    DEG.age_years = na_if_null(deg$Age) / 12,
    DEG.nationality = na_if_null(deg$q5),
    DEG.first_language = na_if_null(deg$`First Language`),
    DEG.second_language = na_if_null(deg$`Second Language`)
  )
}

ability_vars <- function(r) {
  tests <- c("RAT", "BAT", "JAJ", "MPT")
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
  sub <- lapply(sub, function(x) as.numeric(x))
  stats::setNames(sub, paste0(id, ".", gsub(" ", "_", names(sub))))
}

na_if_null <- function(x) if (is.null(x)) NA else x
