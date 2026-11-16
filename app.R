# Entry point for shiny server / local start: shiny::runApp(".")
# The admin password is read from the environment variable JMS_ADMIN_PASSWORD
# (on the server: /home/shiny/.Renviron), so it never ends up in the repository.
# Optionally JMS_HOME_URL holds the address shown on the page before the
# questionnaires, so that participants know where to continue at home.
library(jmsbattery)

admin_password <- Sys.getenv("JMS_ADMIN_PASSWORD")
if (!nzchar(admin_password)) {
  stop("Environment variable JMS_ADMIN_PASSWORD is not set.")
}
home_url <- Sys.getenv("JMS_HOME_URL")

jms_battery(admin_password = admin_password,
            home_url = if (nzchar(home_url)) home_url else NULL)
