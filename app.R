# Entry point for shiny server / local start: shiny::runApp(".")
# The admin password is read from the environment variable JMS_ADMIN_PASSWORD
# (on the server: /home/shiny/.Renviron), so it never ends up in the repository.
library(jmsbattery)

admin_password <- Sys.getenv("JMS_ADMIN_PASSWORD")
if (!nzchar(admin_password)) {
  stop("Environment variable JMS_ADMIN_PASSWORD is not set.")
}

jms_battery(admin_password = admin_password)
